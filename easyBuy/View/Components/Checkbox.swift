//
//  Checkbox.swift
//  easyBuy
//
//  
//

import SwiftUI

// 單選
struct CheckBoxSingle: View {
    @Binding var selectedId: String?
    @Binding var selectedTheId: String
    var theId: String
    
    var body: some View {
        HStack{
            Image(systemName: selectedId == theId ? "checkmark.square.fill" : "square")
                .foregroundColor(selectedId == theId ? .blue : .gray)
                .onTapGesture {
                    if selectedId == theId {
                        selectedId = nil  // 點選已選的則取消選擇
                        selectedTheId = ""
                    } else {
                        selectedId = theId
                        selectedTheId = theId  // ✅ 單選重點
                    }
                }
            Text(theId)
        }
        
    }
}


// 可多選、可呼叫動作
struct CheckBox<Label: View>: View {
    let item: String
    @Binding var selections: [String: Bool]
    var onToggle: ((Bool) -> Void)? = nil // 點擊時可呼叫動作
    var label: () -> Label

    var body: some View {
        HStack {
            Image(systemName: (selections[item] ?? false) ? "checkmark.square.fill" : "square")
                .foregroundColor((selections[item] ?? false) ? .accentColor : .secondary)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
                .onTapGesture {
                    let newVal = !(selections[item] ?? false)
                    selections[item] = newVal
                    onToggle?(newVal)
                }
            
            label()
        }
    }
}

// 提供一個沒有 label 的 init，之後即可不寫label
extension CheckBox where Label == EmptyView {
    init(item: String,
         selections: Binding<[String: Bool]>,
         onToggle: ((Bool) -> Void)? = nil) {
        self.item = item
        self._selections = selections
        self.onToggle = onToggle
        self.label = { EmptyView() }
    }
}


#Preview {
    struct Wrapper: View {
        let options = ["蘋果", "香蕉", "芒果"]
        @State private var selections: [String: Bool] = [:] // 多選用
        @State var selectedId: String? = nil // 單選用
        @State private var selectedTheId: String = "" // 單選用

        var body: some View {
            
            // 單選
            VStack(alignment: .leading) {
                Text("單選").bold().foregroundColor(.orange)
                ForEach(options, id: \.self) { item in
                    CheckBoxSingle(selectedId: $selectedId, selectedTheId: $selectedTheId, theId: item)
                }

                Divider().padding(.vertical, 10)
                Text("選中的是：\(selectedTheId)")

                Button("送出") {
                    let selected = selections.filter { $0.value }.map { $0.key }
                    print("✅ 選中的是：\(selected)")
                }
            }
            .padding()
            
            // 多選
            VStack(alignment: .leading) {
                Text("多選").bold().foregroundColor(.purple)
                ForEach(options, id: \.self) { item in
                    CheckBox(item: item, selections: $selections) { newVal in
                        print("\(item) 變更：\(newVal)")
                    } label: {
                        HStack {
                            Text(item)
                            Image(systemName: "leaf")
                        }
                    }
                }

                Divider().padding(.vertical, 10)
                Text("選中的有：\(selections.filter { $0.value }.map { $0.key })")
                Button("送出") {
                    let selected = selections.filter { $0.value }.map { $0.key }
                    print("✅ 選中的有：\(selected)")
                }
            }
            .padding()
            
        }
    }
    return Wrapper()
}

