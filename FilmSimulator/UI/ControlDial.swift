import SwiftUI

struct ControlDial: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var format: String = "%.1f"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label.uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(String(format: format, value))
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Slider(
                value: $value,
                in: range,
                step: step
            ) {
                Text(label)
            } minimumValueLabel: {
                Text(String(format: format, range.lowerBound))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            } maximumValueLabel: {
                Text(String(format: format, range.upperBound))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .tint(.yellow)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
