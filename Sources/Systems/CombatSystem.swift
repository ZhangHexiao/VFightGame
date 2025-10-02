import SpriteKit

/// CombatSystem
/// 1. Red attack box now starts at fighter horizontal center and extends 20px forward only.
/// 2. Attack only considered if fighter & target are on (approximately) the same Y level.
///    (We compare their bottom–anchor Y positions with a small tolerance.)
final class CombatSystem {
    
    private var lastDamageFrame: [ObjectIdentifier: [ObjectIdentifier: Int]] = [:]
    
    // CONFIG (local to this simple prototype change)
    private let forwardExtent: CGFloat = 135          // how far forward from center the box extends
    private let attackBoxHeight: CGFloat = 64        // vertical size of the small attack box
    private let yLevelTolerance: CGFloat = 4         // allowed Y difference to count as “same level”
    
    func update(player: PlayerNode, enemy: EnemyNode) {
        applyAttack(attacker: player, target: enemy)
        applyAttack(attacker: enemy, target: player)
    }
    
    private func applyAttack(attacker: FighterEntity & SKSpriteNode,
                             target: FighterEntity & SKSpriteNode) {
        guard attacker.state == .attack1,
              !attacker.isDead,
              !target.isDead else { return }
        
        guard isAttackActive(attacker) else { return }
        
        // New constraint: must share essentially the same ground Y.
        guard sameYLevel(attacker, target) else { return }
        
        let hitRect  = hitBox(for: attacker)
        let hurtRect = hurtBox(for: target)
        
        #if DEBUG
        if GameConfig.debugHitboxesEnabled {
            debugRect(hitRect, color: .red, parent: attacker.parent)
            debugRect(hurtRect, color: .green, parent: target.parent)
        }
        #endif
        
        guard hitRect.intersects(hurtRect) else { return }
        
        let aID = ObjectIdentifier(attacker)
        let tID = ObjectIdentifier(target)
        var perTarget = lastDamageFrame[aID] ?? [:]
        if perTarget[tID] == attacker.currentFrameIndex {
            return
        }
        
        target.applyDamage(GameConfig.attackDamage,
                           knockback: GameConfig.knockback,
                           from: attacker)
        perTarget[tID] = attacker.currentFrameIndex
        lastDamageFrame[aID] = perTarget
    }
    
    // MARK: - Active frame logic (unchanged)
    private func isAttackActive(_ attacker: FighterEntity & SKSpriteNode) -> Bool {
        if let actual = attacker.userData?["attackFrameCount"] as? Int, actual > 0 {
            let configuredRange = GameConfig.attackActiveFrameIndices
            if configuredRange.upperBound < actual {
                return configuredRange.contains(attacker.currentFrameIndex)
            }
            let activeFrame = max(0, actual - 2)
            #if DEBUG
            if attacker.currentFrameIndex == 0 &&
                attacker.userData?["__loggedDynAttack"] == nil {
                print("[Combat] Dynamic attack activeFrame=\(activeFrame) (actualFrames=\(actual))")
                attacker.userData?["__loggedDynAttack"] = true
            }
            #endif
            return attacker.currentFrameIndex == activeFrame
        } else {
            return GameConfig.attackActiveFrameIndices.contains(attacker.currentFrameIndex)
        }
    }
    
    // MARK: - Geometry
    
    // Small hurt box: keep using a reduced body rectangle based on entity size, centered horizontally.
    // (Kept simple; can refine later.)
    private func hurtBox(for entity: FighterEntity & SKSpriteNode) -> CGRect {
        // Use a fraction of sprite size so it shrinks away from padded transparent edges.
        let w = entity.size.width * 0.15
        let h = entity.size.height * 0.30
        let originX = entity.position.x - w / 2
        let originY = entity.position.y + (entity.size.height * 0.35) // slight lift
        return CGRect(x: originX, y: originY, width: w, height: h)
    }
    
    // NEW: Minimal forward “stab” style attack box.
    // Starts exactly at horizontal center of the fighter and extends ONLY forward 20px.
    // Vertically centered around the midpoint of the sprite’s full height (approx character torso).
    private func hitBox(for entity: FighterEntity & SKSpriteNode) -> CGRect {
        let midY = entity.position.y + entity.size.height * 0.5
        let height = attackBoxHeight
        let originY = midY - height / 2
        
        if entity.facingRight {
            // Start at center, extend +forwardExtent
            return CGRect(x: entity.position.x,
                          y: originY,
                          width: forwardExtent,
                          height: height)
        } else {
            // Facing left: extend backward (i.e., “forward” in facing direction)
            return CGRect(x: entity.position.x - forwardExtent,
                          y: originY,
                          width: forwardExtent,
                          height: height)
        }
    }
    
    private func sameYLevel(_ a: (FighterEntity & SKSpriteNode),
                            _ b: (FighterEntity & SKSpriteNode)) -> Bool {
        abs(a.position.y - b.position.y) <= yLevelTolerance
    }
    
    // MARK: - Debug
    
    private func debugRect(_ rect: CGRect, color: SKColor, parent: SKNode?) {
        guard let parent = parent else { return }
        parent.children
            .filter { $0.name == "__debug_\(color.description)" }
            .forEach { $0.removeFromParent() }
        
        let path = CGMutablePath()
        path.addRect(rect)
        let shape = SKShapeNode(path: path)
        shape.strokeColor = color
        shape.lineWidth = 2
        shape.fillColor = .clear
        shape.zPosition = 10_000
        shape.name = "__debug_\(color.description)"
        parent.addChild(shape)
        
        shape.run(.sequence([.wait(forDuration: 0.08), .removeFromParent()]))
    }
}
