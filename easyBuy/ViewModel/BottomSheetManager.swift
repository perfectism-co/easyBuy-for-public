//
//  BottomSheetManager.swift
//  easyBuy
//
//  
//

import SwiftUI

final class BottomSheetManager: ObservableObject {
    static let shared = BottomSheetManager()

    @Published var isPresented: Bool = false
    @Published var height: CGFloat = 300
    @Published var content: AnyView? = nil

    private init() {}

    func show<Content: View>(height: CGFloat, @ViewBuilder content: () -> Content) {
        self.height = height
        self.content = AnyView(content())
        withAnimation {
            self.isPresented = true
        }
    }

    func hide() {
        withAnimation {
            self.isPresented = false
        }
    }
}
