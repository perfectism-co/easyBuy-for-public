//
//  PdViewModel.swift
//  easyBuy
//
//  
//

import Foundation


@MainActor
class ProductViewModel: ObservableObject {
    @Published var products: [OpenProduct] = []
    @Published var isLoading: Bool = false
    
    // Sort alphabetically
    var categorizedProducts: [String: [OpenProduct]] {
        Dictionary(grouping: products, by: { $0.category })
    }
    
    
    func fetchProducts() async {
        isLoading = true; defer { isLoading = false }
        guard let url = URL(string: "https://raw.githubusercontent.com/perfectism-co/easyBuy/main/fakeProductDatabase.json") else {
            print("❌ URL 無效")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let decoded = try? JSONDecoder().decode(ProductResponse.self, from: data) else {
                print("❌ 解碼失敗")
                return
            }
            self.products = decoded.products
            
        } catch {
            print("❌ 下載或解析失敗: \(error)")
        }
    }
    
}
    
    
    

struct ProductResponse: Codable {
    let products: [OpenProduct]
}
// MARK: - OpenProduct
struct OpenProduct: Identifiable, Codable, Equatable {
    var id: String
    let name: String
    let category: String
    let imageUrl: [String]
    let price: Int
    let rating: Double
    
    private enum CodingKeys: String, CodingKey {
        case id, name, category, imageUrl, price
    }
    
    // Custom init(from:) because JSON has no rating
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.category = try container.decode(String.self, forKey: .category)
        self.imageUrl = try container.decode([String].self, forKey: .imageUrl)
        self.price = try container.decode(Int.self, forKey: .price)
        self.rating = Double.random(in: 3.0...5.0) // 模擬評分
    }
    
    // For preview
    init(id: String, name: String, category: String, imageUrl: [String], price: Int, rating: Double) {
        self.id = id
        self.name = name
        self.category = category
        self.imageUrl = imageUrl
        self.price = price
        self.rating = rating
    }
}




// Add an initializer in Product for a cleaner conversion
extension Product {
    init(from open: OpenProduct, quantity: Int) {
        self.id = UUID().uuidString
        self.productId = open.id
        self.name = open.name
        self.imageUrl = open.imageUrl
        self.price = open.price
        self.quantity = quantity
    }
}
