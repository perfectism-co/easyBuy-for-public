//
//  CouponViewModel.swift
//  easyBuy
//
// 
//

import Foundation


@MainActor
class CouponViewModel: ObservableObject {
    @Published var coupons: [OpenCoupon] = []
    
    func fetchCoupon() async {
        guard let url = URL(string: "https://raw.githubusercontent.com/perfectism-co/easyBuy/main/fakeCouponDatabase.json") else {
            print("❌ URL 無效")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let dict = try JSONDecoder().decode([String: CouponInfo].self, from: data)
            
            self.coupons = dict.map { key, value in
                OpenCoupon(id: key, code: value.code, discount: value.discount)
            }
            .sorted { $0.id < $1.id }
        } catch {
            print("❌ 下載或解析失敗: \(error)")
        }
    }
}


struct OpenCoupon: Identifiable, Codable {
    let id: String
    let code: String
    let discount: Int
}


// Intermediate use: parse the value part of JSON first
struct CouponInfo: Codable {
    let code: String
    let discount: Int
}
