//
//  KeyboardObserver.swift
//  easyBuy
//
//  
//

import SwiftUI
import Combine

class KeyboardObserver: ObservableObject {
    @Published var isKeyboardVisible: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { _ in true }
        
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in false }
        
        // Merge two publishers and update isKeyboardVisible
        Publishers.Merge(willShow, willHide)
            .receive(on: RunLoop.main)
            .assign(to: &$isKeyboardVisible)
    }
}

