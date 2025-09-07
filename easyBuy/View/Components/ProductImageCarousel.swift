//
//  ProductImageCarousel.swift
//  easyBuy
//
//  
//  不自動輪播

import SwiftUI

struct ProductImageCarousel: View {

    let product: OpenProduct
    let isShowImageCount: Int
    @Binding var isPresented: Bool
    @State var currentIndex: Int
    
    init(product: OpenProduct,
         isShowImageCount: Int,
         isPresented: Binding<Bool>) {
        self.product = product
        self.isShowImageCount = isShowImageCount
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: isShowImageCount) 
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(edges: .all)
            ImageCarousel(imageUrls: product.imageUrl, contentMode: .scaleAspectFit, autoScroll: false, currentIndex: $currentIndex)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack {
                HStack {                    
                    Spacer()
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black)
                        .onTapGesture {
                            withAnimation {
                                isPresented = false
                            }                           
                        }
                }
                Spacer()
                if product.imageUrl.count != 1 {
                    PageControl(numberOfPages: product.imageUrl.count, currentPage: $currentIndex)
                        .padding(8)
                }
            }
        }
    }
}


#Preview {
    ProductImageCarousel(product: .sample, isShowImageCount: 0, isPresented: .constant(true))
}

