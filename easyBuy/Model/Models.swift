//
//  Models.swift
//
//
//
//

import Foundation
import UIKit // for UIImage

// MARK: - 🧍 User
struct User: Codable {
    let id: String  // only one
    let email: String  // only one
    var orders: [Order]
    var cart: [Product]
}

// MARK: - 📦 Order
struct Order: Codable, Identifiable, Equatable {
    var id: String
    var products: [Product]
    var shippingMethod: String
    var createdAt: Date
    var totalAmount: Int
    var shippingFee: Int
    var coupon: Coupon?
    var review: Review

    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case products
        case shippingMethod
        case createdAt
        case totalAmount
        case shippingFee
        case coupon
        case review
    }
}


struct OrderRequest: Codable {
    var products: [Product]
    var couponId: String?
    var shippingId: String
}

extension OrderRequest {
    var isEmpty: Bool {
        products.isEmpty && shippingId.isEmpty
    }
    
    static let empty = OrderRequest(products: [], couponId: "", shippingId: "")
}

struct NewOrderRequest {
    var products: [Product]=[]
    var couponId: String?
    var shippingId: String = ""
    
    func toOrderRequest() -> OrderRequest {
        return OrderRequest(
            products: products,
            couponId: couponId,
            shippingId: shippingId
        )
    }
}


// MARK: - 🛍️ Product
struct Product: Codable, Identifiable, Equatable {
    var id: String
    var productId: String
    var name: String
    var imageUrl: [String]
    var price: Int
    var quantity: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case productId
        case name
        case imageUrl
        case price
        case quantity
    }
}
// MARK: - 🛒 Cart
struct CartItem: Codable {
    var productId: String
    var quantity: Int
}

struct CartRequest: Codable {
    var products: [CartItem]
}

extension CartRequest {
    static var empty: CartRequest {
        CartRequest(products: [])
    }
}

struct CartResponse: Codable {
    var cart: CartData
}

struct CartData: Codable {
    var products: [Product]
}

struct DeleteCartRequest: Codable {
    var productIds: [String]
}

// MARK: - Coupon, Review
// 🎟️ Coupon（optional）
struct Coupon: Codable, Equatable {
    var code: String?
    var discount: Int?
    
    var isEmpty: Bool {
        return code == nil && discount == nil
    }
}

// ⭐ Review（Permanently present）
struct Review: Codable, Equatable {
    var comment: String?
    var rating: Int?
    var imageUrls: [String]
    
    var isEmpty: Bool {
        (comment?.isEmpty ?? true) &&
        (rating == nil) &&
        imageUrls.isEmpty
    }
}


struct AddReviewRequest {
    let orderId: String
    let comment: String
    let rating: Int
    let images: [UIImage]
}




