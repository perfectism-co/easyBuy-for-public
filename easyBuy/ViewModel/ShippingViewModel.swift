//
//  ShippingViewModel.swift
//  easyBuy
//
// 
//

import Foundation


@MainActor
class ShippingViewModel: ObservableObject {
    @Published var shippings: [OpenShipping] = []
    
    func fetchShipping() async {
        guard let url = URL(string: "https://raw.githubusercontent.com/perfectism-co/easyBuy/main/fakeShippingFeeDatabase.json") else {
            print("❌ URL 無效")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
           
            let dict = try JSONDecoder().decode([String: ShippingInfo].self, from: data)            
          
            self.shippings = dict.map { key, value in
                OpenShipping(id: key, shippingMethod: value.shippingMethod, ShippingFee: value.ShippingFee)
            }
            .sorted { $0.id < $1.id }
        } catch {
            print("❌ 下載或解析失敗: \(error)")
        }
    }
}


struct OpenShipping: Identifiable, Codable {
    let id: String
    let shippingMethod: String
    let ShippingFee: Int
}


// Intermediate use: parse the value part of JSON first
struct ShippingInfo: Codable {
    let shippingMethod: String
    let ShippingFee: Int
}
