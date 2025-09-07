//
//  CellTab.swift
//  easyBuy
//
//  
//

import SwiftUI

struct CellTab: View {
    let text: String    // 每個 Cell 的文字
    var notSelectedColor: Color = .white
    @Binding var selected: String     // 當前被選到的 tab
    var onTap: (() -> Void)? = nil    // 額外點擊動作（可選）

    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .fontWeight(selected == text ? .bold : .regular)
            .foregroundColor(selected == text ? Color.white : Color.primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(selected == text ? Color.accentColor : notSelectedColor)
            .cornerRadius(100)
            .onTapGesture {
                selected = text         // 內建的切換邏輯
                onTap?()                // 外部自定義邏輯
            }
    }
}

#Preview {
    CellTabListPreview()
}

struct CellTabListPreview: View {
    @State private var selected = "Apple"
    let tabs = ["Apple", "Banana", "Orange"]

    var body: some View {
        ZStack {
            Color.white
            HStack {
                ForEach(tabs, id: \.self) { label in
                    CellTab(text: label, notSelectedColor: Color.bg, selected: $selected){}
                }
            }
            .padding()
        }
    }
}




