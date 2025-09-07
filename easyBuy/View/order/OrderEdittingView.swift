//
//  UpdateOrderView.swift
//  easyBuy
//
// 
//

import SwiftUI

struct OrderEdittingView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var shippingVM: ShippingViewModel
    @EnvironmentObject var couponVM: CouponViewModel
    @EnvironmentObject var router: PageRouter
    @State private var showShoppingSheet: Bool = false
    @State private var showConstSheet: Bool = false
    @State private var showAlert: Bool = false
    
    @State private var shippingId: String = ""
    @State private var couponId: String = ""
    
    @State private var productQuantities: [String: Int] = [:] // [productId: quantity]
    
    let order: Order
    
    private var computedTotalAmount: Int {
        // 商品總價
        let productsTotal = order.products.reduce(0) { total, product in
            // 取得此商品的最新數量（如果使用者有更改，就使用新數量；否則用原本訂單數量）
            let quantity = productQuantities[product.productId] ?? product.quantity
            
            // 將當前商品的價格 × 數量，加到總金額中
            return total + product.price * quantity
        }
        
        // 運費（根據使用者當前選擇）
        let shippingFee = shippingVM.shippings.first(where: { $0.id == shippingId })?.ShippingFee ?? order.shippingFee
        
        // 折扣（根據使用者當前選擇）
        let discount = couponVM.coupons.first(where: { $0.id == couponId })?.discount ?? (order.coupon?.discount ?? 0)
        
        return productsTotal + shippingFee - discount
    }
    

    
    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                HStack { }.frame(height: 48)
                VStack(spacing: 0) {
                    ListRowNoDrag {
                        VStack(alignment: .leading, spacing: 30) {
                            Text("Order ID: \(order.id)")
                                .font(.callout)
                                .fontWeight(.medium)
                            
                            ForEach(order.products, id: \.productId) { product in
                                EdittingProductRow(product: product)
                            }
                            
                            orderInfoOrig
                        }
                    }
                    
                    newOrderInfo
                    
                    ListRowNoDrag {
                        VStack (spacing: 40){
                            HStack {
                                Spacer()
                                Text("Total: $\(computedTotalAmount)").fontWeight(.bold)
                            }
                            
                            PrimaryFilledButton(title: "Submit Changes") {
                                guard !shippingId.isEmpty else  {
                                    showAlert = true
                                    return
                                }
                                Task {
                                    // ✅ 套用新數量（根據 vm.productQuantities）
                                    let updatedProducts = order.products.map { product -> Product in
                                        var updated = product
                                        if let newQty = productQuantities[product.productId] {
                                            updated.quantity = newQty
                                        }
                                        return updated
                                    }

                                    // ✅ 準備新訂單資料
                                    vm.newOrderRequest = OrderRequest(
                                        products: updatedProducts,
                                        couponId: couponId,
                                        shippingId: shippingId
                                    )
                                    
                                    await vm.updateOrder(order: order)
                                    DispatchQueue.main.async {
                                        router.pop() 
                                    }
                                }
                            }
                        }
                    }
                    
                }
                .padding(8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                HStack {}.frame(height: 60)
            }
            .padding(.horizontal)

            HeaderView(text: "Update Order", bgColor: .bg, showBackButton: true)
        }
        .bottomSheet(isPresented: $showShoppingSheet, height: 450) {
            ShippingView(selected: $shippingId)
        }
        .bottomSheet(isPresented: $showConstSheet, height: 450) {
            CouponView(selected: $couponId)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(""),
                message: Text("Shipping method not selected."),
                dismissButton: .default(Text("OK"), action: {showAlert = false})
            )
        }
        .onAppear {
            Task {
                await shippingVM.fetchShipping()
                await couponVM.fetchCoupon()
            }
        }
        .navigationBarHidden(true)
    }
    
// MARK: - 子元件：ProductRow
    private func EdittingProductRow(product: Product) -> some View {
        VStack(alignment: .leading) {
            HStack (spacing: 16){
                Image60(theUrl: product.imageUrl.first ?? "")
                
                VStack(alignment: .leading) {
                    Text("Product ID: \(product.productId)")
                        .font(.caption2)
                        .foregroundColor(Color.gray)
                    Text(product.name)
                        .lineLimit(1)
                    HStack {
                        Text("$ \(product.price)")
                        Spacer()
                        Text("x \(product.quantity)")
                            .foregroundColor(Color.gray)
                    }
                }
            }
            
            let bindingQuantity = Binding<Int>(
                get: {
                    productQuantities[product.productId] ?? product.quantity
                },
                set: { newValue in
                    productQuantities[product.productId] = newValue
                }
            )

            Stepper("Update Qty: \(bindingQuantity.wrappedValue)", value: bindingQuantity, in: 1...100)

        }
        .font(.callout)
    }
    
    
    
    private var orderInfoOrig: some View {
        VStack {
            HStack {
                Text("Shipping: \(order.shippingMethod)")
                Spacer()
                Text("$ \(order.shippingFee)")
            }
            if let coupon = order.coupon {
                HStack {
                    Text("Coupon: \(coupon.code ?? "")")
                    Spacer()
                    Text("-$ \(coupon.discount ?? 0)")
                }
            }
            
            HStack {
                Text("Date: \(order.createdAt.orderFormattedTime)")
                Spacer()
                Text("Total: $\(order.totalAmount)").fontWeight(.bold)
            }
        }
        .font(.callout)
        .foregroundColor(.gray)
    }
    
    private var newOrderInfo: some View {
        Group {
            ListRowNoDrag {
                Button {
                    withAnimation {
                        showShoppingSheet = true
                    }
                } label: {
                    HStack{
                        Text("Shipping Info")
                        Spacer()
                        
                        if let selected = shippingVM.shippings.first(where: { $0.id == shippingId }) {
                            Text(selected.shippingMethod)
                            Text("$\(selected.ShippingFee)")
                        }else {
                            Text("Not Selected")
                        }
                    }
                    .lineLimit(1)
                }
            }
            ListRowNoDrag {
                Button {
                    withAnimation {
                        showConstSheet = true
                    }
                    
                } label: {
                    HStack{
                        Text("Coupon")
                        Spacer()
                        
                        if let selected = couponVM.coupons.first(where: { $0.id == couponId }) {
                            Text(selected.code)
                            Text("- $\(selected.discount)")
                        }else {
                            Text("Not Selected")
                        }
                    }
                    .lineLimit(1)
                }
            }
        }
        .foregroundColor(.primary)
    }
}





// Preview
#Preview{
    let previewVM = AuthViewModel.preview()
    if let order = previewVM.user?.orders.first {
        OrderEdittingView(order: order)
            .environmentObject(AuthViewModel.preview())
            .environmentObject(ShippingViewModel())
            .environmentObject(CouponViewModel())
    }
}


