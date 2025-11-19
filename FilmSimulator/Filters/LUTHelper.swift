import UIKit
import CoreImage

class LUTHelper {
    static let shared = LUTHelper()
    
    private init() {}
    
    func createCubeData(from lutName: String, dimension: Int) -> Data? {
        // In a real app, we would parse a .cube file here.
        // For this prototype, we will generate a "Teal & Orange" look programmatically
        // to demonstrate HSL shifts without needing external assets.
        
        let size = dimension
        let count = size * size * size
        var data = [Float](repeating: 0, count: count * 4)
        
        var offset = 0
        for z in 0..<size {
            for y in 0..<size {
                for x in 0..<size {
                    let r = Float(x) / Float(size - 1)
                    let g = Float(y) / Float(size - 1)
                    let b = Float(z) / Float(size - 1)
                    
                    // Apply HSL-style Shift (Teal & Orange approximation)
                    // Push shadows (darker) towards Teal (Blue-Green)
                    // Push highlights (lighter) towards Orange (Red-Yellow)
                    
                    var newR = r
                    var newG = g
                    var newB = b
                    
                    // Simple luminance
                    let luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
                    
                    // Shadow Tint (Teal)
                    let shadowStrength = (1.0 - luma) * 0.15
                    newR -= shadowStrength
                    newG += shadowStrength * 0.5
                    newB += shadowStrength
                    
                    // Highlight Tint (Orange)
                    let highlightStrength = luma * 0.15
                    newR += highlightStrength
                    newG += highlightStrength * 0.5
                    newB -= highlightStrength
                    
                    // Saturation Boost
                    // ... (simplified for now)
                    
                    data[offset] = newR
                    data[offset + 1] = newG
                    data[offset + 2] = newB
                    data[offset + 3] = 1.0 // Alpha
                    
                    offset += 4
                }
            }
        }
        
        return Data(bytes: data, count: data.count * MemoryLayout<Float>.size)
    }
    
    // Function to parse a standard .cube file (Placeholder for future expansion)
    // Function to parse a standard .cube file
    func parseCubeFile(named fileName: String) -> (data: Data, dimension: Int)? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "cube") else {
            print("LUTHelper: Could not find \(fileName).cube in bundle")
            return nil
        }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            var size = 0
            var data = [Float]()
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix("TITLE") {
                    continue
                }
                
                if trimmed.hasPrefix("LUT_3D_SIZE") {
                    let parts = trimmed.components(separatedBy: .whitespaces)
                    if parts.count >= 2, let s = Int(parts.last!) {
                        size = s
                    }
                    continue
                }
                
                // Parse RGB values
                let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if parts.count == 3 {
                    if let r = Float(parts[0]), let g = Float(parts[1]), let b = Float(parts[2]) {
                        data.append(r)
                        data.append(g)
                        data.append(b)
                        data.append(1.0) // Alpha
                    }
                }
            }
            
            guard size > 0, data.count == size * size * size * 4 else {
                print("LUTHelper: Invalid data count or size. Size: \(size), Count: \(data.count)")
                return nil
            }
            
            let buffer = Data(bytes: data, count: data.count * MemoryLayout<Float>.size)
            return (buffer, size)
            
        } catch {
            print("LUTHelper: Error reading file: \(error)")
            return nil
        }
    }
}
