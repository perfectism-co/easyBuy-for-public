//
//  CheckoutView.swift
//  easyBuy
//
//  
//

import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var shippingVM: ShippingViewModel
    @EnvironmentObject var couponVM: CouponViewModel
    @EnvironmentObject var router: PageRouter

    @State private var isShowAlert: Bool = false
    @State private var isShowShoppingSheet: Bool = false
    @State private var isShowConstSheet: Bool = false
    
    @State private var shippingId: String = ""
    @State private var couponId: String = ""
   
    var data: CheckoutData
        
    private var totalPrice: Int {
        let selectedS = shippingVM.shippings.first(where: { $0.id == shippingId })
        let selectedC = couponVM.coupons.first(where: { $0.id == couponId })
        let total = data.totalPrice + (selectedS?.ShippingFee ?? 0) - (selectedC?.discount ?? 0)
        return total
    }
    
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                HStack { }.frame(height: 10)
               
                List(data.products) { product in
                    listRow(product: product)
                }

                bottomView
            }

            HeaderView(text: "Checkout", bgColor: .bg, showBackButton: true)
        }
        .navigationBarHidden(true)
        .bottomSheet(isPresented: $isShowShoppingSheet, height: 450) {
            ShippingView(selected: $shippingId)
        }
        .bottomSheet(isPresented: $isShowConstSheet, height: 450) {
            CouponView(selected: $couponId)
        }
        .alert(isPresented: $isShowAlert) {
            Alert(
                title: Text(""),
                message: Text("Shipping method not selected."),
                dismissButton: .default(Text("OK"), action: {isShowAlert = false})
            )
        }
        .onAppear {
            Task {
                await shippingVM.fetchShipping()
                await couponVM.fetchCoupon()
            }
        }
    }
    
    private func listRow(product: Product) -> some View {
        HStack {
            Image60(theUrl: product.imageUrl.first ?? "")

            VStack(alignment: .leading) {
                Text(product.name)
                    .font(.headline)
                Spacer()
                HStack {
                    Text("$\(product.price)")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Qty：\(product.quantity)")
                        .font(.footnote)
                }
            }
            .frame(height: 60)
        }
    }
    
    private var bottomView: some View {
        VStack(spacing: 28) {
            
// MARK: -  Two button to select
            
            VStack(spacing: 0) {
                
// MARK: Shipping Info
                Button {
                    withAnimation {
                        isShowShoppingSheet = true
                    }
                } label: {
                    lineLabel(content:
                        HStack {
                            Text("Shipping Info")
                            Spacer()
                            if let selected = shippingVM.shippings.first(where: { $0.id == shippingId }) {
                                Text(selected.shippingMethod).fontWeight(.semibold)
                                Text("$\(selected.ShippingFee)").fontWeight(.semibold)
                            }else {
                                Text("Not Selected").foregroundStyle(.secondary)
                            }
                        }
                        .lineLimit(1)
                    )
                }
                
// MARK: Coupon
                Button {
                    withAnimation {
                        isShowConstSheet = true
                    }
                } label: {
                    lineLabel(content:
                        HStack {
                            Text("Coupon")
                            Spacer()
                            if let selected = couponVM.coupons.first(where: { $0.id == couponId }) {
                                Text(selected.code).fontWeight(.semibold)
                                Text("- $\(selected.discount)").fontWeight(.semibold)
                            }else {
                                Text("Not Selected").foregroundStyle(.secondary)
                            }
                        }
                        .lineLimit(1)
                    )
                }
            }
            
 // MARK: -  Total line
            
            Text("Total：$\(totalPrice)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
// MARK: -  bottom tool
            
            HStack {
                Button("Back to Cart") {
                    router.pop()
                    shippingId = ""
                    couponId = ""
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                PrimaryFilledButton(title: "Place Order"){
                    guard !shippingId.isEmpty else  {
                        isShowAlert = true
                        return
                    }
                    Task {
                        // 1. 將目前結帳資訊組成訂單
                        vm.newOrderRequest = OrderRequest(
                            products: data.products,
                            couponId: couponId,
                            shippingId: shippingId
                        )

                        // 2. 呼叫送出訂單 API
                        await vm.addOrder()

                        // 3. 切換頁面跳轉
                        router.setRoot(to: "orders")
                    }
                }
                .frame(width: 150)
            }
        }
        .padding(.horizontal)
    }

// MARK: - style FOR Two button to select
    
    private func lineLabel<Content: View>(content: Content) -> some View {
        VStack(spacing: 0) {
            content
                .padding(.vertical, 16)
            Divider()
        }
    }

}

// #Preview

#Preview {
    CheckoutView(data: .sample)
        .environmentObject(AuthViewModel.preview())
        .environmentObject(ShippingViewModel())
        .environmentObject(CouponViewModel())
}


extension Product {
    static let sample: Product = Product(
        id: "p1",
        productId: "123",
        name: "iPhone 15",
        imageUrl: ["https://i.pinimg.com/736x/cc/40/23/cc4023447a65596c3b0f05329c5acdec.jpg"],
        price: 100,
        quantity: 2
    )
}

extension CheckoutData {
    static let sample: CheckoutData = CheckoutData(
        products: [Product.sample],
        totalPrice: Product.sample.price * Product.sample.quantity
    )
}

