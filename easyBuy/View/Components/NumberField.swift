//
//  NumberField.swift
//  easyBuy
//
//  
//

import SwiftUI

struct NumberField: View {
    let placeholder: String
    @Binding var number: Double
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField(placeholder, value: $number, format: .number)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.numberPad)
            .focused($isFocused)
            .toolbar { // 鍵盤上方工具列
                ToolbarItemGroup(placement: .keyboard) {
                    if isFocused { // ✅ 只在目前聚焦的欄位顯示工具列,避免ForEach重複遍歷
                        Spacer()
                        Button("Done") {
                            isFocused = false // 收鍵盤
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
    }
}

#Preview {
    NumberField(placeholder: "Input number", number: .constant(0))
}
