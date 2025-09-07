//
//  Header.swift
//  easyBuy
//
//  
//

import SwiftUI

struct HeaderView<Content: View>: View {
    @EnvironmentObject var router: PageRouter   
    
    var text: String
    var bgColor: Color
    let content: Content
    let showBackButton: Bool
    
    init(
            text: String,
            bgColor: Color,
            showBackButton: Bool = false,
            @ViewBuilder content: () -> Content = { EmptyView() }
        ) {
            self.text = text
            self.bgColor = bgColor
            self.showBackButton = showBackButton
            self.content = content()
        }
    var body: some View {
        ZStack{
            VStack {
                HStack {
                    if showBackButton {
                        Button {
                            router.pop()
                        }label: {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 16, weight: .bold, design: .default))
                                
                        }
                    }
                    Spacer()
                    content
                }
                .padding(.horizontal, 20).padding(.bottom, 10)
                .frame(height: 40)
                .background(Color.bg)
                .offset(y: 0)
                
                
                Spacer()
            }
            VStack {
                Text(text)
                    .font(.headline)
                    .padding(.vertical, 28)
                    .offset(y: -24)
                Spacer()
            }
        }
        
    }
}


#Preview(" Header"){
    HeaderView(text: "123", bgColor: .bg, showBackButton: true)
}
