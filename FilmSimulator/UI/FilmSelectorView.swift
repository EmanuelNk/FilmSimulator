import SwiftUI

struct FilmSelectorView: View {
    @Binding var currentProfile: FilmProfile
    let profiles = FilmProfile.allProfiles
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(profiles) { profile in
                    let isSelected = profile == currentProfile
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ZStack {
                            // Use per-film icon if provided, otherwise fall back to generic placeholder
                            if let iconName = profile.iconName {
                                Image(iconName)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image("portra400")
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .frame(width: 110, height: 80)
                        .clipped()
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    isSelected ? Color.yellow : Color.white.opacity(0.12),
                                    lineWidth: isSelected ? 2.5 : 1
                                )
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black.opacity(0.6))
                        )
                        .cornerRadius(12)
                        .shadow(color: isSelected ? Color.yellow.opacity(0.6) : Color.black.opacity(0.8),
                                radius: isSelected ? 8 : 6,
                                x: 0,
                                y: 4)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
                        
                        Text(profile.name)
                            .font(.caption2)
                            .foregroundColor(isSelected ? .yellow : .white.opacity(0.8))
                            .lineLimit(1)
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            currentProfile = profile
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.85), Color.black.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
