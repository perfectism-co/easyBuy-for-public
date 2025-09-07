//
//  Button.swift
//  easyBuy
//
//  
//

import SwiftUI

struct PrimaryFilledButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}


struct SecondaryFilledButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(BorderedButtonStyle())
        .controlSize(.large)
    }
}



struct IconFilledButton: View {
    let iconName: String
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .frame(width: width, height: height)
        }
        .buttonStyle(.borderedProminent)
    }
}


#Preview{
    PrimaryFilledButton(title: "123"){}
    SecondaryFilledButton(title: "123"){}
    IconFilledButton(iconName: "slider.horizontal.3") {}
}
