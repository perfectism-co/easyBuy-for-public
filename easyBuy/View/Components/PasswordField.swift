//
//  PasswordField.swift
//  easyBuy
//
//  
//

import SwiftUI

struct PasswordField: View {
    @Binding var password: String
    @State private var isSecured: Bool = true

    var body: some View {
        ZStack(alignment: .leading) {
                HStack {
                    Group {
                        if isSecured {
                            SecureField("", text: $password)
                            
                        } else {
                            TextField("", text: $password)
                        }
                    }
                    .disableAutocorrection(true) // 不要自動修正拼字
                    .modifier(TextInputAutocapitalizationModifier()) // 完全不要自動大寫 自訂修飾符
                    
                    Button {
                        isSecured.toggle()
                    }label: {
                        Image(systemName: self.isSecured ? "eye.slash" : "eye")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding()
                .foregroundColor(.white)
                .frame(height: 54)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                
                if password.isEmpty {
                    Text("Password")
                        .foregroundColor(.white.opacity(0.5)) // ✅ 自訂 placeholder 顏色
                        .padding(.leading, 20)
                }
            }
    }
}


#Preview {
    ZStack {
        Color.black
        PasswordField(password: .constant("123"))
    }
    
}
