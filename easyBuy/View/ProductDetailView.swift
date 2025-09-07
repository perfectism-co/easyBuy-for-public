//
//  ProductDetailView.swift
//  easyBuy
//
//  
//

import SwiftUI
import SwiftfulUI


struct ProductDetailView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var router: PageRouter
    
    let product: OpenProduct
    let size: [String] = ["S", "M", "L", "XL"]
    @State private var selectedSize: String = "S"
    @State private var neededProductQuantity: Int = 1
    
   
    @State private var isShowAddToCartSheet = false
    @State private var isShowAlbumSheet: Bool = false
    @State private var isShowToast = false
    @State private var isShowHeaderBG = false
    //    @State private var offset: CGFloat = 0
    
    @State private var ImageCarouselCurrentIndex: Int = 0
    
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            ScrollView(.vertical, showsIndicators: false) {
                topImageCarousel
                    .readingFrame { frame in
                        // offset = frame.maxY
                        isShowHeaderBG = frame.maxY < 260
                    }
                content
                VStack{}.frame(height: 30)
            }
            .padding()
            .offset(y: -20)
            
            bottomBar
           
            headerView
                .offset(y: -20)
           
            if isShowToast {
                Toast(text: "Add to cart success.", showToast: $isShowToast)
            }
            
            //            Text("\(offset)").background(Color.red)
            
            ZStack {
                if isShowAlbumSheet {
                    ProductImageCarousel(product: product, isShowImageCount: ImageCarouselCurrentIndex, isPresented: $isShowAlbumSheet)
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                }
            }.animation(.easeInOut(duration: 0.3), value: isShowAlbumSheet)
            
        }
        
        .navigationBarHidden(true)
        // 加上自訂 Sheet Modifier
        .bottomSheet(isPresented: $isShowAddToCartSheet, height: 300) {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Image60(theUrl: product.imageUrl.first ?? "")                    
                    VStack (alignment: .leading){
                        Text(product.name)
                        Spacer()
                        Text("$\(product.price)")
                            .fontWeight(.semibold)
                    }
                    .frame(height: 60)
                }
                
                HStack(spacing: 24) {
                    ForEach(size, id: \.self) { size in
                        CellTab(text: size, notSelectedColor: Color.bg, selected: $selectedSize)
                    }
                }
                .padding(.bottom, 24)
                HStack{
                    Stepper(value: $neededProductQuantity, in: 1...100) {
                        Text("數量：\(neededProductQuantity)")
                    }
                    .frame(width: 200)
                    Spacer()
                    PrimaryFilledButton(title: "Add to cart") {
                        let cartItem = CartItem(productId: product.id, quantity: neededProductQuantity)
                        let cartRequest = CartRequest(products: [cartItem])
                        
                        Task {
                            await vm.addCart(products: cartRequest)
                            await vm.fetchUser()
                        }
                        
                        withAnimation {
                            isShowAddToCartSheet = false
                            isShowToast = true //顯示提示
                            
                            // 自動延遲 3 秒關閉
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation {
                                    isShowToast = false
                                }
                            }
                        }
                    }
                    .frame(width: 150)
                }
            }
        }
    }
    
    private var topImageCarousel: some View {
        ZStack(alignment: .bottom) {
            ImageCarousel(imageUrls: product.imageUrl, currentIndex: $ImageCarouselCurrentIndex)
                .frame(height: 350)
                .onTapGesture {
                    withAnimation {
                        isShowAlbumSheet = true
                    }
                }
            if product.imageUrl.count != 1 {
                Rectangle() //暗底漸層
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.2)]),
                            startPoint: .top,
                            endPoint: .bottom
                       )
                    )
                    .frame(maxWidth: .infinity, maxHeight: 80)
            
                PageControl(numberOfPages: product.imageUrl.count, currentPage: $ImageCarouselCurrentIndex)
                    .padding(8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(product.name)
                .font(.title2)
                .fontWeight(.semibold)
            HStack {
                Text("$\(product.price)")
                    .font(.system(size: 24))
                    .fontWeight(.semibold)
                Spacer()
                Text("★")
                    .foregroundColor(Color.yellow)
                Text("\(product.rating, specifier: "%.1f")")
                    .foregroundColor(Color.gray)
            }
            
            Text("Description")
                .font(.headline)
            Text("Step up your daily commute with our fashion-forward commuter wear – where comfort meets confidence. Designed for the hustle of city life, this stylish outfit blends breathable fabrics with bold, eye-catching details that turn sidewalks into runways. Whether you're hopping on a train or grabbing coffee on the go, you’ll stay fresh, flexible, and effortlessly cool.Perfect for trendsetters who believe that every journey deserves a great outfit.")
                .foregroundColor(Color.gray)

            ImagerFit(theUrl: "https://i.pinimg.com/1200x/e3/ba/02/e3ba02b01e69b42efcdbc1b833b4684c.jpg")
            ImagerFit(theUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQYKu_FTgtpJ_TFDJ4yFEgCQsgZgwvWcT9ovQ&s")
        }
    }
    
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 12) {
                PrimaryFilledButton(title: "♥︎ Wishlist"){}
                    .tint(.purple)
                PrimaryFilledButton(title: "Add to cart"){
                    withAnimation {
                        isShowAddToCartSheet = true
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .background(Color.white)
        }
    }
    
    private var headerView: some View {
        VStack {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        router.popNoReset()
                    }label: {
                        Image(systemName: isShowHeaderBG ? "chevron.backward" : "arrow.backward")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundColor(isShowHeaderBG ? .accentColor : .white)
                            .frame(width: 40, height: 40)
                            .background(isShowHeaderBG ? Color.clear : Color.black.opacity(0.2))
                            .clipShape(Circle())
                        
                    }
                    Spacer()
                    
                    if isShowHeaderBG {
                        Text("Product Detail")
                            .font(.headline)
                    }
                    
                    Spacer()
                    Button {
                        //                    router.push(.cart(showBackButton: true))
                        router.switchTab(to: "cart")
                    }label: {
                        ZStack{
                            HStack{}
                                .frame(width: 40, height: 40)
                                .background(isShowHeaderBG ? Color.clear : Color.black.opacity(0.2))
                                .clipShape(Circle())
                            HStack {
                                Image(systemName: "cart")
                                    .font(.system(size: 16, weight: .bold, design: .default))
                                    .foregroundColor(isShowHeaderBG ? .accentColor : .white)
                                    .iconCount(vm.user?.cart.count ?? 0)
                            }.frame(width: 40, height: 40)
                        }
                    }
                }
                .frame(height: 40)
                .padding()
                .background(isShowHeaderBG ? Color.white : Color.clear)
                if isShowHeaderBG {
                    Divider()
                }
            }
            Spacer()
        }
        .animation(.smooth(duration: 0.5), value: isShowHeaderBG)
    }
}




#Preview {
    
  ProductDetailView(product: .sample)    
    .environmentObject(AuthViewModel.preview())
    .environmentObject(ShippingViewModel())
    .environmentObject(CouponViewModel())
    .environmentObject(PageRouter())
}




//canva預覽試用
extension OpenProduct {
    static let sample = OpenProduct(
        id: "123",
        name: "Classic City Ringer T-Shirt Light Beige color 100% Cotton",
        category: "T-shirt",
        imageUrl: ["https://i.pinimg.com/1200x/b9/f7/f6/b9f7f67c30d85a24a5c092ddac3e6fd6.jpg","https://i.pinimg.com/1200x/d3/e4/21/d3e42186adb4e81adb8b2eb1c1427ca0.jpg", "https://i.pinimg.com/1200x/c2/97/47/c29747091dddc05f6a7d3d35f413aff2.jpg","https://i.pinimg.com/736x/69/df/de/69dfde7d5db7731bccb3572fd815e9b0.jpg", "https://i.pinimg.com/1200x/75/19/b3/7519b34c120cbaaafe80fec8961b8c52.jpg"],
        price: 500,
        rating: 4.5
    )
}




