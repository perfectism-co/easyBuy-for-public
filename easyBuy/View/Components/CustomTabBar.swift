//
//  CustomTabBar.swift
//  easyBuy
//
//  
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: String
    var cartCount: Int

    var body: some View {
        
        VStack {
            HStack {
                TabBarItem(icon: selectedTab == "home" ? "house.fill" : "house", isSelected: selectedTab == "home") {
                    selectedTab = "home"
                }
                
                TabBarItem(icon: selectedTab == "cart" ? "cart.fill" : "cart", isSelected: selectedTab == "cart", badgeCount: cartCount) {
                    selectedTab = "cart"
                }
                
                TabBarItem(icon: selectedTab == "orders" ? "person.fill" : "person", isSelected: selectedTab == "orders") {
                    selectedTab = "orders"
                }
            }
            .padding(.vertical, 22)
            .background(
                Group {
                    if #available(iOS 15, *) {
                        // iOS 15+ 用系統毛玻璃材質
                        Color.clear.background(.ultraThinMaterial)
                    } else {
                        // iOS 13/14 自訂 VisualEffectBlur
                        VisualEffectBlur(blurStyle: .light)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 100))
            .overlay(
                RoundedRectangle(cornerRadius: 100) // 圓角 8
                    .stroke(Color.white, lineWidth: 0.4) // 藍色邊線，2pt
            )
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 16)
            .padding(.horizontal, 28)
            HStack {}.frame(height: 10)
        }
    }
}


#Preview {
    
    struct Wrapper: View {
        @State var selectedTab: String = "home"
        var body: some View {
            ZStack {
                Color.yellow.ignoresSafeArea()
                Rectangle().fill(Color.blue).frame(maxWidth: 100, maxHeight: .infinity)
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $selectedTab, cartCount: 2)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
    return Wrapper()
}
