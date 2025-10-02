import UIKit
import SpriteKit

@MainActor
final class GameViewController: UIViewController {
    private let skView = SKView(frame: .zero)
    private let inputSystem = InputSystem()
    private let hudLayer = HUDLayer()
    private let controlsLayer = ControlsLayer()
    private var sceneRef: GameScene?
    #if DEBUG
    private let debugOverlay = DebugToggleOverlay()
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSKView()
        setupOverlays()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if sceneRef == nil && skView.bounds.width > 0 && skView.bounds.height > 0 {
            presentScene()
        } else if let scene = sceneRef, scene.size != skView.bounds.size {
            scene.size = skView.bounds.size
        }
    }

    private func setupSKView() {
        skView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skView)
        NSLayoutConstraint.activate([
            skView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skView.topAnchor.constraint(equalTo: view.topAnchor),
            skView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupOverlays() {
        hudLayer.translatesAutoresizingMaskIntoConstraints = false
        controlsLayer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hudLayer)
        view.addSubview(controlsLayer)
        NSLayoutConstraint.activate([
            hudLayer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hudLayer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hudLayer.topAnchor.constraint(equalTo: view.topAnchor),
            hudLayer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.18),

            controlsLayer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsLayer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsLayer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlsLayer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.40)
        ])
        controlsLayer.bindInputSystem(inputSystem)

        #if DEBUG
        debugOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(debugOverlay)
        NSLayoutConstraint.activate([
            debugOverlay.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            debugOverlay.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -4),
            debugOverlay.heightAnchor.constraint(equalToConstant: 28),
            debugOverlay.widthAnchor.constraint(greaterThanOrEqualToConstant: 96)
        ])
        debugOverlay.restartHandler = { [weak self] in
            self?.restartGame()
        }
        debugOverlay.aiToggleHandler = { [weak self] enabled in
            (self?.sceneRef)?.setEnemyAIEnabled(enabled)
        }
        #endif
    }

    private func presentScene() {
        let scene = GameScene(size: skView.bounds.size, inputSystem: inputSystem, hud: hudLayer)
        scene.scaleMode = .resizeFill
        sceneRef = scene
        skView.presentScene(scene)
    }

    private func restartGame() {
        let scene = GameScene(size: skView.bounds.size, inputSystem: inputSystem, hud: hudLayer)
        scene.scaleMode = .resizeFill
        sceneRef = scene
        skView.presentScene(scene, transition: .fade(withDuration: 0.25))
    }

    override var prefersStatusBarHidden: Bool { true }
}
