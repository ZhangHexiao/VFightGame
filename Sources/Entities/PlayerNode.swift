import SpriteKit

final class PlayerNode: SKSpriteNode, FighterEntity {

    var state: EntityState = .idle
    var health: Int = GameConfig.maxHealth {
        didSet {
            if health <= 0 {
                health = 0
                if state != .death {
                    state = .death
                    resetAnimationCycle()
                }
            }
        }
    }
    var velocity: CGVector = .zero
    var facingRight: Bool = true
    
    var currentFrameIndex: Int = 0
    var frameElapsedTime: TimeInterval = 0
    
    var lastGroundedTime: TimeInterval = 0
    var pendingJumpRequestTime: TimeInterval = -1
    
    init() {
        super.init(texture: nil, color: .clear, size: GameConfig.fighterSize)
        name = "player"
        anchorPoint = CGPoint(x: 0.5, y: 0)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    
    func applyDamage(_ amount: Int, knockback: CGFloat, from attacker: FighterEntity?) {
        guard !isDead else { return }
        health = max(0, health - amount)
        if !isDead && state != .attack1 && state != .takeHit {
            state = .takeHit
            resetAnimationCycle()
        }
        if let attacker = attacker {
            facingRight = attacker.facingRight == false
        }
        velocity.dx = 0
    }
    
    func requestJump(at time: TimeInterval) {
        pendingJumpRequestTime = time
    }
    
    func requestAttack() {
        guard !isDead else { return }
        // Cannot start a new attack while taking hit or dead
        if state == .takeHit || state == .death { return }
        
        if state == .attack1 {
            // Allow re-trigger ONLY if the current attack animation has already reached (or passed) its last frame.
            // This solves the race where AnimationSystem will flip to .idle later in the same frame order.
            let lastFrame: Int
            if let count = userData?["attackFrameCount"] as? Int, count > 0 {
                lastFrame = count - 1
            } else {
                lastFrame = GameConfig.playerAttack1Frames - 1
            }
            if currentFrameIndex < lastFrame {
                // Still mid-swing – do not restart yet.
                return
            }
            // We are effectively at the end of the swing; fall through to restart.
        }
        
        state = .attack1
        resetAnimationCycle()
        #if DEBUG
        print("[Attack] Player started attack (frame reset to 0).")
        #endif
    }
    
    func resetAnimationCycle() {
        currentFrameIndex = 0
        frameElapsedTime = 0
    }
    
}
