//
//  Image.swift
//  easyBuy
//
//  
//

import SwiftUI
import SDWebImageSwiftUI

struct Imager: View {
    let theUrl: String
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 0
    
    // 傳入一個閉包，接收 WebImage 回傳 AnyView
    let imageModifier: (AnyView) -> AnyView
    
    @State private var isLoading = true
    @State private var isFailed = false
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            if isLoading {
                // 載入中：灰底漸層動畫
                LinearGradient(
                    gradient: Gradient(colors: [
                        isAnimating ?Color.gray.opacity(0.02):Color.gray.opacity(0.1),
                        isAnimating ?Color.gray.opacity(0.06):Color.gray.opacity(0.02),
                        isAnimating ?Color.gray.opacity(0.1):Color.gray.opacity(0.02)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .animation(
                    .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
            }

            imageModifier(
                AnyView(
                    WebImage(url: URL(string: theUrl))
                        .onSuccess { _, _, _ in
                            isLoading = false
                            isFailed = false
                        }
                        .onFailure { _ in
                            isLoading = false
                            isFailed = true
                        }
                        .resizable()
                )
            )
            .opacity(isLoading || isFailed ? 0 : 1)
            
            if isFailed {
                Image(systemName: "xmark.octagon")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .padding(20)
                    .frame(width: width, height: height)
                    .background(Color.gray.opacity(0.1)) // ⚠️ 圖片載入中或失敗時的背景
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}





struct Image60: View {
    let theUrl: String
    var body: some View {
//        Imager(theUrl: theUrl, width: 60, height: 60, cornerRadius: 8){ imageView in
//            imageView
//                .scaledToFill()
//                .eraseToAnyView()  // 下面示範如何實作這個擴展
//        }
        ImagerNoAnimated(theUrl: theUrl, width: 60, height: 60, cornerRadius: 8){ imageView in
            imageView
                .scaledToFill()
                .eraseToAnyView()
        }
    }
}


struct ImagerFill: View {
    let theUrl: String
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 0
    
    var body: some View {
        ImagerNoAnimated(theUrl: theUrl, width: width, height: height, cornerRadius: cornerRadius){ imageView in
            imageView
                .aspectRatio(contentMode: .fill)
                .eraseToAnyView()
        }
    }
}

struct ImagerFit: View {
    let theUrl: String
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 0
    
    var body: some View {
        ImagerNoAnimated(theUrl: theUrl, width: width, height: height, cornerRadius: cornerRadius){ imageView in
            imageView
                .scaledToFit()
                .eraseToAnyView()
        }
    }
}



//無動畫
struct ImagerNoAnimated: View {
    let theUrl: String
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 0
    let imageModifier: (AnyView) -> AnyView
    
    var body: some View {
        
            imageModifier(
                AnyView(
                    WebImage(url: URL(string: theUrl))
                        .resizable() // ✅ 放在 placeholder 之後
                        .indicator(.activity) // ✅ 顯示 Activity Indicator
                        .transition(.fade(duration: 0.5)) // 🌫 淡入動畫
                    //                    .aspectRatio(contentMode: .fill)
                       
                )
            )
            .frame(width: width, height: height)
            .background(
                Color.gray.opacity(0.1) // ⚠️ 圖片載入中或失敗時的背景
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}



#Preview {
    struct Wrapper: View {
//        let value = "https://picsum.photos/id/1018/200/300"
        let value: String = "https://picsum.photos/id/1018/200/300"
        var body: some View {
            VStack {
                ImagerNoAnimated(theUrl: value, width: 60, height: 60, cornerRadius: 8){ imageView in
                    imageView
                        .scaledToFill()
                        .eraseToAnyView()
                }
                Imager(theUrl: value, width: 60, height: 60, cornerRadius: 8){ imageView in
                    imageView
                        .scaledToFill()
                        .clipped()
                        .eraseToAnyView()  // 下面示範如何實作這個擴展
                }
                Imager(theUrl: value, width: 300, height: 60){ imageView in
                    imageView
                        .scaledToFill()
                        .clipped()
                        .eraseToAnyView()  // 下面示範如何實作這個擴展
                }
                LoadingAnimated()
            }
            
        }
    }
    return Wrapper()
}



// test
struct LoadingAnimated: View {
    @State private var isAnimating = false

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                isAnimating ?Color.gray.opacity(0.02):Color.gray.opacity(0.1),
                isAnimating ?Color.gray.opacity(0.06):Color.gray.opacity(0.02),
                isAnimating ?Color.gray.opacity(0.1):Color.gray.opacity(0.02)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
            .frame(width: 300, height: 100)
            .animation(
                .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

