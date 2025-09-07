//
//  OrderDetailView.swift
//  easyBuy
//
// 
//

import SwiftUI

struct OrderDetailView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var router: PageRouter
   
    @State private var refreshID = UUID()

    let order: Order
    var urls: [String] {order.review.imageUrls}
    
    
    // 用@State 即時刷新
    @State private var theOrder: Order
    init(order: Order) {
       self.order = order
       _theOrder = State(initialValue: order)
    }
    
    var body: some View {
        ZStack {
            Color.bg.edgesIgnoringSafeArea(.all)
            ScrollView(.vertical, showsIndicators: false){
                HStack { }.frame(height: 48)
                
                Group{
                    orderFrame()
                    reviewFrame()
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(12)
                
                VStack{}.frame(height: 60)
            }
            .padding(.horizontal)

            HeaderView(text: "Order Detail", bgColor: .bg, showBackButton: true)
        }
        .navigationBarHidden(true)
        .id(refreshID) // ✅ 每次 refreshID 改變時，SwiftUI 會重新構建整個 View
        .onAppear {
            Task {
                await vm.fetchUser()
                
                // 根據 ID 找出最新訂單資料
                if let updated = vm.user?.orders.first(where: { $0.id == order.id }) {
                    theOrder = updated // ✅ 更新畫面用的訂單資料
                    refreshID = UUID() // ✅ 讓 View 強制刷新
                }
            }
        }
    }
    
    func orderFrame() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Order ID: \(theOrder.id)")
                .font(.callout)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(theOrder.products, id: \.productId) { product in
                ProductRow(product: product)
            }
           
            HStack {
                Text("Shipping: \(theOrder.shippingMethod)")
                    .lineLimit(1)
                Spacer()
                Text("$ \(theOrder.shippingFee)")
            }
            
            if let coupon = theOrder.coupon, !coupon.isEmpty {
                HStack {
                    Text("Coupon: \(coupon.code ?? "")")
                        .lineLimit(1)
                    Spacer()
                    Text("-$ \(coupon.discount ?? 0)")
                }
            }
            
            HStack {
                Text("Date: \(theOrder.createdAt.orderFormattedTime)")
                Spacer()
                Text("Total: $\(theOrder.totalAmount)").fontWeight(.bold)
            }
            HStack {
                SecondaryFilledButton(title: "Update Order"){
                    router.push(.orderEditting(order: theOrder))
                }
                Spacer(minLength: 20)
                SecondaryFilledButton(title: "Cancel Order"){
                    Task {
                        await vm.deleteOrder(order: theOrder)
                        router.pop() // 等 delete 完成後才 pop，這樣 onAppear 才能生效
                    }
                }
            }
            .font(.footnote)
            .padding(.top)
        }
        .font(.callout)
    }
    
    func reviewFrame() -> some View {
        VStack {
            if theOrder.review.isEmpty {
                PrimaryFilledButton(title: "Add Review") {
                    router.push(.reviewUpload(orderId: theOrder.id))
                }
            }else {
                VStack(alignment: .leading, spacing: 20) {
                    Text("My Review").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                    HStack {
                        Text("⭐️ Rating：")
                        StarRatingView(rating: theOrder.review.rating ?? 0, starSize: 20)
                        Text("\(theOrder.review.rating ?? 0)")
                    }
                    
                    if !(theOrder.review.comment ?? "").isEmpty {
                        Text("📝 Review：\(theOrder.review.comment ?? "")")
                    }
                    
                    if !theOrder.review.imageUrls.isEmpty {
                        HStack {
                            ForEach(theOrder.review.imageUrls, id: \.self) { urlStr in
                                if let url = URL(string: urlStr) {
                                    AuthenticatedImageView(url: url)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    Button("Delete Review") {
                        Task{
                            await vm.deleteReview(order: theOrder)
                            await vm.fetchUser()
                            // 根據 ID 找出最新訂單資料
                            if let updated = vm.user?.orders.first(where: { $0.id == order.id }) {
                                theOrder = updated // ✅ 更新畫面用的訂單資料
                                refreshID = UUID() // ✅ 讓 View 強制刷新
                            }
                            
                        }
                    }.foregroundColor(.red)
                }
            }
        }
        .font(.callout)
    }
}



#Preview {
    let previewVM = AuthViewModel.preview()
    if let order = previewVM.user?.orders.first {
        OrderDetailView(order: order)
            .environmentObject(AuthViewModel.preview())
            .environmentObject(ShippingViewModel())
            .environmentObject(CouponViewModel())
    }
}



struct AuthenticatedImageView: View {
    let url: URL
    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
            } else {
                Color.gray
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            Task {
                isLoading = true
                self.image = await APIService.shared.fetchImageWithAuth(from: url)
                isLoading = false
            }
        }
    }
}



extension DateFormatter {
    static let oderDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy HH:mm"
        formatter.locale = Locale(identifier: "zh_TW") // ← 可選：中文顯示
        formatter.timeZone = TimeZone.current           // ← 根據裝置顯示當地時間
        return formatter
    }()
}

extension Date {
    var orderFormattedTime: String {
        return DateFormatter.oderDateTimeFormatter.string(from: self)
    }
}
