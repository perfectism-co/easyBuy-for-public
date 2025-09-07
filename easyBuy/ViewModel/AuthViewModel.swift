
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var newOrderRequest: OrderRequest = .empty
    @Published var isAutoLoading: Bool = false
    @Published var isLoading: Bool = false
    @Published var message: String?
    
    @Published var comment = ""
    @Published var rating = 0
    @Published var selectedImages: [UIImage] = []
  
    @Published var selectedTab: Int = 0

    
    private var hasSavedToken: Bool {
       KeychainHelper.shared.read(service: "easyBuy", account: "accessToken") != nil
    }

 
    var isLoggedIn: Bool { user != nil }

    init() {
       autoLoginIfNeeded()
    }

    private func autoLoginIfNeeded() {
        print("💻▶️ autoLoginIfNeeded called")
        guard hasSavedToken else {
            print("💻❌ hasSavedToken = false")
            return
        }
       Task {
           isAutoLoading = true
           defer { isAutoLoading = false }
           do {
               let fetched = try await APIService.shared.fetchUser()
               self.user = fetched
           } catch {
               print("💻❗️Auto-login failed:", error)
           }
       }
   }

    func register() async {
        guard !email.isEmpty, !password.isEmpty else {
            message = "Please enter your email and password."
            return
        }
        isLoading = true; defer { isLoading = false }
        do {
            try await APIService.shared.register(email: email, password: password)
            message = "Registration successful, please log in."
        } catch {
            message = error.localizedDescription
        }
    }

    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            message = "Please enter your email and password."
            return
        }
        isLoading = true; defer { isLoading = false }
        do {
            try await APIService.shared.login(email: email, password: password)
            user = try await APIService.shared.fetchUser()
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }

    func logout() async {
        isLoading = true; defer { isLoading = false }
        do {
            try await APIService.shared.logout()
            user = nil
            email = ""; password = ""; newOrderRequest = .empty
            selectedTab = 0
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }
    
    
    func fetchUser() async {
        do {
            let fetchedUser = try await APIService.shared.fetchUser()
            self.user = fetchedUser
        } catch {
            print("💻❌ 無法取得使用者資料：\(error)")
        }
    }


    
    func addCart(products: CartRequest) async {
        print("💻🛎️addCart called")
        do {
            _ = try await APIService.shared.submitCart(add: products)
            message = nil
        } catch {
            message = error.localizedDescription
            print("💻❌errorMessage:\(message ?? "")")
        }
    }

    func addOrder() async {
        print("💻🛎️addOrder called")
        guard !newOrderRequest.isEmpty else {
            message = "Please check the required fields."
            return
        }
        do {
            try await APIService.shared.submitOrder(order: newOrderRequest)
            newOrderRequest = .empty
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }

    
    func updateCartItem(productId: String, quantity: Int) async {
        print("💻🛎️updateCartItem called")

        do {
            // 呼叫後端更新商品數量
            try await APIService.shared.updateCart(productId: productId, quantity: quantity)

            // 本地更新
            if let index = user?.cart.firstIndex(where: { $0.productId == productId }) {
                user?.cart[index].quantity = quantity
            }

            message = nil
        } catch {
            message = error.localizedDescription
            print("💻❌updateCartItem failed, errorMessage:\(message ?? "")")
        }
    }
    
    func updateOrder(order: Order) async {
        do {
            try await APIService.shared.updateOrder(orderId: order.id, order: newOrderRequest)
            newOrderRequest = .empty
            message = nil
        } catch {
            message = error.localizedDescription
            print("💻❌updateOrder failed, errorMessage:\(message ?? "")")
        }
    }

    func deleteCartItems(productIds: [String]) async {
        do {
            let request = DeleteCartRequest(productIds: productIds)
            try await APIService.shared.deleteCart(productIds: request)

            // Update the local cart (remove successfully deleted items).
            user?.cart.removeAll(where: { productIds.contains($0.id) })

            message = nil
        } catch {
            message = error.localizedDescription
        }
    }
    
    
    func deleteOrder(order: Order) async {
        do {
            try await APIService.shared.deleteOrder(orderId: order.id)
            user?.orders.removeAll(where: { $0.id == order.id })
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }
    
    
    func addReview(orderId: String) async {
        let request = AddReviewRequest(
            orderId: orderId,
            comment: comment, //vm.commet
            rating: rating, //vm.rating
            images: selectedImages //vm.selectedImages
        )

        do {
            try await APIService.shared.submitReview(add: request)
            message = nil
            
            comment = ""
            rating = 0
            selectedImages = []
            
        } catch {
            message = error.localizedDescription
        }
    }

    
    func deleteReview(order: Order) async {
        do {
            try await APIService.shared.deleteReview(orderId: order.id)
            user?.orders.removeAll(where: { $0.id == order.id })
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }
    
}




