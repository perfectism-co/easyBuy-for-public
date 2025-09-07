//
//  TabPagingView.swift
//  easyBuy
//
//  
//  可用ForEach建頁面


import SwiftUI

struct TabPagingView<Content: View>: View {
    @Binding var selectedPage: Int
    let pageCount: Int
    let content: (Int) -> Content

    @GestureState private var dragOffset: CGFloat = 0

    init(selectedPage: Binding<Int>, pageCount: Int, @ViewBuilder content: @escaping (Int) -> Content) {
        self._selectedPage = selectedPage
        self.pageCount = pageCount
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(0..<pageCount, id: \.self) { index in
                    content(index)
                        .frame(width: geo.size.width)
                }
            }
            .offset(x: -CGFloat(selectedPage) * geo.size.width + dragOffset)
            .animation(.easeInOut(duration: 0.15), value: selectedPage)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold = geo.size.width / 2
                        let translation = value.translation.width
                        let predicted = value.predictedEndTranslation.width

                        let shouldNext = (translation < -threshold || predicted < -threshold / 2) && selectedPage < pageCount - 1
                        let shouldPrev = (translation > threshold || predicted > threshold / 2) && selectedPage > 0

                        if shouldNext {
                            selectedPage += 1
                        } else if shouldPrev {
                            selectedPage -= 1
                        }
                    }
            )
        }
    }
}




struct TabPagingViewWrapper: View {
    @State private var selectedPageIndex = 0

    let categories = ["All", "Books", "Clothing", "Electronics"]
    var columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)

    func filteredProducts1(for category: String) -> [String] {
        switch category {
        case "Books": return ["Book A", "Book B", "Book C"]
        case "Clothing": return ["Shirt", "Pants"]
        case "Electronics": return ["Phone", "Tablet", "Laptop"]
        default: return ["All Product 1", "All Product 2", "All Product 3", "All Product 4"]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(categories.indices, id: \.self) { i in
                    Button {
                        selectedPageIndex = i
                    } label: {
                        Text(categories[i])
                            .fontWeight(selectedPageIndex == i ? .bold : .regular)
                            .foregroundColor(selectedPageIndex == i ? .blue : .gray)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                    }
                    .background(
                        VStack {
                            Spacer()
                            Rectangle()
                                .frame(height: 3)
                                .foregroundColor(selectedPageIndex == i ? .blue : .clear)
                        }
                    )
                }
            }
            .background(Color(UIColor.systemBackground))
            .padding(.bottom, 4)

            TabPagingView(selectedPage: $selectedPageIndex, pageCount: categories.count) { index in
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(filteredProducts1(for: categories[index]), id: \.self) { product in
                            Text(product)
                                .frame(height: 80)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                                .padding(.horizontal, 4)
                        }
                    }
                }
            }
        }
    }
}

struct TabPagingView_Previews: PreviewProvider {
    static var previews: some View {
        TabPagingViewWrapper()
    }
}




