import SpriteKit

struct SpriteSheet {
    let textures: [SKTexture]
    let frameTime: TimeInterval
    let loops: Bool
    let locked: Bool
    let declaredFrames: Int
    let actualFrames: Int
}

enum SpriteSheetLoader {
    
    static func load(name: String,
                     declaredFrameCount: Int,
                     frameTime: TimeInterval,
                     loops: Bool,
                     locked: Bool) -> SpriteSheet? {
        
        let sheet = SKTexture(imageNamed: name)
        let size = sheet.size()
        guard size.width > 0, size.height > 0, declaredFrameCount > 0 else {
            return nil
        }
        
        // Start with the declared frame count
        var frameCount = declaredFrameCount
        
        // Only attempt auto square inference if NOT locked.
        if !locked {
            let squareCandidate = Int(round(size.width / size.height))
            if squareCandidate > 0 &&
                abs(CGFloat(squareCandidate) * size.height - size.width) < 0.5 &&
                squareCandidate != declaredFrameCount {
                #if DEBUG
                print("[SpriteSheetLoader] Auto-adjusting frameCount for \(name) from \(declaredFrameCount) → \(squareCandidate) (square inference)")
                #endif
                frameCount = squareCandidate
            }
        } else {
            #if DEBUG
            if declaredFrameCount != Int(round(size.width / size.height)) {
                print("[SpriteSheetLoader] Locked sheet '\(name)' keeps declared \(declaredFrameCount) frames (ignoring square inference).")
            }
            #endif
        }
        
        // Slice horizontally into 'frameCount' textures.
        let textures = slice(texture: sheet, frames: frameCount)
        return SpriteSheet(textures: textures,
                           frameTime: frameTime,
                           loops: loops,
                           locked: locked,
                           declaredFrames: declaredFrameCount,
                           actualFrames: frameCount)
    }
    
    private static func slice(texture: SKTexture, frames: Int) -> [SKTexture] {
        guard frames > 0 else { return [] }
        var out: [SKTexture] = []
        let w = 1.0 / CGFloat(frames)
        for i in 0 ..< frames {
            let rect = CGRect(x: CGFloat(i) * w,
                              y: 0,
                              width: w,
                              height: 1.0)
            out.append(SKTexture(rect: rect, in: texture))
        }
        return out
    }
}
