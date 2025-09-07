//
//  Slider.swift
//  easyBuy
//
//  
//

import SwiftUI

struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    var step: Double // 由外部決定步進值

    var body: some View {
        ZStack{
            Capsule()
                .fill(Color.bg)
                .frame(height: 4)
            GeometryReader { geo in
                let width = geo.size.width
                let totalRange = range.upperBound - range.lowerBound
                let minPercent = (minValue - range.lowerBound) / totalRange
                let maxPercent = (maxValue - range.lowerBound) / totalRange
                let minX = width * minPercent
                let maxX = width * maxPercent

                ZStack {
                    // 滑軌背景
                    Capsule()
                        .fill(Color.bg)
                        .frame(height: 4)

                    // 選取範圍
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width:  max(0,maxX - minX), height: 4)
                        .offset(x: (maxX + minX)/2 - width/2)

                    // 左滑塊
                    sliderCircle
                        .position(x: minX, y: 22)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let location = value.location.x
                                    let percent = min(max(0, location / width), 1)
                                    let newValue = range.lowerBound + percent * totalRange
                                    let steppedValue = (newValue / step).rounded() * step
                                    minValue = min(steppedValue, maxValue)
                                }
                        )

                    // 右滑塊
                    sliderCircle
                        .position(x: maxX, y: 22)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let location = value.location.x
                                    let percent = min(max(0, location / width), 1)
                                    let newValue = range.lowerBound + percent * totalRange
                                    let steppedValue = (newValue / step).rounded() * step
                                    maxValue = max(steppedValue, minValue)
                                }
                        )
                }
                .frame(height: 44) // 明確高度，手勢才能準確感應
            }
            .frame(height: 44) // 給 GeometryReader 明確高度
            .padding(.horizontal, 14) // 圓半徑14
        }
    }
    private var sliderCircle: some View {
        Circle()
            .fill(Color.white)
            .overlay(Circle().stroke(Color.gray, lineWidth: 0.08))
            .frame(width: 28, height: 28) // 直徑28
            .shadow(color: Color.black.opacity(0.18), radius: 5, x: 0, y: 4)
    }
}





#Preview {
    struct Wrapper: View {
        @State private var min = 0.0
        @State private var max = 5000.0

        var body: some View {
            ZStack {
                Color.yellow.ignoresSafeArea()
                VStack {
                    HStack {
                        TextField("最低價格", value: $min, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)

                        Text("~")

                        TextField("最高價格", value: $max, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }
                    .padding(.horizontal)
                    
                    RangeSlider(
                        minValue: $min,
                        maxValue: $max,
                        range: 0...5000,
                        step: 50
                    )
                   
                    
                    SingleSlider(value: $min, range: 0...5000, step: 50)
                       
                    
                    VStack {}.frame(height: 50)
                    
                    Text("原生slider UI")
                    Slider(value: $min, in: 0...5000, step: 50)
                }
                .background(Color.blue)
                .padding()
            }
        }
    }
    return Wrapper()
}

struct SingleSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double // 步進值

    var body: some View {
        ZStack{
            Capsule()
                .fill(Color.bg)
                .frame(height: 4)
            VStack {
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 22, height: 4)
            }.frame(maxWidth: .infinity, alignment: .leading)
            
            GeometryReader { geo in
                let width = geo.size.width
                let totalRange = range.upperBound - range.lowerBound
                let percent = (value - range.lowerBound) / totalRange
                let knobX = width * percent

                ZStack {
                    // 滑軌背景
                    Capsule()
                        .fill(Color.bg)
                        .frame(height: 4)

                    // 已選範圍
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: knobX, height: 4)
                        .offset(x: knobX / 2 - width / 2)

                    // 滑塊
                    sliderCircle
                        .position(x: knobX, y: 22)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let location = gesture.location.x
                                    let newPercent = min(max(0, location / width), 1)
                                    let newValue = range.lowerBound + newPercent * totalRange
                                    let steppedValue = (newValue / step).rounded() * step
                                    value = min(max(range.lowerBound, steppedValue), range.upperBound)
                                }
                        )
                }
                .frame(height: 44) // 確保手勢感應範圍
            }
            .frame(height: 44) // 給 GeometryReader 高度
            .padding(.horizontal, 14) // 圓半徑14
        }
        
    }

    private var sliderCircle: some View {
        Circle()
            .fill(Color.white)
            .overlay(Circle().stroke(Color.gray, lineWidth: 0.08))
            .frame(width: 28, height: 28)
            .shadow(color: Color.black.opacity(0.18), radius: 5, x: 0, y: 4)
    }
}
