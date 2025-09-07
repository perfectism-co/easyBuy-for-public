//
//  ConstView.swift
//  easyBuy
//
// 
//

import SwiftUI

struct CouponView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var couponVM: CouponViewModel
    @Binding var selected: String

   
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            Text("Coupon").font(.headline)                        
           
            ForEach(couponVM.coupons) { coupon in
                LableSingleSelect(selected: $selected, theId: coupon.id) {
                    HStack {
                        Text("🎉")
                        Text(coupon.code)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.pink)
                        Spacer()
                        Text("＄\(coupon.discount)")
                    }
                    .padding(8)
                    .frame(width: 280, height: 70)
                }
            }

            HStack {
                if let selected = couponVM.coupons.first(where: { $0.id == selected }) {
                    Text("Selected：\(selected.code)")
                } else {
                    Text("Not Selected")
                }
                Spacer()
            }
        }
        .onAppear {
            Task {
                await couponVM.fetchCoupon()
            }            
        
            // 在這裡安全地從 vm 設定 selectedId
//            if selectedId == nil {
//                selectedId = selected
//            }
        }
        
    }
    
}
#Preview {
    CouponView(selected: .constant(""))
        .environmentObject(AuthViewModel.preview())
        .environmentObject(CouponViewModel())
}
