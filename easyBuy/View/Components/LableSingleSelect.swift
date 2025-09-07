//
//  LableSingleSelect.swift
//  easyBuy
//
//  
//

import SwiftUI

struct LableSingleSelect<Content: View>: View {
    @Binding var selected: String // 放入傳入的資料做對比用
    var theId: String //傳入的資料
    let content: () -> Content  // ✅ 改為 closure
    
    init(
        selected: Binding<String>,
        theId: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._selected = selected
        self.theId = theId
        self.content = content
    }
    
    var body: some View {
        
        HStack {
            content()
        }
        .background(selected == theId ? Color.bg.opacity(0.3) : Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(selected == theId ? Color.accentColor : Color.gray, lineWidth: selected == theId ? 3 : 1)
         )
        .onTapGesture {
            if selected == theId {
                selected = ""  // 點選已選的則取消選擇
            } else {
                selected = theId // 放資料進去
            }
        }
    }
}

#Preview {
    PreviewContainer()
}

struct PreviewContainer: View {
    
    @State private var selected: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            LableSingleSelect(
                selected: $selected,
                theId: "item1"
            ) {
                Text("選項 1")
                    .padding()
            }
            
            LableSingleSelect(
                selected: $selected,
                theId: "item2"
            ) {
                Text("選項 2")
                    .padding()
            }
            
            LableSingleSelect(
                selected: $selected,
                theId: "item3"
            ) {
                Text("選項 3")
                    .padding()
            }
        }
        .padding()
    }
}
