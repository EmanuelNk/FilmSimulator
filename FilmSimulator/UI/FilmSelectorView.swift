import SwiftUI

struct FilmSelectorView: View {
    @Binding var currentProfile: FilmProfile
    let profiles = FilmProfile.allProfiles
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(profiles) { profile in
                    VStack {
                        Circle()
                            .fill(profile == currentProfile ? Color.yellow : Color.gray)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(profile.name.prefix(1)))
                                    .foregroundColor(.black)
                                    .fontWeight(.bold)
                            )
                        
                        Text(profile.name)
                            .font(.caption)
                            .foregroundColor(profile == currentProfile ? .yellow : .white)
                    }
                    .onTapGesture {
                        withAnimation {
                            currentProfile = profile
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.5))
    }
}
