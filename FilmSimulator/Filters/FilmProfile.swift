import Foundation
import CoreImage

struct FilmProfile: Identifiable, Equatable {
    let id = UUID()
    let name: String
    /// Name of the image asset used as the film's icon / thumbnail
    let iconName: String?
    
    // Color Controls
    var saturation: Double
    var contrast: Double
    var brightness: Double
    
    // Color Matrix (RGB Bias)
    var redVector: CIVector
    var greenVector: CIVector
    var blueVector: CIVector
    
    // Tone
    var gamma: Double
    
    // Effects
    var grainIntensity: Double
    var vignetteIntensity: Double
    
    // Advanced Effects
    var bloomIntensity: Double // 0.0 to 1.0 (Halation)
    var temperature: Double    // 6500 is neutral. < 6500 warm, > 6500 cool
    var tint: Double           // 0 is neutral. < 0 green, > 0 magenta
    
    enum LUTType: Equatable {
        case none
        case tealOrange // Programmatic example
        case custom(String) // For .cube files
    }
    var lutType: LUTType = .none
    
    static func neutral(name: String, lutName: String, iconName: String? = nil) -> FilmProfile {
        return FilmProfile(
            name: name,
            iconName: iconName,
            saturation: 1.0,
            contrast: 1.0,
            brightness: 0.0,
            redVector: CIVector(x: 1.0, y: 0.0, z: 0.0, w: 0.0),
            greenVector: CIVector(x: 0.0, y: 1.0, z: 0.0, w: 0.0),
            blueVector: CIVector(x: 0.0, y: 0.0, z: 1.0, w: 0.0),
            gamma: 1.0,
            grainIntensity: 0.0,
            vignetteIntensity: 0.0,
            bloomIntensity: 0.0,
            temperature: 6500,
            tint: 0,
            lutType: .custom(lutName)
        )
    }

    static let allProfiles: [FilmProfile] = [
        FilmProfile.neutral(name: "Agfa Portrait XPS 160", lutName: "Agfa Portrait XPS 160", iconName: "pro_image_100"),
        FilmProfile.neutral(name: "b", lutName: "b", iconName: "Tmax"),
        FilmProfile.neutral(name: "Fuji Astia 100F", lutName: "Fuji Astia 100F", iconName: "fujicolor_200"),
        FilmProfile.neutral(name: "Fuji Eterna 3513", lutName: "Fuji Eterna 3513", iconName: "Superia"),
        FilmProfile.neutral(name: "Fuji Eterna 8563", lutName: "Fuji Eterna 8563", iconName: "Superia_400"),
        FilmProfile.neutral(name: "Fuji Provia 100F", lutName: "Fuji Provia 100F", iconName: "Superia"),
        FilmProfile.neutral(name: "Fuji Sensia 100", lutName: "Fuji Sensia 100", iconName: "Superia"),
        FilmProfile.neutral(name: "Fuji Superia Xtra 400", lutName: "Fuji Superia Xtra 400", iconName: "Superia_400"),
        FilmProfile.neutral(name: "Fuji Vivid 8543", lutName: "Fuji Vivid 8543", iconName: "fujicolor_200"),
        FilmProfile.neutral(name: "Kodak Ektachrome 64", lutName: "Kodak Ektachrome 64", iconName: "kodak_color"),
        FilmProfile.neutral(name: "Kodak Ektachrome 65", lutName: "Kodak Ektachrome 65", iconName: "kodak_gold"),
        FilmProfile.neutral(name: "Kodak Professional Portra 400", lutName: "Kodak Professional Portra 400", iconName: "portra400"),
        FilmProfile.neutral(name: "Kodak Vision 2383", lutName: "Kodak Vision 2383", iconName: "kodak_ultramax"),
        FilmProfile.neutral(name: "LPP Tetrachrome 400", lutName: "LPP Tetrachrome 400", iconName: "Ultramax_400"),
        FilmProfile.neutral(name: "Polaroid 600", lutName: "Polaroid 600", iconName: "pro_image_100")
    ]
}
