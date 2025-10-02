import SpriteKit

final class GameScene: SKScene {
    
    private let input: InputSystem
    private let hud: HUDLayer
    
    private let player = PlayerNode()
    private let enemy = EnemyNode()
    
    private let physicsSystem = PhysicsSystem()
    private let combatSystem = CombatSystem()
    private let animationSystem = AnimationSystem()
    private let enemyAI = EnemyAIController()
    private var enemyAIEnabled = false
    
    private var lastUpdateTime: TimeInterval = 0
    private var roundRemaining: TimeInterval = GameConfig.roundDurationSeconds
    private var roundOver = false
    
    private let backgroundLayer = BackgroundLayer()
    
    init(size: CGSize, inputSystem: InputSystem, hud: HUDLayer) {
        self.input = inputSystem
        self.hud = hud
        super.init(size: size)
        scaleMode = .resizeFill
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    
    override func didMove(to view: SKView) {
        setupWorld()
        spawnEntities()
        resetRoundState()
    }
    
    private func resetRoundState() {
        roundOver = false
        roundRemaining = GameConfig.roundDurationSeconds
        input.enabled = true
        hud.clearStatus()
        player.health = GameConfig.maxHealth
        enemy.health = GameConfig.maxHealth
        player.state = .idle
        enemy.state = .idle
        player.velocity = .zero
        enemy.velocity = .zero
        player.currentFrameIndex = 0
        enemy.currentFrameIndex = 0
        player.frameElapsedTime = 0
        enemy.frameElapsedTime = 0
    }
    
    private func setupWorld() {
        #if DEBUG
        let floorLine = SKShapeNode(rectOf: CGSize(width: size.width, height: 4))
        floorLine.fillColor = .darkGray
        floorLine.strokeColor = .clear
        floorLine.position = CGPoint(x: size.width / 2, y: GameConfig.floorY)
        addChild(floorLine)
        #endif
        SKTexture.preload([
            SKTexture(imageNamed: "background"),
            SKTexture(imageNamed: "shop")
        ]) { [weak self] in
            guard let self else { return }
            self.addChild(self.backgroundLayer)
            self.backgroundLayer.configureIfNeeded(sceneSize: self.size)
        }
    }
    
    private func spawnEntities() {
        let leftX  = size.width * 0.20
        let rightX = size.width * 0.80
        player.position = CGPoint(x: leftX,  y: GameConfig.fighterFloorWithOffset)
        enemy.position  = CGPoint(x: rightX, y: GameConfig.fighterFloorWithOffset)
        addChild(player)
        addChild(enemy)
    }
    
    func setEnemyAIEnabled(_ enabled: Bool) {
        guard !roundOver else {
            enemyAIEnabled = false
            return
        }
        enemyAIEnabled = enabled
    }
    
    override func update(_ currentTime: TimeInterval) {
        let dt = (lastUpdateTime == 0) ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        guard dt > 0 else { return }
        
        backgroundLayer.update(dt: dt)
        
        if !roundOver {
            roundRemaining -= dt
            if roundRemaining <= 0 {
                finishRound(timeExpired: true)
            }
        }
        
        hud.updateTimer(Int(ceil(roundRemaining)))
        input.update()
        
        if !roundOver && enemyAIEnabled {
            enemyAI.update(dt: dt, currentTime: currentTime, player: player, enemy: enemy)
        } else if roundOver {
            enemy.velocity = .zero
        } else {
            enemy.velocity.dx = 0
            if enemy.state == .run { enemy.state = .idle }
        }
        
        if !roundOver {
            physicsSystem.update(dt: dt,
                                 currentTime: currentTime,
                                 player: player,
                                 enemy: enemy,
                                 input: input)
            combatSystem.update(player: player, enemy: enemy)
        } else {
            // Freeze player horizontal motion after round ends
            player.velocity.dx = 0
        }
        
        animationSystem.update(entity: player, dt: dt)
        animationSystem.update(entity: enemy, dt: dt)
        
        if !roundOver && (player.isDead || enemy.isDead) {
            finishRound(timeExpired: false)
        }
        
        hud.updateHealth(player: player.health, enemy: enemy.health)
        animationSystem.update(entity: player, dt: dt)
        animationSystem.update(entity: enemy, dt: dt)
        
        applyFighterFacingScale(player)
        applyEnermyFacingScale(enemy)
    }
    
    private func applyFighterFacingScale(_ entity: FighterEntity & SKSpriteNode) {
        let base = abs(entity.xScale) > 0 ? abs(entity.xScale) : 1
        entity.xScale = entity.facingRight ? -base : base
    }
    
    private func applyEnermyFacingScale(_ entity: FighterEntity & SKSpriteNode) {
        let base = abs(entity.xScale) < 0 ? abs(entity.xScale) : 1
        entity.xScale = entity.facingRight ? base : -base
    }
    
    private func finishRound(timeExpired: Bool) {
        roundOver = true
        input.enabled = false
        enemyAIEnabled = false
        enemy.velocity = .zero
        player.velocity.dx = 0
        let result: String
        if timeExpired {
            if player.health == enemy.health { result = "Tie" }
            else if player.health > enemy.health { result = "Player Wins" }
            else { result = "Enemy Wins" }
        } else {
            result = player.isDead ? "Enemy Wins" : "Player Wins"
        }
        hud.setStatus(result)
    }
}
