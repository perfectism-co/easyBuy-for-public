//
//  HomeView.swift
//  easyBuy
//
//  
//

import SwiftUI


struct HomeView: View {
    @EnvironmentObject var vmPd: ProductViewModel
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var router: PageRouter
    @State private var currentIndex: Int = 0
    
    @State private var selectedCategory: String = "All"
    
    @State private var searchText = ""
    @State private var isShowFilter: Bool = false // 篩選商品(價格、評分...)
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 9999
    @State private var minRating: Double = 0
    
    @State private var theMinPrice: Double = 0
    @State private var theMaxPrice: Double = 9999
    @State private var theMinRating: Double = 0
    
    @FocusState private var isFocused: Bool

    @State private var offsetY: CGFloat = 0  // 初始在畫面上方
    @State private var opacity: Double = 0
    
    
    @State private var selectedPageIndex = 0
    
    // 用字典記錄每頁要滾動的目標ID（這裡固定用0代表頂部）
    @State private var scrollToIds: [Int: Int?] = [:] // [page : id]
    
    
    let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    
    var categories: [String] {
            // 「All」放最前面，其餘分類照字母排序
            ["All"] + vmPd.categorizedProducts.keys.sorted()
        }

    var filteredProducts: [OpenProduct] {
        // 1. 根據分類顯示
       let products = selectedCategory == "All"
           ? vmPd.products
           : vmPd.categorizedProducts[selectedCategory] ?? []

       // 2. 根據搜尋文字、價格區間、評分條件進行篩選
       return products.filter {
           // 如果沒輸入搜尋文字，則通過；否則需符合名稱關鍵字
           (searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)) &&
           // 價格條件
           Double($0.price) >= theMinPrice &&
           Double($0.price) <= theMaxPrice &&
           // 評分條件
           $0.rating >= theMinRating
       }
    }
    
    
    func filteredProducts1(for category: String) -> [OpenProduct] {
        // 1. 先根據傳入的分類決定初始產品集
        let products = category == "All"
            ? vmPd.products
            : vmPd.categorizedProducts[category] ?? []
        
        // 2. 再依搜尋、價格、評分條件過濾
        return products.filter {
            (searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)) &&
            Double($0.price) >= theMinPrice &&
            Double($0.price) <= theMaxPrice &&
            $0.rating >= theMinRating
        }
    }


    
    var body: some View {
        GeometryReader { geometry in  //偵測螢幕寬度
            ZStack {
                Color.bg.edgesIgnoringSafeArea(.all)
                if vmPd.isLoading {
                    ProgressView("Loading...")
                } else {
                   
                    // 👉 商品
                    if filteredProducts.isEmpty {
                        Spacer()
                        Text("⚠️ 找不到符合條件的商品")
                            .foregroundColor(.gray)
                            .padding()
                        Spacer()
                    } else {
                        ScrollViewReader { proxy in  // Filter reset\done buttom 點擊回頂部
                                TabViewContent(geometry: geometry, proxy: proxy)
                           
                        }
                   }
                }
                
                // 👉 分類列（可滑動）
                VStack(spacing: 0){
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(categories.indices, id: \.self) { index in
                                CellTab(text: categories[index], selected: $selectedCategory) {
                                    withAnimation {
                                        selectedPageIndex = index
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.bg)
                    Spacer()
                }
                .offset(y: 40)
                
                
                // 👉 Filter content
                if isShowFilter {
                    VStack{
                        FilterContent()
                        Spacer()
                    }
                    .zIndex(1)
                    .transition(
                        .asymmetric(
                            // 出現：從 y = -Screenheight 滑到 y = 22 並淡入
                            insertion: AnyTransition.modifier(
                                active: OffsetOpacityModifier(offsetY: -UIScreen.main.bounds.height, opacity: 0),
                                identity: OffsetOpacityModifier(offsetY: 22, opacity: 1)
                            ),
                            // 消失：從 y = 22 滑回 y = -Screenheight 並淡出
                            removal: AnyTransition.modifier(
                                active: OffsetOpacityModifier(offsetY: -UIScreen.main.bounds.height, opacity: 0),
                                identity: OffsetOpacityModifier(offsetY: 22, opacity: 1)
                            )
                        )
                    )
                }
                
                // 👉 SearchBar line
                VStack {
                    HStack {
                        SearchBarView(text: $searchText){
                            scrollToIds[selectedPageIndex] = 0
                        }
                        IconFilledButton(iconName: "slider.horizontal.3",height: 24) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowFilter.toggle()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .background(Color.bg)
                    Spacer()
                }
                .zIndex(2)                                  
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await vmPd.fetchProducts()
            }
        }
            
    }
    private struct ProductItem: View {
        let product: OpenProduct
        let geometry: GeometryProxy
        var body: some View {
            VStack{
                ImagerFill(theUrl: product.imageUrl.first ?? "", width: geometry.size.width * 0.45, height: 200)
                
                VStack(alignment: .leading) {
                    Text(product.name)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    HStack {
                        Text("$\(product.price)")
                            .fontWeight(.bold)
                        Spacer()
                        Text("★")
                            .foregroundColor(Color.yellow)
                        Text("\(product.rating, specifier: "%.1f")")
                            .foregroundColor(Color.gray)
                        
                    }
                }
                .padding(.bottom, 12)
                .padding(.horizontal, 8)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func TabViewContent(geometry: GeometryProxy, proxy: ScrollViewProxy) -> some View {
   
        TabPagingView(selectedPage: $selectedPageIndex, pageCount: categories.count) { index in
            
            ScrollView(.vertical, showsIndicators: false) {
               // 👉 AD
                ImageCarouselSwiftUI(imageUrls: ["AD1", "AD2", "AD3"], currentIndex: $currentIndex, autoScroll: true, interval: 1.0, height: 140, cornerRadius: 8)
                    .padding(.horizontal)
                
                // 最上方加上一個 id = 0 的空白 View，用 id(0) 作為回頂部目標，方便滾動回頂部
                Color.clear
                    .frame(height: 0)
                    .id(0)
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredProducts1(for: categories[index])) { product in
                        ProductItem(product: product, geometry: geometry)
                            .onTapGesture {
                                router.push(.productDetail(product: product))
                            }
                    }
                }
                .padding(.horizontal)
                
                VStack{}.frame(height: 200)
            }
            .onChange(of: scrollToIds[index] ?? nil) { targetId in // 記錄當前是哪一頁，給回上方用
                guard let targetId = targetId else { return }
                proxy.scrollTo(targetId, anchor: .top)
                // 滾動完重置狀態，避免重複觸發
                scrollToIds[index] = nil
            }
            .onChange(of: selectedPageIndex) { newIndex in
                selectedCategory = categories[newIndex] // ✅ 滑動時同步分類
            }
        }
        .offset(y: 110)
    }
        
    
    private func FilterContent() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            
            Text("Price Range")
            HStack {
                NumberField(placeholder: "Min Price", number: $minPrice)
                Text("~")
                NumberField(placeholder: "Max Price", number: $maxPrice)
            }
            .padding(.vertical, 8)
            RangeSlider(
                minValue: $minPrice,
                maxValue: $maxPrice,
                range: 0...9999,
                step: 50
            )

            Divider().padding(.vertical)


            HStack {
               Text("Min Rating")
               Spacer()
               Text("⭐️ \(String(format: "%.1f", minRating))")
            }
            SingleSlider(value: $minRating, range: 0...5, step: 0.5)


            HStack(spacing: 30) {
                SecondaryFilledButton(title: "Reset") {
                    minPrice = 0
                    maxPrice = 9999
                    minRating = 0
                    theMinPrice = 0
                    theMaxPrice = 9999
                    theMinRating = 0
                    // 設定目前分頁的滾動目標為0
                    scrollToIds[selectedPageIndex] = 0
                    withAnimation {
                        isShowFilter = false
                    }
                }
                
                PrimaryFilledButton(title: "Apply") {
                    theMinPrice = minPrice
                    theMaxPrice = maxPrice
                    theMinRating = minRating
                    // 設定目前分頁的滾動目標為0
                    scrollToIds[selectedPageIndex] = 0
                    withAnimation {
                        isShowFilter = false
                    }
                }
            }
            .padding(.top, 24)
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(28)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.16), radius: 16, y: 2)
        )
    }
}






struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Search for fashion items"
    // 新增一個 onSubmitAction 參數，預設空動作
    var onSubmitAction: () -> Void = {}

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(placeholder, text: $text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onSubmit {
                    print("使用者按下了 Enter！輸入文字：\(text)")
                    onSubmitAction()
                }
            
            Image(systemName: "camera")
                .foregroundColor(.gray)

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.white))
        .cornerRadius(10)
        
    }
}

/// 自訂過渡動畫修飾器 Filter content用
struct OffsetOpacityModifier: ViewModifier {
    var offsetY: CGFloat
    var opacity: Double
    
    func body(content: Content) -> some View {
        content
            .offset(y: offsetY)
            .opacity(opacity)
    }
}



#Preview {
    HomeView()
        .environmentObject(AuthViewModel.preview())
        .environmentObject(ShippingViewModel())
        .environmentObject(CouponViewModel())
        .environmentObject(ProductViewModel())
}
