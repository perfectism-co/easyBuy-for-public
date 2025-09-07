//
//  TabBarItem.swift
//  easyBuy
//
//  
//

import SwiftUI

struct TabBarItem: View {
    let icon: String
    var label: String?
    let isSelected: Bool
    var badgeCount: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .accent : .accent)
                        .iconCount(badgeCount)
                }
                if (label != nil) {
                    Text(label ?? "")
                        .font(.caption)
                        .foregroundColor(isSelected ? .accent : .accent)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    TabBarItem(icon: "house", label: "123", isSelected: true, action: {})
}
