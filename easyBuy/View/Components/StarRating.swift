//
//  StarRating.swift
//  easyBuy
//
//  
//

import SwiftUI

struct StarRating: View {
    @Binding var rating: Int
    var maxRating: Int = 5
    var starSize: CGFloat = 30
    var filledColor: Color = .yellow
    var emptyColor: Color = .gray

    var body: some View {
        HStack {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .resizable()
                    .frame(width: starSize, height: starSize)
                    .foregroundColor(index <= rating ? filledColor : emptyColor)
                    .onTapGesture {
                        rating = index
                    }
            }
        }
    }
}

#Preview {
    StarRating(rating: Binding<Int>.init(get: { 3 }, set: { _ in }))
    StarRatingView(rating: 3 , starSize: 20)
}


struct StarRatingView: View {
    var rating: Int
    var maxRating: Int = 5
    var starSize: CGFloat = 30
    var filledColor: Color = .yellow
    var emptyColor: Color = .gray.opacity(0.2)

    var body: some View {
        HStack {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: "star.fill")
                    .resizable()
                    .frame(width: starSize, height: starSize)
                    .foregroundColor(index <= rating ? filledColor : emptyColor)
            }
        }
    }
}
