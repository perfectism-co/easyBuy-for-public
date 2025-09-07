//
//  CustomStepper.swift
//  easyBuy
//
//  
//

import SwiftUI

// MARK: - CustomStepper
struct CustomStepper: View {
    var range: ClosedRange<Int>
    var step: Int = 1
    @Binding var value: Int
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 16) {

            HStack(spacing: 0) {
                Image(systemName: "minus")
                    .font(.system(size: 10))
                    .foregroundColor(value == 1 ? .gray.opacity(0.6) :.primary)
                    .frame(width: 26, height: 80)
                    .background(Color.bg)
                    .onTapGesture {
                        if value > range.lowerBound {
                            value -= step
                        }
                    }

                Rectangle() //分線
                    .frame(width: 2, height: 20)
                    .foregroundColor(.white)
                
                TextField("", text: $text)
                    .keyboardType(.numberPad)
                    .foregroundColor(.primary)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .focused($isFocused)
                    .onAppear {
                        text = String(value) // 初始值
                    }
                    .toolbar { // 鍵盤上方工具列
                        ToolbarItemGroup(placement: .keyboard) {
                        if isFocused { // ✅ 只在目前聚焦的欄位顯示工具列,避免ForEach重複遍歷
                            
                                Spacer()
                                Button("完成") {
                                    isFocused = false // 收鍵盤
                                    
                                    // 嘗試轉成 Int 並檢查最小值
                                    if let intValue = Int(text), intValue >= 1 {
                                        value = intValue
                                        text = String(intValue) // ✅ 顯示去除前導 0 的新值
                                    } else {
                                        text = String(value) // 無效輸入還原
                                    }
                                }
                            }
                        }
                   }
                
                
                Rectangle() //分線
                    .frame(width: 2, height: 20)
                    .foregroundColor(.white)
                
                Image(systemName: "plus")
                    .font(.system(size: 10))
                    .foregroundColor(.primary)
                    .frame(width: 26, height: 80)
                    .background(Color.bg)
                    .onTapGesture {
                        if value < range.upperBound {
                            value += step
                        }
                    }

            }
        }
        .onChange(of: value) { newValue in
                text = String(newValue)
            }
        .frame(height: 24)
        .background(Color.bg)
        .cornerRadius(8)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var value = 1

        var body: some View {
            CustomStepper(range: 1...100, value: $value)
        }
    }

    return PreviewWrapper()
}

