//
//  MyOrdersView.swift
//  easyBuy
//
// 
//

import SwiftUI

struct MyOrdersView: View {
    @EnvironmentObject var vm: AuthViewModel
    
    var body: some View {
        ZStack {
            Color.bg.edgesIgnoringSafeArea(.all)
            VStack{
                if vm.user?.orders.isEmpty == false {
                    ScrollView(.vertical, showsIndicators: false) {
                        HStack { }.frame(height: 48)
                        LazyVStack(spacing: 20) {
                            ForEach(vm.user?.orders ?? []) { order in
                                OrderRow(order: order)
                            }
                        }
                        VStack{}.frame(height: 60)
                    }
                }else {
                    Text("No orders yet")
                        .foregroundColor(Color.gray)
                }
            }
            .padding(.horizontal, 16)

            HeaderView(text: "My Orders", bgColor: .bg){
                Button{
                    Task { await vm.logout() }
                }label: {
                    Image(systemName: "iphone.and.arrow.right.outward").tint(.primary)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                 await vm.fetchUser()
            }
        }
    }
}

// MARK: - 子元件：OrderRow

struct OrderRow: View {
    @EnvironmentObject var router: PageRouter
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Order ID: \(order.id)")
                    .font(.footnote)
                    
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.gray)

            ForEach(order.products, id: \.productId) { product in
                ProductRow(product: product)
            }
            HStack {
                Spacer()
                Text("Total: $ \(order.totalAmount)")
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(12)
        .onTapGesture {
            router.push(.orderDetail(order: order))
        }
    }
}

// MARK: - 子元件：ProductRow

struct ProductRow: View {
    let product: Product

    var body: some View {
        VStack {
            HStack (spacing: 16){
                Image60(theUrl: product.imageUrl.first ?? "")
                
                VStack(alignment: .leading) {
                    Text("Product ID: \(product.productId)")
                        .font(.caption2)
                        .foregroundColor(Color.gray)
                    HStack {
                        Text(product.name)
                            .lineLimit(1)
                        Spacer()
                        Text("x \(product.quantity)")
                    }
                    
                    HStack {
                        Text("$ \(product.price)")
                        Spacer()
                        Text("Subtotal: $ \(product.price * (product.quantity))").font(.footnote).foregroundColor(.gray)
                    }
                }
            }
        }        
    }
}



#Preview {
 
   MyOrdersView()
        .environmentObject(AuthViewModel.preview())
        .environmentObject(ShippingViewModel())
        .environmentObject(CouponViewModel())
}


