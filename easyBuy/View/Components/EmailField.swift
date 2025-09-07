//
//  EmailField.swift
//  easyBuy
//
//  
//

import SwiftUI

struct EmailField: View {
    @Binding var text: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            TextField("", text: $text)
                .keyboardType(.emailAddress) // 使用 Email 專用鍵盤
                .autocorrectionDisabled(true) // 不要自動修正拼字
                .padding()
                .frame(height: 54)
                .foregroundColor(.white)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .modifier(TextInputAutocapitalizationModifier())
            
            if text.isEmpty {
                Text("Email")
                    .foregroundColor(.white.opacity(0.5)) // ✅ 自訂 placeholder 顏色
                    .padding(.leading, 20)
            }
        }
    }
}

// 完全不要自動大寫 自訂修飾符
struct TextInputAutocapitalizationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content.textInputAutocapitalization(.none)
        } else {
            content.autocapitalization(.none)
        }
    }
}



#Preview {
    struct Wrapper: View {
        var body: some View {
            ZStack {
                Color.black.opacity(0.8).ignoresSafeArea()
                Rectangle().fill(Color.blue).frame(maxWidth: 100, maxHeight: .infinity)
                VStack {
                    EmailField(text: .constant(""))
                }
                .ignoresSafeArea()
            }
            
        }
    }
    return Wrapper()
    
}


//struct AutoCorrectionModifier: ViewModifier {
//    func body(content: Content) -> some View {
//        if #available(iOS 14.0, *) {
//            content.environment(\.autocorrectionDisabled, true)
//        } else {
//            content // iOS 13：不處理，避免錯誤
//        }
//    }
//}
