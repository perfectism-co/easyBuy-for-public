//
//  LoadingView.swift
//  easyBuy
//
//  
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                Image("FASHION")
                ProgressView("Loading...").foregroundColor(.white)
            }
        }
        
    }
}

#Preview {
    LoadingView()
}
