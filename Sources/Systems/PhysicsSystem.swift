import CoreGraphics
import SpriteKit

/// Handles movement, gravity, jump buffer, coyote time, ground collision, horizontal bounds, and state classification.
final class PhysicsSystem {

    func update(dt: TimeInterval,
                currentTime: TimeInterval,
                player: PlayerNode,
                enemy: EnemyNode,
                input: InputSystem) {

        applyPlayerInput(dt: dt, currentTime: currentTime, player: player, input: input)
        applyGravity(dt: dt, entity: player)
        applyGravity(dt: dt, entity: enemy)

        integrate(dt: dt, currentTime: currentTime, player: player)
        integrate(dt: dt, entity: enemy)

        classifyVerticalState(player)
        classifyVerticalState(enemy)
    }

    private func applyPlayerInput(dt: TimeInterval, currentTime: TimeInterval, player: PlayerNode, input: InputSystem) {
        guard !player.isDead else { return }

        // Horizontal acceleration
        if input.horizontal != 0 {
            player.velocity.dx += input.horizontal * GameConfig.horizontalAcceleration * CGFloat(dt)
            player.velocity.dx = max(min(player.velocity.dx, GameConfig.maxHorizontalSpeed),
                                     -GameConfig.maxHorizontalSpeed)
            // Do NOT override attack (allow moving during attack)
            if !protectedState(player.state) {
                player.state = .run
            }
            player.facingRight = input.horizontal > 0
        } else {
            player.velocity.dx *= GameConfig.horizontalDamping
            if abs(player.velocity.dx) < 6 { player.velocity.dx = 0 }
            if player.state == .run && !protectedState(player.state) {
                player.state = .idle
            }
        }

        // Jump buffering
        if input.wantsJump {
            player.requestJump(at: currentTime)
        }

        let canJump = onGround(player) || (currentTime - player.lastGroundedTime <= GameConfig.coyoteTime)
        let hasBuffered = player.pendingJumpRequestTime >= 0 &&
            (currentTime - player.pendingJumpRequestTime <= GameConfig.jumpBufferWindow)

        if canJump && hasBuffered && !protectedState(player.state) {
            player.velocity.dy = GameConfig.jumpImpulse
            player.state = .jump
            player.pendingJumpRequestTime = -1
        }

        if input.wantsAttack {
            player.requestAttack()
        }
    }

    private func applyGravity(dt: TimeInterval, entity: FighterEntity & SKSpriteNode) {
        if !onGround(entity) || entity.velocity.dy > 0 {
            entity.velocity.dy += GameConfig.gravity * CGFloat(dt)
        } else {
            entity.velocity.dy = max(0, entity.velocity.dy)
        }
    }

    private func integrate(dt: TimeInterval, currentTime: TimeInterval, player: PlayerNode) {
        var p = player.position
        p.x += player.velocity.dx * CGFloat(dt)
        p.y += player.velocity.dy * CGFloat(dt)

        if p.y < GameConfig.fighterFloorWithOffset {
            p.y = GameConfig.fighterFloorWithOffset
            player.lastGroundedTime = currentTime
        }

        if let sceneWidth = player.scene?.size.width, sceneWidth > 0 {
            let half = player.size.width * 0.5
            let minX = half
            let maxX = sceneWidth - half
            if p.x < minX {
                p.x = minX
                player.velocity.dx = 0
            } else if p.x > maxX {
                p.x = maxX
                player.velocity.dx = 0
            }
        }

        player.position = p
    }

    private func integrate(dt: TimeInterval, entity: FighterEntity & SKSpriteNode) {
        var p = entity.position
        p.x += entity.velocity.dx * CGFloat(dt)
        p.y += entity.velocity.dy * CGFloat(dt)

        if p.y < GameConfig.fighterFloorWithOffset {
            p.y = GameConfig.fighterFloorWithOffset
            if entity.state == .jump || entity.state == .fall {
                if !protectedState(entity.state) {
                    entity.state = .idle
                }
            }
        }

        if let sceneWidth = entity.scene?.size.width, sceneWidth > 0 {
            let half = entity.size.width * 0.5
            let minX = half
            let maxX = sceneWidth - half
            if p.x < minX {
                p.x = minX
                entity.velocity.dx = 0
            } else if p.x > maxX {
                p.x = maxX
                entity.velocity.dx = 0
            }
        }

        entity.position = p
    }

    private func classifyVerticalState(_ entity: FighterEntity & SKSpriteNode) {
        guard !entity.isDead else { return }
        // Treat attack as protected so aerial attacks are not overridden by jump/fall state changes
        if protectedState(entity.state) { return }

        if !onGround(entity) {
            if entity.velocity.dy > 0 {
                if entity.state != .jump { entity.state = .jump }
            } else {
                if entity.state != .fall { entity.state = .fall }
            }
        } else {
            if entity.state == .jump || entity.state == .fall {
                entity.state = .idle
            }
        }
    }

    private func onGround(_ entity: FighterEntity & SKSpriteNode) -> Bool {
        entity.position.y <= GameConfig.fighterFloorWithOffset + 0.5
    }

    //Include .attack1 so attack state is preserved (allows attacking mid-air)
    private func protectedState(_ state: EntityState) -> Bool {
        switch state {
        case .takeHit, .death, .attack1:
            return true
        default:
            return false
        }
    }
}
