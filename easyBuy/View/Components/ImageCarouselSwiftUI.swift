

import SwiftUI
import SDWebImageSwiftUI

// MARK: - ImageCarousel
struct ImageCarouselSwiftUI: View {
    let imageUrls: [String]         // Can be URL / Bundle / local path
    @Binding var currentIndex: Int
    var autoScroll: Bool = true
    var interval: TimeInterval = 3.0
    var resumeDelay: TimeInterval = 5.0
    var height: CGFloat = 220
    var cornerRadius: CGFloat = 16

    @State private var timer: Timer?
    @State private var lastUserInteraction: Date = .now

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentIndex) {
                ForEach(imageUrls.indices, id: \.self) { index in
                    CustomImageView(urlString: imageUrls[index])
                        .frame(height: height)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onChange(of: currentIndex) { _ in
                lastUserInteraction = .now
                restartTimerWithDelay()
            }

            PageControl2(numberOfPages: imageUrls.count, currentPage: $currentIndex)
                .padding(.bottom, 8)
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private func startTimer() {
        guard autoScroll, timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            if Date().timeIntervalSince(lastUserInteraction) >= resumeDelay {
                withAnimation(.easeInOut) {
                    currentIndex = (currentIndex + 1) % imageUrls.count
                }
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func restartTimerWithDelay() {
        stopTimer()
        startTimer()
    }
}

// MARK: - CustomImageView
struct CustomImageView: View {
    let urlString: String
    @State private var uiImage: UIImage? = nil

    var body: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.2) // Placeholder
            }
        }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        // 避免重複下載
        guard uiImage == nil else { return }

        if let url = URL(string: urlString), url.scheme == "http" || url.scheme == "https" {
            // 遠端 URL
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async { self.uiImage = image }
                }
            }.resume()
        } else if let bundleImage = UIImage(named: urlString) {
            // Assets.xcassets
            self.uiImage = bundleImage
        } else if FileManager.default.fileExists(atPath: urlString) {
            // 本地檔案
            self.uiImage = UIImage(contentsOfFile: urlString)
        }
    }
}


// MARK: - PageControl（doll）
struct PageControl2: View {
    var numberOfPages: Int
    @Binding var currentPage: Int

    var body: some View {
        HStack(spacing: 18) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.gray : Color.white.opacity(0.5))
                    .frame(width: 8)
                    .overlay(
                        Circle()
                            .stroke(index == currentPage ? Color.white : Color.clear,
                                    lineWidth: 0.5)
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

// MARK: - Demo 使用範例
struct CarouselDemoView2: View {
    @State private var index = 0
    let urls = [
        "https://picsum.photos/id/1018/900/600",
        "https://picsum.photos/id/1025/900/600",
        "https://picsum.photos/id/1039/900/600"
    ]

    var body: some View {
        VStack {
            ImageCarouselSwiftUI(
                imageUrls: urls,
                currentIndex: $index,
                autoScroll: true,
                interval: 1,
                resumeDelay: 5
            )
            .frame(height: 500)
            .padding()

            Text("Current Index: \(index)")
                .padding()
        }
    }
}

#Preview {
    CarouselDemoView2()
}
