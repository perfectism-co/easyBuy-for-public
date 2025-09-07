//
//  IconCount.swift
//  easyBuy
//
//  
//

import SwiftUI

struct IconCount: View {
    @State private var cartCount = 100
    
    var body: some View {
        VStack(spacing: 20) {
            // 語法糖寫法
            Image(systemName: "cart")
                .resizable()
                .frame(width: 24, height: 24)
                .iconCount(cartCount)
                .frame(width: 50, height: 50)
                .background(Color.red.opacity(0.2))
            
            Image(systemName: "cart")
                .resizable()
                .frame(width: 28, height: 28)
                .iconCount(cartCount)
                .background(Color.red.opacity(0.2))

            Button("加一件商品") {
                cartCount += 1
            }
            
            Button("減一件商品") {
                cartCount -= 1
                
            }

            Button("清空購物車") {
                cartCount = 0
            }
            
            Text("購物車數量：\(cartCount)")
        }
        .padding()
    }
}


// MARK: - 語法糖：加上紅點數字的 icon
extension View {
    func iconCount(
        _ count: Int,
        maxDisplay: Int = 99,
        offset: CGSize = CGSize(width: 10, height: -12),
        color: Color = .red
    ) -> some View {
        ZStack {
            self

            if count > 0 {
                Text(count > maxDisplay ? "\(maxDisplay)+" : "\(count)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(2)
                    .frame(minWidth: 17)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 100))
                    .offset(count > maxDisplay ?  CGSize(width: 18, height: -12) : offset)
            }
        }
    }

}


struct IconCount_Previews: PreviewProvider {
    static var previews: some View {
        IconCount()
    }
}
