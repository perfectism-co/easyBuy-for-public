//
//  ListView.swift
//  easyBuy
//
// 
//  自訂義ListRow 支援舊ios

import SwiftUI
import SwiftfulUI


// 原生 GeometryReader
struct ListView<Label: View, Behind: View>: View {
    let label: () -> Label  //<名字: View> 讓外部可重複利用
    let behindView: (CGFloat) -> Behind
    @State private var labelHeight: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        
       ZStack(alignment: .trailing) {
           // 操作按鈕欄
           behindView(labelHeight) // 把量到的高度傳進去
               .background(Color.yellow)
           // 前景內容，可放 Text / Checkbox / Image 等
           label()
               .padding()
               .frame(maxWidth: .infinity)
               .background(Color.white)
               .background(
                   GeometryReader { geo in
                       Color.clear
                           .onAppear {
                               labelHeight = geo.size.height
                           }
                           .onChange(of: geo.size.height) { newValue in
                               labelHeight = newValue
                           }
                   }
               )
               .offset(x: offsetX + dragOffset)
               .gesture(
                   DragGesture()
                       .updating($dragOffset) { value, state, _ in
                           // 只允許向左拖
                           if value.translation.width < 0 {
                               state = value.translation.width
                           }
                       }
                       .onEnded { value in
                           // 若滑動超過 -80，就打開操作按鈕欄
                           withAnimation {
                               if value.translation.width < -80 {
                                   offsetX = -100
                               } else {
                                   offsetX = 0
                               }
                           }
                       }
               )
               .onTapGesture {
                   // 點擊時收回
                   withAnimation {
                       offsetX = 0
                   }
               }
           VStack {
               Spacer()
               Rectangle() // Rectangle 預設會撐滿父容器寬度
                   .frame(height: 1)
                   .foregroundColor(Color.gray.opacity(0.2))
           }
       }
       .fixedSize(horizontal: false, vertical: true) // 因 GeometryReader 本身會撐滿可用空間，所以要限制高度
    }
}
#Preview {
    struct Wrapper: View {
        @State private var items = ["項目 A", "項目 B", "項目 C"]

        var body: some View {
            VStack {
                ForEach(items, id: \.self) { item in
                    ListView {
                        Text(item)
                    } behindView: { height in
                        HStack {
                            Spacer()
                            Button(action: {
                                deleteAction(item)
                            }) {
                                Text("刪除")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .frame(height: height)
                                    .background(Color.red)
                            }

                        }
                    }
                }
            }
        }
        func deleteAction(_ item: String) {
            items.removeAll { $0 == item }
        }
        
        
    }
    return Wrapper()
}


#Preview {
    struct Wrapper2: View {
        @State private var items = ["項目 A", "項目 B", "項目 C"]

        var body: some View {
            VStack {
                ForEach(items, id: \.self) { item in
                    ListRow (
                        label:{
                            
                            Text(item)
                        },
                        behindView: { height in
                            HStack {
                                // 不可寫space;寫space必須訂義寬度
                                Button(action: {
                                    deleteAction(item)
                                }) {
                                    Text("刪除")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .frame(height: height)
                                        .background(Color.red)
                                }
                            }
                        },
                        behindBackgroundColor: Color.red, isDrag: true
                    )
                }
            }
        }
        func deleteAction(_ item: String) {
            items.removeAll { $0 == item }
        }
        
    }
    return Wrapper2()
}

 
// package readingFrame
struct ListRow<Label: View, Behind: View>: View {
    let label: () -> Label  //<名字: View> 讓外部可重複利用
    let behindView: (CGFloat) -> Behind
    var behindBackgroundColor: Color = .clear
    @State private var labelHeight: CGFloat = 0
    @State private var backButtonWidth: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    let isDrag: Bool

    var body: some View {
        
       ZStack(alignment: .trailing) {
           // 操作按鈕欄
           HStack{
               Spacer()
               behindView(labelHeight) // 把量到的高度傳進去
                   .readingFrame(onChange: { frame in
                       backButtonWidth = frame.width
                   })
           }
           .background(behindBackgroundColor)
           
           // 前景內容，可放 Text / Checkbox / Image 等
           label()
               .padding()
               .frame(maxWidth: .infinity)
               .background(Color.white)
               .readingFrame(onChange: { frame in
                   labelHeight = frame.height
               })
               .offset(x: offsetX + dragOffset)
               .gesture(
                   DragGesture()
                       .updating($dragOffset) { value, state, _ in
                           // 只允許向左拖
                           if value.translation.width < 0 {
                               state = value.translation.width
                           }
                       }
                       .onEnded { value in
                           // 若滑動超過 -80，就打開操作按鈕欄
                           withAnimation {
                               if value.translation.width < -80 {
                                   offsetX = -backButtonWidth
                               } else {
                                   offsetX = 0
                               }
                           }
                       }
               )
               .onTapGesture {
                   // 點擊時收回
                   withAnimation {
                       offsetX = 0
                   }
               }
               
             
               
           VStack {
               Spacer()
               Rectangle() // Rectangle 預設會撐滿父容器寬度
                   .frame(height: 1)
                   .foregroundColor(Color.gray.opacity(0.2))
           }
       }
       .fixedSize(horizontal: false, vertical: true) // 因 GeometryReader 本身會撐滿可用空間，所以要限制高度
    }
}

struct ListRowNoDrag<Label: View>: View {
    let label: () -> Label  //<名字: View> 讓外部可重複利用
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
          
           // 前景內容，可放 Text / Checkbox / Image 等
           label()
               .padding()

           Rectangle() // Rectangle 預設會撐滿父容器寬度
               .frame(height: 1)
               .foregroundColor(Color.gray.opacity(0.2))
       }
        .background(Color.white)
    }
}

#Preview {
    let items = ["項目 A", "項目 B", "項目 C"]
    ZStack {
        Color.yellow.edgesIgnoringSafeArea(.all)
        
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(items, id: \.self) { item in
                    
                    ListRowNoDrag {
                        Text(item).padding(100)
                    }
                }
            }
            HStack {}.frame(height: 80).background(Color.blue)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
      
    }
}
