import CoreImage
import Foundation
import UIKit

class FilterRenderer {
    private let context = CIContext()
    
    func process(image: CIImage, with profile: FilmProfile, isPreview: Bool = false) -> CIImage {
        var processed = image
        
        // 0. Temperature & Tint (White Balance)
        // We only apply if values differ from neutral defaults
        if profile.temperature != 6500 || profile.tint != 0 {
            let tempTint = CIFilter(name: "CITemperatureAndTint")!
            tempTint.setValue(processed, forKey: kCIInputImageKey)
            // Neutral vector is (6500, 0)
            tempTint.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            // Target vector
            tempTint.setValue(CIVector(x: CGFloat(profile.temperature), y: CGFloat(profile.tint)), forKey: "inputTargetNeutral")
            processed = tempTint.outputImage!
        }
        
        // 1. Color Controls (Saturation, Contrast, Brightness)
        let colorControls = CIFilter(name: "CIColorControls")!
        colorControls.setValue(processed, forKey: kCIInputImageKey)
        colorControls.setValue(profile.saturation, forKey: kCIInputSaturationKey)
        colorControls.setValue(profile.contrast, forKey: kCIInputContrastKey)
        colorControls.setValue(profile.brightness, forKey: kCIInputBrightnessKey)
        processed = colorControls.outputImage!
        
        // 2. Color Matrix (RGB Bias)
        let colorMatrix = CIFilter(name: "CIColorMatrix")!
        colorMatrix.setValue(processed, forKey: kCIInputImageKey)
        colorMatrix.setValue(profile.redVector, forKey: "inputRVector")
        colorMatrix.setValue(profile.greenVector, forKey: "inputGVector")
        colorMatrix.setValue(profile.blueVector, forKey: "inputBVector")
        processed = colorMatrix.outputImage!
        
        // 3. Gamma
        let gammaAdjust = CIFilter(name: "CIGammaAdjust")!
        gammaAdjust.setValue(processed, forKey: kCIInputImageKey)
        gammaAdjust.setValue(profile.gamma, forKey: "inputPower")
        processed = gammaAdjust.outputImage!
        
        // 4. Grain (Skipped in Preview)
        if !isPreview && profile.grainIntensity > 0 {
            let grain = CIFilter(name: "CIRandomGenerator")!
            var noiseImage = grain.outputImage!
            
            // Make grain monochrome (Black & White) for more realistic film look
            let monochrome = CIFilter(name: "CIColorMonochrome")!
            monochrome.setValue(noiseImage, forKey: kCIInputImageKey)
            monochrome.setValue(CIColor(red: 0.5, green: 0.5, blue: 0.5), forKey: kCIInputColorKey)
            monochrome.setValue(1.0, forKey: kCIInputIntensityKey)
            noiseImage = monochrome.outputImage!
            
            // Scale grain
            let transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            noiseImage = noiseImage.transformed(by: transform)
            
            // Blend grain using SoftLight for better integration
            let blend = CIFilter(name: "CISoftLightBlendMode")!
            blend.setValue(noiseImage, forKey: kCIInputImageKey)
            blend.setValue(processed, forKey: kCIInputBackgroundImageKey)
            
             processed = blend.outputImage!
        }
        
        // 5. Vignette
        if profile.vignetteIntensity > 0 {
            let vignette = CIFilter(name: "CIVignette")!
            vignette.setValue(processed, forKey: kCIInputImageKey)
            vignette.setValue(profile.vignetteIntensity * 2.0, forKey: kCIInputIntensityKey)
            vignette.setValue(2.0, forKey: kCIInputRadiusKey)
            processed = vignette.outputImage!
        }
        
        // 6. Bloom (Halation) (Disabled for now)
        /*
        if !isPreview && profile.bloomIntensity > 0 {
            let bloom = CIFilter(name: "CIBloom")!
            bloom.setValue(processed, forKey: kCIInputImageKey)
            bloom.setValue(profile.bloomIntensity * 10.0, forKey: kCIInputIntensityKey) // Scale up for visibility
            bloom.setValue(10.0, forKey: kCIInputRadiusKey) // Fixed radius for glow
            processed = bloom.outputImage!
        }
        */
        
        // 7. LUT (HSL / Color Grading)
        switch profile.lutType {
        case .tealOrange:
            // Generate data (cached in a real app)
            if let data = LUTHelper.shared.createCubeData(from: "tealOrange", dimension: 64) {
                let colorCube = CIFilter(name: "CIColorCube")!
                colorCube.setValue(processed, forKey: kCIInputImageKey)
                colorCube.setValue(64, forKey: "inputCubeDimension")
                colorCube.setValue(data, forKey: "inputCubeData")
                processed = colorCube.outputImage!
            }
        case .custom(let name):
            // Load custom .cube file
            if let (data, dimension) = LUTHelper.shared.parseCubeFile(named: name) {
                let colorCube = CIFilter(name: "CIColorCube")!
                colorCube.setValue(processed, forKey: kCIInputImageKey)
                colorCube.setValue(dimension, forKey: "inputCubeDimension")
                colorCube.setValue(data, forKey: "inputCubeData")
                processed = colorCube.outputImage!
            }
        case .none:
            break
        }
        
        // Ensure the output has a finite extent matching the input
        // This fixes issues where filters like Bloom or Grain might produce infinite or expanded extents
        return processed.cropped(to: image.extent)
    }
    
    func render(image: CIImage, to buffer: CVPixelBuffer) {
        context.render(image, to: buffer)
    }
    
    func createCGImage(from ciImage: CIImage) -> CGImage? {
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}
