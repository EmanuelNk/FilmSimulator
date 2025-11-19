import SwiftUI
import UIKit

struct ControlDial: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var format: String = "%.1f"
    
    @State private var lastHapticStep: Double?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label.uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text(String(format: format, value))
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                
                ZStack(alignment: .leading) {
                    // Tick marks across the width
                    let tickCount = 21
                    ForEach(0..<tickCount, id: \.self) { index in
                        let x = CGFloat(index) / CGFloat(tickCount - 1) * width
                        Rectangle()
                            .fill(Color.white.opacity(index == tickCount / 2 ? 0.8 : 0.4))
                            .frame(width: 1, height: index.isMultiple(of: 2) ? 14 : 8)
                            .position(x: x, y: height / 2)
                    }
                    
                    // Custom knob that follows the bound value
                    let fraction = CGFloat(
                        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
                    )
                    let clamped = min(max(fraction, 0), 1)
                    let knobX = clamped * width
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                        .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                        .position(x: knobX, y: height / 2)
                }
                .contentShape(Rectangle()) // Entire area responds to drag
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let x = min(max(drag.location.x, 0), width)
                            let t = x / width
                            let raw = range.lowerBound + Double(t) * (range.upperBound - range.lowerBound)
                            
                            // Apply stepping to mimic Slider behaviour
                            let stepped = (raw / step).rounded() * step
                            let clampedValue = min(max(stepped, range.lowerBound), range.upperBound)
                            
                            value = clampedValue
                            
                            // Haptic feedback per "tick"
                            let currentStepIndex = ((clampedValue - range.lowerBound) / step).rounded()
                            if lastHapticStep == nil || lastHapticStep != currentStepIndex {
                                lastHapticStep = currentStepIndex
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        }
                        .onEnded { _ in
                            lastHapticStep = nil
                        }
                )
            }
            .frame(height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
}
