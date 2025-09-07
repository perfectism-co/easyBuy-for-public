//
//  RootView.swift
//  easyBuy
//
//  
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: PageRouter
    
    var body: some View {
        ZStack {
            ZStack { // all routers 全繪製，不依賴 ＠publish currentTab 來繪製view，避免currentTab更動時刷新頁面
                ForEach(router.allTabs, id: \.self) { tab in
                    AppCoordinatorView(tabKey: tab)
                        .opacity(router.currentTab == tab ? 1 : 0)
                }
            }
            
            if !router.hideTabBar {
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $router.currentTab,
                                 cartCount: authVM.user?.cart.count ?? 0)
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: router.hideTabBar)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .onChange(of: router.currentTab) { newTab in
            // 切換 Tab，先切換路徑，再設定該路徑 root
            let tabKey: String
            
            switch newTab {
            case "home":
                tabKey = "home"
            case "cart":
                tabKey = "cart"
            case "orders":
                tabKey = "orders"
            default:
                tabKey = "home"
            }
            
            router.switchTab(to: tabKey)
        }
        .onAppear {
            // 預設選 home tab 並設定 root
            let defaultTab = "home"
            router.switchTab(to: defaultTab)
            router.setRootNoAnimation(to: .home)
        }
        .onChange(of: router.currentStack) { stack in
            if let top = stack.last?.page {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    router.hideTabBar = top.isTabBarHide
                }
            }
        }
        .onChange(of: router.hideTabBar) { value in
            print("🧩 hideTabBar = \(value)")
        }
    }
}


#Preview {
    RootView()
        .environmentObject(AuthViewModel.preview())
        .environmentObject(PageRouter())
        .environmentObject(ProductViewModel())
        .environmentObject(ShippingViewModel())
        .environmentObject(CouponViewModel())
        .environmentObject(KeyboardObserver())
        .environmentObject(BottomSheetManager.shared)
}


            
