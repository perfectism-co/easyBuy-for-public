//
//  PagingScrollView.swift
//  easyBuy
//
// 
//  輪播圖片（UIKit + SwiftUI 包裝）
//

import SwiftUI
import UIKit

// MARK: - SwiftUI Wrapper
struct ImageCarousel: UIViewControllerRepresentable {
    var imageUrls: [String]
    var contentMode: UIView.ContentMode = .scaleAspectFill
    var autoScroll: Bool = true
    @Binding var currentIndex: Int

    init(imageUrls: [String],
         contentMode: UIView.ContentMode = .scaleAspectFill,
         autoScroll: Bool = true,
         currentIndex: Binding<Int>) {
        self.imageUrls = imageUrls
        self.contentMode = contentMode
        self.autoScroll = autoScroll
        self._currentIndex = currentIndex
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(transitionStyle: .scroll,
                                          navigationOrientation: .horizontal)
        pageVC.dataSource = context.coordinator
        pageVC.delegate = context.coordinator

        // 建立每一頁的 UIViewController
        let controllers = imageUrls.map { URLImageView(urlString: $0, contentMode: contentMode) }
        context.coordinator.controllers = controllers

        // 保護 index 範圍
        let start = min(max(0, currentIndex), max(0, controllers.count - 1))
        if controllers.indices.contains(start) {
            pageVC.setViewControllers([controllers[start]], direction: .forward, animated: false)
        }

        // 追蹤 UIScrollView 以便判定手動滑動
        context.coordinator.attachScrollObserver(to: pageVC)

        // 決定是否要啟動自動輪播
        if autoScroll {
            context.coordinator.startAutoScroll(pageVC)
        }
        return pageVC
    }

    func updateUIViewController(_ pageVC: UIPageViewController, context: Context) {
        // 更新 parent（因為 struct 是值型別）
        context.coordinator.parent = self
        
        // 如果 autoScroll 參數有改變，做同步處理
        // ✅ 改這裡：用 self.autoScroll 或 context.coordinator.parent.autoScroll
        if self.autoScroll {
            if context.coordinator.timer == nil {
                context.coordinator.startAutoScroll(pageVC)
            }
        } else {
            context.coordinator.stopAutoScroll()
        }

        guard context.coordinator.controllers.indices.contains(currentIndex) else { return }

        if let visible = pageVC.viewControllers?.first,
           let visibleIndex = context.coordinator.controllers.firstIndex(of: visible),
           visibleIndex != currentIndex {
            let direction: UIPageViewController.NavigationDirection =
                currentIndex > visibleIndex ? .forward : .reverse
            pageVC.setViewControllers([context.coordinator.controllers[currentIndex]],
                                      direction: direction,
                                      animated: true)
        } else if pageVC.viewControllers?.isEmpty ?? true {
            pageVC.setViewControllers([context.coordinator.controllers[currentIndex]],
                                      direction: .forward,
                                      animated: false)
        }
    }

    static func dismantleUIViewController(_ uiViewController: UIPageViewController,
                                          coordinator: Coordinator) {
        coordinator.stopAutoScroll()
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate {
        var parent: ImageCarousel
        var controllers: [UIViewController] = []
        var timer: Timer?
        var lastManualScroll: Date = .distantPast

        init(_ parent: ImageCarousel) { self.parent = parent }

        // 自動輪播
        func startAutoScroll(_ pageVC: UIPageViewController) {
            stopAutoScroll()
            timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak pageVC, weak self] _ in
                guard let self = self, let pageVC = pageVC, !self.controllers.isEmpty else { return }
                // 手動滑動後 5 秒內不自動滾動
                if Date().timeIntervalSince(self.lastManualScroll) < 5 { return }

                let next = (self.parent.currentIndex + 1) % self.controllers.count
                self.parent.currentIndex = next
                pageVC.setViewControllers([self.controllers[next]], direction: .forward, animated: true)
            }
            if let timer = timer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }

        func stopAutoScroll() {
            timer?.invalidate()
            timer = nil
        }

        // 偵測開始拖曳
        func attachScrollObserver(to pageVC: UIPageViewController) {
            for subview in pageVC.view.subviews {
                if let scroll = subview as? UIScrollView {
                    scroll.delegate = self
                    break
                }
            }
        }

        // 使用者開始拖曳 -> 標記時間
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            lastManualScroll = Date()
        }

        // MARK: DataSource（環狀）
        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController), !controllers.isEmpty else { return nil }
            let prev = (index - 1 + controllers.count) % controllers.count
            return controllers[prev]
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController), !controllers.isEmpty else { return nil }
            let next = (index + 1) % controllers.count
            return controllers[next]
        }

        // 同步 currentIndex
        func pageViewController(_ pageViewController: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            guard completed,
                  let visible = pageViewController.viewControllers?.first,
                  let idx = controllers.firstIndex(of: visible) else { return }
            parent.currentIndex = idx
            lastManualScroll = Date()
        }
    }
}

// MARK: - 單頁圖片載入 VC
class URLImageView: UIViewController {
    private let urlString: String
    private let contentMode: UIView.ContentMode
    
    init(urlString: String, contentMode: UIView.ContentMode) {
        self.urlString = urlString
        self.contentMode = contentMode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageView = UIImageView()
        imageView.contentMode = contentMode
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        // 🔑 判斷字串是 URL 還是 Bundle 圖片
        if let url = URL(string: urlString), url.scheme == "http" || url.scheme == "https" {
            // 遠端圖片
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async { imageView.image = image }
                }
            }.resume()
            
        } else if let bundleImage = UIImage(named: urlString) {
            // Assets.xcassets 內圖片
            imageView.image = bundleImage
            
        } else if FileManager.default.fileExists(atPath: urlString) {
            // 檔案路徑 (file://)
            imageView.image = UIImage(contentsOfFile: urlString)
        }
    }
}



// MARK: - 可點擊的 PageControl（圓點）
struct PageControl: View {
    var numberOfPages: Int
    @Binding var currentPage: Int

    var body: some View {
        HStack(spacing: 18) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.gray : Color.white.opacity(0.5)) // 選中灰色，未選白色
                    .frame(width: 8)
                    .overlay(
                        Circle()
                            .stroke(index == currentPage ? Color.white : Color.clear,
                                    lineWidth: 0.5) // 選中白邊，未選灰邊
                    )
                    .animation(.spring(), value: currentPage)
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            currentPage = index
                        }
                    }
            }
        }
    }
}



// MARK: - 使用範例（SwiftUI）
struct CarouselDemoView: View {
    @State private var index = 0
    let urls = [
        "https://picsum.photos/id/1018/900/600",
        "https://picsum.photos/id/1025/900/600",
        "https://picsum.photos/id/1039/900/600"
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ImageCarousel(imageUrls: urls, contentMode: .scaleAspectFill, autoScroll: true, currentIndex: $index)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            PageControl(numberOfPages: urls.count, currentPage: $index)
                .padding(.bottom, 8)
        }
        .padding()
    }
}
#Preview {
    CarouselDemoView()
}
