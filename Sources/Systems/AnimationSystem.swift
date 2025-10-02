import SpriteKit

/// Texture-based animation system for all fighter states (idle, run, jump, fall, attack1, takeHit, death).
/// Supports per-kind (player/enemy) frame count differences & auto-detect sheet frame counts.
final class AnimationSystem {
    
    private struct EntityAnimationCache {
        var sheets: [EntityState: SpriteSheet] = [:]
        var lastState: EntityState = .idle
    }
    
    private var cache: [ObjectIdentifier: EntityAnimationCache] = [:]
    
    func update(entity: (FighterEntity & SKSpriteNode), dt: TimeInterval) {
        let oid = ObjectIdentifier(entity)
        if cache[oid] == nil {
            cache[oid] = EntityAnimationCache()
        }
        guard var anim = cache[oid] else { return }
        
        let kind: FighterKind = (entity is PlayerNode) ? .player : .enemy
        let state = entity.state
        
        if anim.sheets[state] == nil {
            let spec = AnimationSheetCatalog.spec(kind: kind, state: state)
            if let sheet = SpriteSheetLoader.load(name: spec.name,
                                                  declaredFrameCount: spec.frames,
                                                  frameTime: spec.frameTime,
                                                  loops: spec.loops,
                                                  locked: spec.locked) {
                #if DEBUG
                if sheet.declaredFrames != sheet.actualFrames {
                    print("[AnimationSystem] Sheet \(spec.name): declared \(sheet.declaredFrames) -> actual \(sheet.actualFrames)")
                }
                #endif
                anim.sheets[state] = sheet
            } else {
                // Fallback placeholder so animation timing still advances and state can recover.
                #if DEBUG
                print("[AnimationSystem] WARNING: missing sheet '\(spec.name)' for state \(state); using 1-frame placeholder.")
                #endif
                anim.sheets[state] = placeholderSheet(for: state, spec: spec)
            }
        }
        
        guard let sheet = anim.sheets[state] else {
            cache[oid] = anim
            return
        }
        
        if anim.lastState != state {
            entity.currentFrameIndex = 0
            entity.frameElapsedTime = 0
            anim.lastState = state
        }
        
        if state == .attack1,
           !sheet.loops,
           entity.currentFrameIndex == sheet.textures.count - 1,
           !entity.isDead {
            let reachedActive = (entity.userData?["__reachedActiveFrame"] as? Bool) ?? false
            if reachedActive {
                entity.state = .idle
                entity.resetAnimationCycle()
                entity.userData?["__reachedActiveFrame"] = false
                #if DEBUG
                print("[AnimationSystem] attack1 finished after active frame; transitioning to idle.")
                #endif
            } else {
                // Force one extra frame by not exiting yet; next frame will satisfy reachedActive (or at least display final frame visibly)
                #if DEBUG
                print("[AnimationSystem] attack1 hit final frame without active window; delaying exit 1 frame.")
                #endif
            }
        }
        entity.frameElapsedTime += dt
        while entity.frameElapsedTime >= sheet.frameTime {
            entity.frameElapsedTime -= sheet.frameTime
            entity.currentFrameIndex += 1
            if entity.currentFrameIndex >= sheet.textures.count {
                if sheet.loops {
                    entity.currentFrameIndex = 0
                } else {
                    // Clamp to last frame for non-looping animations
                    entity.currentFrameIndex = max(0, sheet.textures.count - 1)
                }
            }
        }
        
        if !sheet.textures.isEmpty {
            let idx = min(entity.currentFrameIndex, sheet.textures.count - 1)
            let tex = sheet.textures[idx]
            if entity.texture !== tex {
                entity.texture = tex
                // Scale to canonical height while preserving aspect.
                let original = tex.size()
                if original.height > 0 {
                    let targetHeight = GameConfig.fighterSize.height
                    let scale = targetHeight / original.height
                    entity.size = CGSize(width: original.width * scale,
                                         height: targetHeight)
                }
            }
        }
        
        // Auto-exit logic for non-looping transient states:
        // attack1 and takeHit should both return to idle after their final frame
        if (state == .attack1 || state == .takeHit),
           !sheet.loops,
           entity.currentFrameIndex == sheet.textures.count - 1,
           !entity.isDead {
            entity.state = .idle
            entity.resetAnimationCycle()
            #if DEBUG
            print("[AnimationSystem] \(state) finished; transitioning to idle.")
            #endif
        }
        
        cache[oid] = anim
    }
    
    // Simple placeholder (solid color) if a sheet fails to load.
    private func placeholderSheet(for state: EntityState, spec: AnimationSheetSpec) -> SpriteSheet {
        let color: SKColor
        switch state {
        case .attack1: color = .red
        case .takeHit: color = .yellow
        case .death:   color = .gray
        default:       color = .cyan
        }
        let size = CGSize(width: 64, height: 64)
        let image = SKImage(color: color, size: size)
        let texture = SKTexture(image: image)
        return SpriteSheet(textures: [texture],
                           frameTime: spec.frameTime,
                           loops: false,
                           locked: spec.locked,
                           declaredFrames: 1,
                           actualFrames: 1)
    }
}

// Helper to synthesize an image from a color ( SpriteKit has no direct SKImage; use NSImage/UIImage bridging )
#if os(iOS) || os(tvOS)
import UIKit
private typealias SKImage = UIImage
private extension UIImage {
    convenience init(color: UIColor, size: CGSize) {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.init(cgImage: img.cgImage!)
    }
}
#elseif os(macOS)
import AppKit
private typealias SKImage = NSImage
private extension NSImage {
    convenience init(color: NSColor, size: CGSize) {
        self.init(size: size)
        lockFocus()
        color.setFill()
        NSBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
        unlockFocus()
    }
}
#endif
