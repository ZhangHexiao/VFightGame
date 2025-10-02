import SpriteKit
import CoreGraphics

final class EnemyAIController {
    private var nextDecisionTime: TimeInterval = 0
    private var desiredDirection: CGFloat = 0
    
    private let closeRange: CGFloat = 120
    private let engageRange: CGFloat = 260
    private let moveSpeed: CGFloat = 260
    private let decisionMin: TimeInterval = 0.25
    private let decisionMax: TimeInterval = 0.70
    
    func update(dt: TimeInterval,
                currentTime: TimeInterval,
                player: PlayerNode,
                enemy: EnemyNode) {
        guard !enemy.isDead else { return }
        if enemy.state == .attack1 || enemy.state == .takeHit || enemy.state == .death {
            applyMovement(enemy)
            return
        }
        if currentTime >= nextDecisionTime {
            decide(currentTime: currentTime, player: player, enemy: enemy)
        }
        enemy.facingRight = player.position.x > enemy.position.x
        applyMovement(enemy)
    }
    
    private func decide(currentTime: TimeInterval,
                        player: PlayerNode,
                        enemy: EnemyNode) {
        let dx = player.position.x - enemy.position.x
        let adx = abs(dx)
        var newDir: CGFloat = 0
        
        if adx > engageRange {
            newDir = dx > 0 ? 1 : -1
        } else if adx > closeRange {
            if Bool.random(probability: 0.7) {
                newDir = dx > 0 ? 1 : -1
            }
        } else {
            let roll = Double.random(in: 0...1)
            if roll < 0.45 {
                if enemy.state != .attack1 {
                    enemy.requestAttack()
                }
            } else if roll < 0.70 {
                newDir = (dx > 0 ? -1 : 1)
            }
        }
        
        desiredDirection = newDir
        nextDecisionTime = currentTime + TimeInterval.random(in: decisionMin...decisionMax)
    }
    
    private func applyMovement(_ enemy: EnemyNode) {
        if desiredDirection == 0 {
            enemy.velocity.dx = 0
            if enemy.state == .run { enemy.state = .idle }
        } else {
            enemy.velocity.dx = desiredDirection * moveSpeed
            if enemy.state != .run { enemy.state = .run }
        }
    }
}

private extension Bool {
    static func random(probability: Double) -> Bool {
        Double.random(in: 0...1) < probability
    }
}
