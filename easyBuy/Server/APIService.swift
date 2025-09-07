import Foundation
import UIKit


// MARK: - APIError

enum APIError: Error, LocalizedError {
    case invalidURL, invalidResponse, unauthorized, other(String)
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無效的網址"
        case .invalidResponse: return "伺服器回應錯誤"
        case .unauthorized: return "未授權，請重新登入"
        case .other(let msg): return msg
        }
    }
}

// MARK: - APIService class

@MainActor
final class APIService {
    static let shared = APIService()
    private init() {}

    private let baseURL = "https://easybuy-881j.onrender.com"
    private let service = "easyBuy"
    private let keyAccess = "accessToken"
    private let keyRefresh = "refreshToken"

    private var accessToken: String? {
        KeychainHelper.shared.read(service: service, account: keyAccess)
    }
    private var refreshToken: String? {
        KeychainHelper.shared.read(service: service, account: keyRefresh)
    }

    func clearTokens() {
        KeychainHelper.shared.delete(service: service, account: keyAccess)
        KeychainHelper.shared.delete(service: service, account: keyRefresh)
    }

    // MARK: - makeRequest    
    private func makeRequest(path: String,
                             method: String = "GET",
                             body: Data? = nil,
                             auth: Bool = false) -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            fatalError("Invalid URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = body { req.httpBody = body }
        if auth, let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    // MARK: - JSONDecoder with Fractional-Seconds ISO8601
    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fmt.date(from: str) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "無法解析日期字串：\(str)")
        }
        return decoder
    }

    // MARK: - Register
    func register(email: String, password: String) async throws {
        let body = try JSONEncoder().encode(["email": email, "password": password])
        let req = makeRequest(path: "/register", method: "POST", body: body)
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.other("Registration Failed")
        }
    }

    // MARK: - Login
    func login(email: String, password: String) async throws {
        let body = try JSONEncoder().encode(["email": email, "password": password])
        let req = makeRequest(path: "/login", method: "POST", body: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.other("Login Failed")
        }
        struct LR: Codable { let accessToken: String; let refreshToken: String }
        let lr = try makeDecoder().decode(LR.self, from: data)
        KeychainHelper.shared.save(lr.accessToken, service: service, account: keyAccess)
        KeychainHelper.shared.save(lr.refreshToken, service: service, account: keyRefresh)
    }

    // MARK: - Logout
    func logout() async throws {
        guard let token = refreshToken else { return }
        let body = try JSONEncoder().encode(["token": token])
        let req = makeRequest(path: "/logout", method: "POST", body: body)
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        clearTokens()
    }

    // MARK: - Refresh Token
    private func refresh() async throws {
        print("🔃 refresh call")
        guard let token = refreshToken else { throw APIError.unauthorized }

        var req = makeRequest(path: "/refresh", method: "POST")
        req.setValue(token, forHTTPHeaderField: "x-refresh-token") // 改用 header 傳送 refresh token
        // body 不用送 token 了，可以不設或設空

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            print("🔴 refresh fail")
            throw APIError.unauthorized
        }

        let dict = try makeDecoder().decode([String:String].self, from: data)
        if let newAccess = dict["accessToken"], let newRefresh = dict["refreshToken"] {
            KeychainHelper.shared.save(newAccess, service: service, account: keyAccess)
            KeychainHelper.shared.save(newRefresh, service: service, account: keyRefresh)
        } else {
            print("🔴 refresh fail")
            throw APIError.invalidResponse
        }
    }


    // MARK: - Fetch User
    func fetchUser() async throws -> User {
        print("👤fetchUser call, accessToken: \(accessToken ?? "nil"), refreshToken: \(refreshToken ?? "nil")")
        var req = makeRequest(path: "/me", auth: true)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0

        if let s = String(data: data, encoding: .utf8) {
            print("[DEBUG] /me JSON:\n\(s)")
        }

        guard status == 200 else {
            print("⛔️ fetchUser fail, status:\(status),maybe astooken expired.")
            try await refresh()
            req = makeRequest(path: "/me", auth: true)
            let (d2, r2) = try await URLSession.shared.data(for: req)
            guard (r2 as? HTTPURLResponse)?.statusCode == 200 else {
                print("⛔️ fetchUser fail, status:\(status)")
                throw APIError.unauthorized
            }
            return try makeDecoder().decode(User.self, from: d2)
        }
        return try makeDecoder().decode(User.self, from: data)
    }

    // MARK: - Add / Update / Delete Order
    func submitOrder(order: OrderRequest) async throws  {
        let body = try JSONEncoder().encode(order)
        var req = makeRequest(path: "/order", method: "POST", body: body, auth: true)
        
        let (_, resp) = try await URLSession.shared.data(for: req)
        
        if let status = (resp as? HTTPURLResponse)?.statusCode,
           [401, 403, 503].contains(status) {
            try await refresh()
            req = makeRequest(path: "/order", method: "POST", body: body, auth: true)
            let (_, r2) = try await URLSession.shared.data(for: req)
            guard (r2 as? HTTPURLResponse)?.statusCode == 200 else {
                throw APIError.unauthorized
            }
        }
    }

    func updateOrder(orderId: String, order: OrderRequest) async throws  {
        let body = try JSONEncoder().encode(order)
        var req = makeRequest(path: "/order/\(orderId)", method: "PUT", body: body, auth: true)
        let (_, resp) = try await URLSession.shared.data(for: req)
        if let status = (resp as? HTTPURLResponse)?.statusCode,
           [401, 403, 503].contains(status) {
            print("❌updateOrder failed")
            try await refresh()
            req = makeRequest(path: "/order/\(orderId)", method: "PUT", body: body, auth: true)
            let (_, r2) = try await URLSession.shared.data(for: req)
            guard (r2 as? HTTPURLResponse)?.statusCode == 200 else {
                print("❌updateOrder failed")
                throw APIError.unauthorized
            }
        }
    }

    func deleteOrder(orderId: String) async throws {
        print("✋deleteOrder called:\(orderId)")
        var req = makeRequest(path: "/order/\(orderId)", method: "DELETE", auth: true)
        let (_, resp) = try await URLSession.shared.data(for: req)
        if let status = (resp as? HTTPURLResponse)?.statusCode,
           [401, 403, 503].contains(status) {
            try await refresh()
            req = makeRequest(path: "/order/\(orderId)", method: "DELETE", auth: true)
            _ = try await URLSession.shared.data(for: req)
            return
        }
    }
    
    
    // MARK: - Add / Update / Delete Cart
    func submitCart(add: CartRequest) async throws -> [Product] {
        let body = try JSONEncoder().encode(add)
        var req = makeRequest(path: "/cart", method: "POST", body: body, auth: true)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        print("🪵 Response JSON:")
        print(String(data: data, encoding: .utf8) ?? "⚠️ 無法轉為字串")

        if let status = (resp as? HTTPURLResponse)?.statusCode,
           [401, 403, 503].contains(status) {
            print("submitCart fail: statusCode:\(status)")
            try await refresh()
            req = makeRequest(path: "/cart", method: "POST", body: body, auth: true)
            let (d2, r2) = try await URLSession.shared.data(for: req)
            guard (r2 as? HTTPURLResponse)?.statusCode == 200 else {
                print("❌submitCart fail")
                throw APIError.unauthorized
            }
            let response = try makeDecoder().decode(CartResponse.self, from: d2)
            return response.cart.products
        }
        
        let response = try makeDecoder().decode(CartResponse.self, from: data)
        return response.cart.products
    }

    func updateCart(productId: String, quantity: Int) async throws  {
        print("🛒 💘PUT /cart/\(productId)")
        let body = try JSONEncoder().encode(["quantity": quantity])
        var req = makeRequest(path: "/cart/\(productId)", method: "PUT", body: body, auth: true)
        let (_, resp) = try await URLSession.shared.data(for: req)
        if let status = (resp as? HTTPURLResponse)?.statusCode,
           [401, 403, 503].contains(status) {
            try await refresh()
            req = makeRequest(path: "/cart/\(productId)", method: "PUT", body: body, auth: true)
            let (_, r2) = try await URLSession.shared.data(for: req)
            guard (r2 as? HTTPURLResponse)?.statusCode == 200 else {
                throw APIError.unauthorized
            }
            print("🥳PUT /cart/\(productId) - refreshed")
        }
            print("🥳PUT /cart/\(productId) - refreshed")
    }

    func deleteCart(productIds: DeleteCartRequest) async throws {
        let body = try JSONEncoder().encode(productIds)
        var req = makeRequest(path: "/cart", method: "DELETE", body: body,auth: true)
        let (_, resp) = try await URLSession.shared.data(for: req)
        if let status = (resp as? HTTPURLResponse)?.statusCode,
           [401, 403, 503].contains(status) {
            try await refresh()
            req = makeRequest(path: "/cart", method: "DELETE", body: body,auth: true)
            _ = try await URLSession.shared.data(for: req)
            return
        }
    }
    
    // MARK: - Add / Delete Review
    func submitReview(add: AddReviewRequest) async throws {
        guard let url = URL(string: baseURL + "/order/\(add.orderId)/review") else {
            fatalError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body = createMultipartBody(comment: add.comment, rating: add.rating, images: add.images, boundary: boundary)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        print("🪵 Response JSON:")
        print(String(data: data, encoding: .utf8) ?? "⚠️ 無法轉為字串")

        if let status = (response as? HTTPURLResponse)?.statusCode,
           [401, 403, 503].contains(status) {
            try await refresh()

            var retryRequest = request
            if let newToken = accessToken {
                retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            }

            let (_, retryResponse) = try await URLSession.shared.data(for: retryRequest)
            guard (retryResponse as? HTTPURLResponse)?.statusCode == 200 else {
                throw APIError.unauthorized
            }
        }
    }

    private func createMultipartBody(comment: String, rating: Int, images: [UIImage], boundary: String) -> Data {
            var body = Data()
            let lineBreak = "\r\n"

            func appendFormField(name: String, value: String) {
                body.append("--\(boundary)\(lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak)\(lineBreak)")
                body.append("\(value)\(lineBreak)")
            }

            func appendImageField(name: String, image: UIImage, index: Int) {
                guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

                body.append("--\(boundary)\(lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"image\(index).jpg\"\(lineBreak)")
                body.append("Content-Type: image/jpeg\(lineBreak)\(lineBreak)")
                body.append(imageData)
                body.append(lineBreak)
            }

            appendFormField(name: "comment", value: comment)
            appendFormField(name: "rating", value: String(rating))

            for (i, image) in images.prefix(5).enumerated() {
                appendImageField(name: "images", image: image, index: i)
            }

            body.append("--\(boundary)--\(lineBreak)")
            return body
        }

    func deleteReview(orderId: String) async throws {
        print("✋deleteReview called:\(orderId)")
        var req = makeRequest(path: "/order/\(orderId)/review", method: "DELETE", auth: true)
        let (_, resp) = try await URLSession.shared.data(for: req)
        if let status = (resp as? HTTPURLResponse)?.statusCode,
           [401, 403, 503].contains(status) {
            try await refresh()
            req = makeRequest(path: "/order/\(orderId)/review", method: "DELETE", auth: true)
            _ = try await URLSession.shared.data(for: req)
            return
        }
    }
       
    func fetchImageWithAuth(from url: URL) async -> UIImage? {
        var request = URLRequest(url: url)
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                print("圖片下載失敗，狀態碼錯誤")
                return nil
            }

            return UIImage(data: data)
        } catch {
            print("圖片載入錯誤：\(error.localizedDescription)")
            return nil
        }
    }
    
    
}


// 🔧 Used to directly append a string.
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}



