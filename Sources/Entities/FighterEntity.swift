import CoreGraphics
import SpriteKit

public enum EntityState: Equatable {
    case idle
    case run
    case jump
    case fall
    case attack1
    case takeHit
    case death
}

public protocol FighterEntity: AnyObject {
    var state: EntityState { get set }
    var health: Int { get set }
    var velocity: CGVector { get set }
    var facingRight: Bool { get set }
    var isDead: Bool { get }

    var currentFrameIndex: Int { get set }
    var frameElapsedTime: TimeInterval { get set }

    func applyDamage(_ amount: Int, knockback: CGFloat, from attacker: FighterEntity?)
    func resetAnimationCycle()
}

public extension FighterEntity {
    var isDead: Bool { state == .death }
}
