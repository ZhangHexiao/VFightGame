import SpriteKit

/// Handles static background + an animated sub-layer (e.g. the "shop" from the JS tutorial).
final class BackgroundLayer: SKNode {

    private let backgroundNode = SKSpriteNode()
    private let animatedNode = SKSpriteNode()

    // Animation bookkeeping
    private var frames: [SKTexture] = []
    private var elapsed: TimeInterval = 0
    private var currentFrameIndex: Int = 0

    private var isConfigured = false

    override init() {
        super.init()
        name = "BackgroundLayer"
        zPosition = -10  // Behind everything else
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configureIfNeeded(sceneSize: CGSize) {
        guard !isConfigured, sceneSize.width > 0 else { return }
        isConfigured = true

        loadTextures()
        setupBackground(size: sceneSize)
        setupAnimatedNode()
    }

    private func loadTextures() {
        // Static background texture
        let bgTexture = SKTexture(imageNamed: "background")
        backgroundNode.texture = bgTexture
        // Switch to center anchoring for simpler aspectFill math
        backgroundNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        if let sheetTexture = optionalTexture(named: "shop") {
            frames = sliceHorizontalSheet(texture: sheetTexture,
                                          frameCount: GameConfig.shopFrameCount)
        }
        
        animatedNode.texture = frames.first
        animatedNode.anchorPoint = CGPoint(x: 0.5, y: 0)
    }

    private func setupBackground(size: CGSize) {
        guard let tex = backgroundNode.texture else { return }

        let texSize = tex.size()
        let widthRatio  = size.width  / texSize.width
        let heightRatio = size.height / texSize.height
        let scale = max(widthRatio, heightRatio)   // aspect fill (cover)

        backgroundNode.size = CGSize(width: texSize.width * scale,
                                     height: texSize.height * scale)
        backgroundNode.position = CGPoint(x: size.width / 2,
                                          y: size.height / 2)

        addChild(backgroundNode)
    }

    private func setupAnimatedNode() {
        // Position animated node relative to the floor line in scene coordinates,
        // not relative to background node's local size (so it matches gameplay floor).
        let yOffset: CGFloat = GameConfig.floorY
        // For horizontal placement we can keep a percentage of scene width
        let xPercent: CGFloat = 0.70

        // animatedNode size = first frame size (unscaled) for now
        if let first = frames.first {
            animatedNode.size = first.size()
        }

        animatedNode.position = CGPoint(x: (scene?.size.width ?? backgroundNode.size.width) * xPercent,
                                        y: yOffset)
        animatedNode.zPosition = 1
        addChild(animatedNode)
    }

    func update(dt: TimeInterval) {
        guard frames.count > 1 else { return }
        elapsed += dt
        let frameTime = GameConfig.shopFrameTime
        if elapsed >= frameTime {
            let steps = Int(elapsed / frameTime)
            elapsed -= frameTime * Double(steps)
            currentFrameIndex = (currentFrameIndex + steps) % frames.count
            animatedNode.texture = frames[currentFrameIndex]
        }
    }

    func resize(sceneSize: CGSize) {
        guard let tex = backgroundNode.texture else { return }
        let texSize = tex.size()
        let widthRatio  = sceneSize.width  / texSize.width
        let heightRatio = sceneSize.height / texSize.height
        let scale = max(widthRatio, heightRatio)
        backgroundNode.size = CGSize(width: texSize.width * scale,
                                     height: texSize.height * scale)
        backgroundNode.position = CGPoint(x: sceneSize.width / 2,
                                          y: sceneSize.height / 2)

        // Reposition animated node horizontally by same percentage (xPercent),
        // vertical stays at floorY.
        let xPercent: CGFloat = 0.70
        animatedNode.position.x = sceneSize.width * xPercent
        animatedNode.position.y = GameConfig.floorY
    }

    // MARK: - Helpers

    private func optionalTexture(named: String) -> SKTexture? {
        let t = SKTexture(imageNamed: named)
        if t.size().width == 0 || t.size().height == 0 { return nil }
        return t
    }

    private func sliceHorizontalSheet(texture: SKTexture, frameCount: Int) -> [SKTexture] {
        guard frameCount > 0 else { return [] }
        var result: [SKTexture] = []
        let w = 1.0 / CGFloat(frameCount)
        for i in 0 ..< frameCount {
            let rect = CGRect(x: CGFloat(i) * w,
                              y: 0,
                              width: w,
                              height: 1.0)
            let sub = SKTexture(rect: rect, in: texture)
            result.append(sub)
        }
        return result
    }
}
