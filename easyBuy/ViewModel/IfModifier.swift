//
//  File.swift
//  easyBuy
//
//  
//

import SwiftUI

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)   // 條件成立 → 套用 transform
        } else {
            self              // 否則 → 原樣回傳
        }
    }
}
