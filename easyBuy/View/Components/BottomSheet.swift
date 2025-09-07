//
//  BottomSheet.swift
//  easyBuy
//
//  
//

import SwiftUI


struct BottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let height: CGFloat
    let content: Content

    @GestureState private var dragOffset: CGFloat = 0  // 拖動狀態
    @State private var currentOffset: CGFloat = 0      // 動畫平滑處理

    init(isPresented: Binding<Bool>, height: CGFloat = 300, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.height = height
        self.content = content()
    }

    var body: some View {
        ZStack {
            // 背景
            if isPresented {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(0)
            }

            if isPresented {
                VStack(spacing: 0) {
                    Spacer()
                    VStack {
                            RoundedRectangle(cornerRadius: 100)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 90, height: 4)
                                .padding(.top, 12)
                            
                            content
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .init(horizontal: .center, vertical: .top))
                                .padding().padding(.bottom, 20)
                        
                    }
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -2)
                    .offset(y: currentOffset + dragOffset) // 加入偏移量
                    .onChange(of: isPresented) { newValue in
                        if newValue {
                            // 每次打開時歸零，確保向上滑入正常
                            currentOffset = 0
                        }
                    }
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                // 只允許往下拖動
                                if value.translation.height > 0 {
                                    state = value.translation.height
                                }
                            }
                            .onEnded { value in
                                if value.translation.height > 70 {
                                    // 拖太遠就關閉
                                    // 👉 記錄最後拖動的 offset
                                    currentOffset = value.translation.height

                                    // 👉 等動畫自然關閉（由 transition 負責）
                                    withAnimation {
                                        isPresented = false
                                    }
                                } else {
                                    // 沒拖夠就彈回來
                                    withAnimation {
                                        currentOffset = 0
                                    }
                                }
                            }
                    )
                    .onDisappear {
                        // ✅ 視圖關閉後才重設 offset，避免動畫跳回
                        currentOffset = 0
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom),  // 出現：由下往上滑入
                        removal: .move(edge: .bottom)     // 消失：往下滑出
                    )
                )
                .zIndex(1)
            }
        }
        .animation(.easeInOut, value: isPresented)
        .edgesIgnoringSafeArea(.all)
    }
}


// BottomSheetModifier.swift
// 語法糖（語法擴充）.bottomSheet
struct BottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let height: CGFloat
    let sheetContent: SheetContent

    init(isPresented: Binding<Bool>, height: CGFloat, @ViewBuilder content: () -> SheetContent) {
        self._isPresented = isPresented
        self.height = height
        self.sheetContent = content()
    }

    func body(content: Content) -> some View {
        ZStack {
            content

            BottomSheet(isPresented: $isPresented, height: height) {
                sheetContent
            }
            .zIndex(999)
            .allowsHitTesting(isPresented) // 隱藏時不攔截點擊

        }
    }
}

extension View {
    func bottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        height: CGFloat = 300,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        self.modifier(BottomSheetModifier(isPresented: isPresented, height: height, content: content))
    }
}



#Preview {
    struct Preview: View {
        @State var isPresented: Bool = false
        var body: some View {
            Text("Hello, World!")
                .onTapGesture {
                    isPresented.toggle()
                }
                .bottomSheet(isPresented: $isPresented) {
                    Text("Hello, World!")
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.blue)
                }
        }
    }
    return Preview()
}
