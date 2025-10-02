import CoreGraphics
import Foundation

public enum GameConfig {
    // World / Physics
    public static let gravity: CGFloat = -1800
    public static let floorY: CGFloat = 35
    public static let fighterFloorWithOffset: CGFloat = -85
    public static let jumpImpulse: CGFloat = 900
    public static let horizontalAcceleration: CGFloat = 1400
    public static let horizontalDamping: CGFloat = 0.82
    public static let maxHorizontalSpeed: CGFloat = 420
    
    // Leniency
    public static let coyoteTime: TimeInterval = 0.08
    public static let jumpBufferWindow: TimeInterval = 0.15
    
    // Combat
    public static let maxHealth: Int = 100
    public static let attackDamage: Int = 20
    public static let knockback: CGFloat = 30
    public static let attackActiveFrameIndices: ClosedRange<Int> = 1...2
    public static let combatBodyWidthFraction: CGFloat = 0.45   // 45% of sprite width = logical body
    public static let combatHurtHeightFraction: CGFloat = 0.80  // 80% of height
    public static let combatHurtYOffsetFraction: CGFloat = 0.05 // small lift so feet not fully included
    public static let combatAttackReach: CGFloat = 180          // forward distance beyond body edge
    public static let combatAttackHeightFraction: CGFloat = 0.60 // vertical coverage for attack box
    public static let combatDirectionTolerance: CGFloat = 12     // allow slight overlap behind center
    
    // Animation timing (seconds per frame)
    public static let idleFrameTime: TimeInterval   = 1.0 / 5.0
    public static let runFrameTime: TimeInterval    = 1.0 / 14.0
    public static let jumpFrameTime: TimeInterval   = 1.0 / 8.0
    public static let fallFrameTime: TimeInterval   = 1.0 / 8.0
    public static let attackFrameTime: TimeInterval = 1.0 / 16.0
    public static let hitFrameTime: TimeInterval    = 1.0 / 14.0
    public static let deathFrameTime: TimeInterval  = 1.0 / 8.0
    
    // Frame counts (generic defaults)
    // We keep idleFrames = enemyIdleFrames for backward compatibility,
    // but introduce per-kind overrides for mismatched sheets.
    public static let enemyIdleFrames = 8
    public static let playerIdleFrames = 4   // <-- your player sheet has 4 frames
    public static let idleFrames = enemyIdleFrames
    
    public static let runFrames = 8
    public static let jumpFrames = 2
    public static let fallFrames = 2
//    public static let attackFrames = 6
//    public static let hitFrames = 4
    public static let playerTakeHitFrames = 3
    public static let enemyTakeHitFrames  = 4
    public static let playerAttack1Frames = 4
    public static let enemyAttack1Frames  = 6
    public static let playerDeathFrames = 7
    public static let enemyDeathFrames = 6
    
    public static let fighterSize = CGSize(width: 320, height: 320)
    
    // Background / environment animation
    public static let shopFrameCount: Int = 6
    public static let shopFrameTime: TimeInterval = 1.0 / 8.0
    
    // Round
    public static let roundDurationSeconds: TimeInterval = 180
    
    // UI controls sizing
    public static let buttonDiameter: CGFloat = 70
    
    // Debug flag for attack
    public static var debugHitboxesEnabled: Bool = true
}

// MARK: Fighter Kind / Sheet Naming

public enum FighterKind {
    case player
    case enemy
    
    func sheetBase(for state: EntityState) -> String {
        let prefix = (self == .player) ? "player" : "enemy"
        switch state {
        case .idle:    return "\(prefix)_idle"
        case .run:     return "\(prefix)_run"
        case .jump:    return "\(prefix)_jump"
        case .fall:    return "\(prefix)_fall"
        case .attack1: return "\(prefix)_attack1"
        case .takeHit: return "\(prefix)_takeHit"
        case .death:   return "\(prefix)_death"
        }
    }
}

public struct AnimationSheetSpec {
    let name: String
    let frames: Int
    let frameTime: TimeInterval
    let loops: Bool
    let locked: Bool
}

public enum AnimationSheetCatalog {
    public static func spec(kind: FighterKind, state: EntityState) -> AnimationSheetSpec {
        switch state {
        case .idle:
            let frames = (kind == .player) ? GameConfig.playerIdleFrames : GameConfig.enemyIdleFrames
            return AnimationSheetSpec(name: kind.sheetBase(for: state),
                                      frames: frames,
                                      frameTime: GameConfig.idleFrameTime,
                                      loops: true,
                                      locked: false)
        case .run:
            return AnimationSheetSpec(name: kind.sheetBase(for: state),
                                      frames: GameConfig.runFrames,
                                      frameTime: GameConfig.runFrameTime,
                                      loops: true,
                                      locked: false)
        case .jump:
            return AnimationSheetSpec(name: kind.sheetBase(for: state),
                                      frames: GameConfig.jumpFrames,
                                      frameTime: GameConfig.jumpFrameTime,
                                      loops: false,
                                      locked: false)
        case .fall:
            return AnimationSheetSpec(name: kind.sheetBase(for: state),
                                      frames: GameConfig.fallFrames,
                                      frameTime: GameConfig.fallFrameTime,
                                      loops: true,
                                      locked: false)
        case .attack1:
            let frames = (kind == .player) ? GameConfig.playerAttack1Frames : GameConfig.enemyAttack1Frames
            return AnimationSheetSpec(name: kind.sheetBase(for: state),
                                      frames: frames,
                                      frameTime: GameConfig.attackFrameTime,
                                      loops: false,
                                      locked: true)
        case .takeHit:
            let frames = (kind == .player) ? GameConfig.playerTakeHitFrames : GameConfig.enemyTakeHitFrames
            return AnimationSheetSpec(name: kind.sheetBase(for: state),
                                      frames: frames,
                                      frameTime: GameConfig.hitFrameTime,
                                      loops: false,
                                      locked: true)
        case .death:
            let frames = (kind == .player) ? GameConfig.playerDeathFrames : GameConfig.enemyDeathFrames
            return AnimationSheetSpec(name: kind.sheetBase(for: state),
                                      frames: frames,
                                      frameTime: GameConfig.deathFrameTime,
                                      loops: false,
                                      locked: true)
        }
    }
}
