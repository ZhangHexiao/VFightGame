import SpriteKit

final class EnemyNode: SKSpriteNode, FighterEntity {

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
    var facingRight: Bool = false
    
    var currentFrameIndex: Int = 0
    var frameElapsedTime: TimeInterval = 0
    
    private var aiTimer: TimeInterval = 0
    
    init() {
        super.init(texture: nil, color: .clear, size: GameConfig.fighterSize)
        name = "enemy"
        anchorPoint = CGPoint(x: 0.5, y: 0)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    
    func updateAI(dt: TimeInterval, playerPosition: CGPoint) {
        guard !isDead else { return }
        aiTimer += dt
        facingRight = playerPosition.x > position.x
    }
    
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
    
    func requestAttack() {
        guard !isDead else { return }
        if state == .takeHit || state == .death { return }
        if state == .attack1 {
            let lastFrame = (userData?["attackFrameCount"] as? Int).map { $0 - 1 } ?? 3
            if currentFrameIndex < lastFrame { return }
        }
        state = .attack1
        resetAnimationCycle()
    }
    
    func resetAnimationCycle() {
        currentFrameIndex = 0
        frameElapsedTime = 0
    }
}
