//
//  easyBuyApp.swift
//  easyBuy
//
//  
//

import SwiftUI

@main
struct easyBuyApp: App {
    init() {
        // 強制全 App 使用淺色模式
        UIView.appearance().overrideUserInterfaceStyle = .light
    }

    @StateObject private var authVM = AuthViewModel()
    @StateObject private var vmPd = ProductViewModel()
    @StateObject private var shippingVM = ShippingViewModel()
    @StateObject private var couponVM = CouponViewModel()
    
    @StateObject private var keyboard = KeyboardObserver()
    @StateObject var router = PageRouter()
    

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isAutoLoading {
                    LoadingView()
                }
                else if authVM.isLoggedIn {
                    RootView()
                        
                } else {
                    EntryView()
                }
            }
            .environmentObject(authVM)
            .environmentObject(vmPd)
            .environmentObject(shippingVM)
            .environmentObject(couponVM)
            .environmentObject(keyboard)
            .environmentObject(router)
        }
        
    }
}
