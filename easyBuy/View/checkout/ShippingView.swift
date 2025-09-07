//
//  ShippingIView.swift
//  easyBuy
//
//  
//

import SwiftUI

struct ShippingView: View {
    @EnvironmentObject var shippingVM: ShippingViewModel
    @Binding var selected: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            Text("ShippingMethod").font(.headline)
            
            ForEach(shippingVM.shippings) { shipping in
                LableSingleSelect(selected: $selected, theId: shipping.id) {
                    HStack {
                        Text("🚚")
                        Text(shipping.shippingMethod)
                        Spacer()
                        Text("＄\(shipping.ShippingFee)")
                    }
                    .padding(8)
                    .frame(width: 280, height: 70)
                }
            }

            HStack {
                if let selected = shippingVM.shippings.first(where: { $0.id == selected }) {
                    Text("Selected：\(selected.shippingMethod)")
                } else {
                    Text("Not Selected")
                }
                Spacer()
            }
        }
        .onAppear {
            Task {
                await shippingVM.fetchShipping()
            }
            
            // 在這裡安全地從 vm 設定 selectedId
//            if selected == nil {
//                selected = returnSelected
//            }
        }
        
    }
    
}

#Preview {
    ShippingView(selected: .constant(""))
        .environmentObject(AuthViewModel.preview())
        .environmentObject(ShippingViewModel())
}

