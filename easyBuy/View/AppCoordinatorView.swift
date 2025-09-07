import SwiftUI

struct PageItem: Identifiable, Equatable {
    var id: UUID = UUID()         // ✅ 控制 View 是否重建
    var page: AppPage

    static func == (lhs: PageItem, rhs: PageItem) -> Bool {
        lhs.page == rhs.page
    }
}


enum AppPage: Equatable {
    case home
    case productDetail(product: OpenProduct)
    case cart(showBackButton: Bool)
    case checkout(data: CheckoutData)
    case myOrders
    case orderDetail(order: Order)
    case orderEditting(order: Order)
    case reviewUpload(orderId: String)
}

extension AppPage {
    var isTabBarHide: Bool {
        switch self {
        case .productDetail, .checkout, .orderEditting:
            return true  // 這些頁面隱藏 TabBar
        default:
            return false // 其他頁面顯示 TabBar
        }
    }
}



class PageRouter: ObservableObject {
    // 用 key（比如 Tab 名稱）管理多個獨立的導航堆疊
    @Published var stacks: [String: [PageItem]] = [
        "home": [PageItem(page: .home)],
        "cart": [PageItem(page: .cart(showBackButton: false))],
        "orders": [PageItem(page: .myOrders)]
    ]
    
    // 紀錄當前顯示的路徑（Tab）
    @Published var currentTab: String = "home"
    
    // 用來判斷動畫方向（true: pop，false: push，nil: 無動畫）
    @Published var isPopping: Bool? = nil
    
    // TabBar 隱藏控制
    @Published var hideTabBar: Bool = false
    
    // 取得目前 Tab 的導航堆疊（防止空值）
    var currentStack: [PageItem] {
        stacks[currentTab] ?? []
    }
    
    var allTabs: [String] {
           Array(stacks.keys)
       }
    
    // MARK: - 導航操作
    
    func push(_ page: AppPage) {
        isPopping = false
        withAnimation(.easeInOut(duration: 0.25)) {
            stacks[currentTab, default: []].append(PageItem(page: page))
        }
    }
    
    func present(_ page: AppPage) {
        isPopping = nil
        withAnimation {
            stacks[currentTab, default: []].append(PageItem(page: page))
        }
    }

    func pop() {
        guard var stack = stacks[currentTab], stack.count > 1 else { return }
        isPopping = true // 表示返回上一頁

        withAnimation(.easeInOut(duration: 0.25)) {
            // 移除頂層頁面
            _ = stack.popLast()

            // 直接改最後一個元素的 id，強制刷新
            if var previous = stack.last {
                previous.id = UUID()
                stack[stack.count - 1] = previous
            }

            stacks[currentTab] = stack
        }
    }

    
    func popNoReset() {
        guard var stack = stacks[currentTab], stack.count > 1 else { return }
        isPopping = true
        withAnimation(.easeInOut(duration: 0.25)) {
            _ = stack.popLast()
            stacks[currentTab] = stack
        }
    }
    
    func hidePresentNoReset() {
        guard var stack = stacks[currentTab], stack.count > 1 else { return }
        _ = stack.popLast()
        stacks[currentTab] = stack
    }
    
    func popToRoot() {
        guard let first = stacks[currentTab]?.first else { return }
        isPopping = true
        withAnimation {
            stacks[currentTab] = [first]
        }
    }
    
    func setRootNoAnimation(to page: AppPage) {
        let t = Transaction(animation: nil)
        withTransaction(t) {
            isPopping = nil
            stacks[currentTab] = [PageItem(page: page)]
        }
    }
    
    
    func setRoot(to newTab: String) {
        let oldTab = currentTab
        
        // 刷新舊 tab 的根頁
        if let oldRoot = stacks[oldTab]?.first {
            let refreshedOldRoot = PageItem(id: UUID(), page: oldRoot.page)
            stacks[oldTab] = [refreshedOldRoot]
        }
        
        // 切換到新 tab
        currentTab = newTab
        
        // 刷新新 tab 的根頁
        if let newRoot = stacks[newTab]?.first {
            let refreshedNewRoot = PageItem(id: UUID(), page: newRoot.page)
            stacks[newTab] = [refreshedNewRoot]
        }
    }

    
    // 切換 Tab，保持各 Tab 獨立導航狀態
    func switchTab(to tabKey: String) {
        currentTab = tabKey
    }
    
    // 目前頁面（當前 Tab 最上層頁面）
    var current: AppPage {
        stacks[currentTab]?.last?.page ?? .home
    }
}



extension AnyTransition {
    static var slideLeft: AnyTransition {
        .asymmetric( //不對稱--> 分別指定不同的動畫
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
    }

    static var slideRight: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .trailing)
        )
    }
}

struct AppCoordinatorView: View {
    @EnvironmentObject var router: PageRouter
    @GestureState private var dragOffset: CGFloat = 0
    @State private var currentStackVersion: Int = 0
    
    let tabKey: String

    var body: some View {
        ZStack {
            ForEach(router.stacks[tabKey] ?? []) { item in
                viewFor(item.page)
                    .id(item.id) // ✅ 手動強制刷新(回上一頁可手動刷新）
                    .zIndex(Double(router.stacks[tabKey]?.firstIndex(of: item) ?? 0)) //.zIndex 在 單一 tab 的多頁面切換中控制 push/pop 前後層。
                    .transition(
                        router.isPopping == nil
                            ? .opacity        // 淡入淡出
                            : (router.isPopping! ? .opacity.combined(with: .slideRight) : .opacity.combined(with: .slideLeft))
                    )
            }
        }
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.width
                }
                .onEnded { value in
                    if value.translation.width > 100 {
                        router.pop()
                    }
                }
        )
    }

    @ViewBuilder
    func viewFor(_ page: AppPage) -> some View {
        switch page {

        case .home:
            HomeView()
                
        case .productDetail(let product):
            ProductDetailView(product: product)
                
        case .cart(let showBackButton):
            CartView(showBackButton: .constant(showBackButton))
                
        case .checkout(let data):
            CheckoutView(data: data)
                
        case .myOrders:
            MyOrdersView()
                
        case .orderDetail(let order):
            OrderDetailView(order: order)
                
        case .orderEditting(let order):
            OrderEdittingView(order: order)
                
        case .reviewUpload(let orderId):
            ReviewUploadView(orderId: orderId)
                
        }
    }
}

