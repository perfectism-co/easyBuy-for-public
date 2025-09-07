//
//  CartView.swift
//  easyBuy
//
//  
//

import SwiftUI


struct CheckoutData: Equatable {
    let products: [Product]
    let totalPrice: Int
}


struct CartView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var router: PageRouter
    @EnvironmentObject private var keyboard: KeyboardObserver

    @State private var selections: [String: Bool] = [:]
    @State private var isShowAlert: Bool = false
    
    @Binding var showBackButton: Bool
    
    
    private var selectedProductIDs: [String] {
        selections.filter { $0.value }.map { $0.key }
    }
    
    // 計算已選商品總金額
    private var selectedTotalPrice: Int {
        guard let cart = vm.user?.cart else { return 0 }
        return cart
            .filter { selectedProductIDs.contains($0.productId) }
            .map { $0.price * $0.quantity }
            .reduce(0, +)
    }
    
    // 建立變數類，並存放值進去~(vm.user?.cart)整個陣列
    private var selectedCheckoutData: CheckoutData {
        let selected = vm.user?.cart.filter { selectedProductIDs.contains($0.productId) } ?? []
        let total = selectedTotalPrice /*selected.map { $0.price * $0.quantity }.reduce(0, +)*/
        return CheckoutData(products: selected, totalPrice: total)
    }
   

    var body: some View {
        ZStack{
            Color.bg.edgesIgnoringSafeArea(.all)
            VStack {
                if let cart = vm.user?.cart, !cart.isEmpty {
                    HStack { }.frame(height: 10)
                    List {
                        ForEach(cart) { product in
                            listRow(product: product)
                        }
                        .onDelete { indexSet in //滑動刪除
                            Task {
                                // 取得要刪除的產品
                                let productIdsToDelete = indexSet.map { cart[$0].productId }

                                // 呼叫刪除 API
                                await vm.deleteCartItems(productIds: productIdsToDelete)

                                // 清除勾選狀態（從陣列中移除）
                                for id in productIdsToDelete {
                                    selections.removeValue(forKey: id)
                                }
                                
                                // 重新抓取購物車資料
                                await vm.fetchUser()
                            }
                        }
                    }

                    // 顯示已選商品總金額與全選按鈕
                    if !keyboard.isKeyboardVisible{
                        bottomToolbar(products: cart)
                    }
                    
                } else {
                    Text("Your cart is empty")
                        .foregroundColor(Color.gray)
                }
            }
            .onAppear {
                Task {
                    await vm.fetchUser()
                }
            }
            
            HeaderView(text: "Cart", bgColor: .bg, showBackButton: showBackButton){
                if let cart = vm.user?.cart, !cart.isEmpty {
                    Button{
                        Task {
                            await vm.deleteCartItems(productIds: selectedProductIDs)
                            for id in selectedProductIDs {
                                selections.removeValue(forKey: id)
                            }
                            await vm.fetchUser()
                        }
                    }label: {
                        Image(systemName: "trash").tint(.primary)
                    }
                }
            }
                
        }
        .navigationBarHidden(true)
        .alert(isPresented: $isShowAlert) {
            Alert(
                title: Text(""),
                message: Text("Please select a product."),
                dismissButton: .default(Text("OK"), action: {isShowAlert = false})
            )
        }
    }
    
    private func listRow(product: Product) -> some View {
        HStack {
            CheckBox(item: product.productId, selections: $selections) { newVal in
                print("\(product.productId) 變更：\(newVal)")
                //selectedProductIDs = selections.filter { $0.value }.map { $0.key }
            }
            HStack {
                Image60(theUrl: product.imageUrl.first ?? "")

                VStack(alignment: .leading) {
                    Text(product.name)
                    HStack {
                        Text("$\(product.price)")
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                            .lineLimit(1)
                        Spacer()
                        CustomStepper(
                            range: 1...99,
                            value: Binding(
                                get: { product.quantity },
                                set: { newQty in
                                    print("Stepper set 被呼叫，newQty: \(newQty)")
                                    
                                    if let index = vm.user?.cart.firstIndex(where: { $0.id == product.id }) {
                                        vm.user?.cart[index].quantity = newQty
                                    }
                                    
                                    Task {
                                        await vm.updateCartItem(productId: product.productId, quantity: newQty)
                                    }
                                }
                            )
                        )
                    }
                }
            }
        }
    }
    
    private func bottomToolbar(products: [Product]) -> some View {
        VStack{
            HStack (spacing: 20){
                VStack(alignment: .leading, spacing: 10) {
                    Button(selections.isEmpty || selections.values.contains(false) ? "Select All" : "Deselect All") {
                        let selectAll = selections.isEmpty || selections.values.contains(false)  //Bool
                        for product in products {
                            selections[product.productId] = selectAll
                        }
                    }
                    .foregroundColor(Color.blue)
                   
                    HStack {
                        Text("Total Selected：")
                            .foregroundColor(Color.gray)
                        Text("$\(selectedTotalPrice)")
                            .font(.headline)
                            .foregroundColor(Color.accentColor)
                    }
                }
                Spacer()
                PrimaryFilledButton(title: "Checkout") {
                    guard !selectedCheckoutData.products.isEmpty else  {
                        isShowAlert = true
                        return
                    }
                    router.push(.checkout(data: selectedCheckoutData))
                }
                .frame(width: 130)
            }
            .padding()
            VStack{}.frame(height: 50)
        }
        .background(Color.white)
    }
}


#Preview {
    
  CartView(showBackButton: .constant(false))
    .environmentObject(AuthViewModel.preview())
    .environmentObject(ShippingViewModel())
    .environmentObject(CouponViewModel())
    .environmentObject(KeyboardObserver())
}

//預覽試用
extension AuthViewModel {
    static func preview() -> AuthViewModel {
        let vm = AuthViewModel()
        
        // 假商品資料
        let product1 = Product(
            id: "1",
            productId: "A001",
            name: "假商品1",
            imageUrl: ["https://m.media-amazon.com/images/I/61s2-ts3f3L._AC_SY741_.jpg"],
            price: 199,
            quantity: 1
        )
        
        let product2 = Product(
            id: "2",
            productId: "A002",
            name: "假商品2",
            imageUrl: ["https://i.pinimg.com/736x/cc/40/23/cc4023447a65596c3b0f05329c5acdec.jpg"],
            price: 299,
            quantity: 2
        )
        
        // 假訂單資料
        let order1 = Order(
            id: "order001",
            products: [product1, product2],
            shippingMethod: "宅配",
            createdAt: Date(),
            totalAmount: 697, // 199 + 299*2
            shippingFee: 100,
            coupon: Coupon(code: "DISCOUNT100", discount: 100),
            review: Review(comment: "商品很好", rating: 5, imageUrls: [
                "https://via.placeholder.com/100",
                "https://via.placeholder.com/100"
            ])
        )
        
        let order2 = Order(
            id: "order002",
            products: [product1],
            shippingMethod: "超商取貨",
            createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            totalAmount: 199,
            shippingFee: 60,
            coupon: nil,
            review: Review(comment: "普通，尚可接受", rating: 3, imageUrls: [])
        )
        
        vm.user = User(
            id: "user123",
            email: "test@example.com",
            orders: [order1, order2],
            cart: [product1, product2]
        )
        
        return vm
    }
}

