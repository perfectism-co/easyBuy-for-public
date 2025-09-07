//
//  Toast.swift
//  easyBuy
//
// 
//

import SwiftUI

struct Toast: View {
    var text: String
    @Binding var showToast: Bool
    var body: some View {
        Text(text)
            .padding()
            .background(Color.black.opacity(0.7))
            .foregroundColor(.white).foregroundColor(.white)
            .cornerRadius(10)
            .padding()
            
    }
}
#Preview {
    struct PreviewWrapper: View {
        @State private var show = true

        var body: some View {
            Toast(text: "Hello World!", showToast: $show)
        }
    }

    return PreviewWrapper()
}
