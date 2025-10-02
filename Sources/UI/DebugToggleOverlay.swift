import UIKit

final class DebugToggleOverlay: UIView {
    private let debugButton = UIButton(type: .system)
    private let aiButton = UIButton(type: .system)
    private let restartButton = UIButton(type: .system)

    var restartHandler: (() -> Void)?
    var aiToggleHandler: ((Bool) -> Void)?

    private var aiEnabled = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func setup() {
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        debugButton.setTitle("🐞", for: .normal)
        debugButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        debugButton.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
        debugButton.layer.cornerRadius = 14
        debugButton.accessibilityIdentifier = "debug_toggle_hitboxes"
        debugButton.addTarget(self, action: #selector(toggleHitboxes), for: .touchUpInside)

        aiButton.translatesAutoresizingMaskIntoConstraints = false
        aiButton.setTitle("🤖", for: .normal)
        aiButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        aiButton.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
        aiButton.layer.cornerRadius = 14
        aiButton.accessibilityIdentifier = "debug_toggle_ai"
        aiButton.addTarget(self, action: #selector(toggleAI), for: .touchUpInside)

        restartButton.translatesAutoresizingMaskIntoConstraints = false
        restartButton.setTitle("🔄", for: .normal)
        restartButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        restartButton.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
        restartButton.layer.cornerRadius = 14
        restartButton.accessibilityIdentifier = "debug_restart_game"
        restartButton.addTarget(self, action: #selector(restartGame), for: .touchUpInside)

        addSubview(restartButton)
        addSubview(aiButton)
        addSubview(debugButton)

        NSLayoutConstraint.activate([
            debugButton.topAnchor.constraint(equalTo: topAnchor),
            debugButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            debugButton.widthAnchor.constraint(equalToConstant: 28),
            debugButton.heightAnchor.constraint(equalToConstant: 28),
            debugButton.bottomAnchor.constraint(equalTo: bottomAnchor),

            aiButton.centerYAnchor.constraint(equalTo: debugButton.centerYAnchor),
            aiButton.trailingAnchor.constraint(equalTo: debugButton.leadingAnchor, constant: -6),
            aiButton.widthAnchor.constraint(equalToConstant: 28),
            aiButton.heightAnchor.constraint(equalToConstant: 28),

            restartButton.centerYAnchor.constraint(equalTo: debugButton.centerYAnchor),
            restartButton.trailingAnchor.constraint(equalTo: aiButton.leadingAnchor, constant: -6),
            restartButton.widthAnchor.constraint(equalToConstant: 28),
            restartButton.heightAnchor.constraint(equalToConstant: 28),
            restartButton.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
    }

    @objc private func toggleHitboxes() {
        GameConfig.debugHitboxesEnabled.toggle()
        UIView.animate(withDuration: 0.15) {
            self.debugButton.transform = GameConfig.debugHitboxesEnabled
                ? .identity
                : CGAffineTransform(scaleX: 0.85, y: 0.85)
        }
    }

    @objc private func toggleAI() {
        aiEnabled.toggle()
        aiToggleHandler?(aiEnabled)
        UIView.animate(withDuration: 0.15) {
            self.aiButton.transform = self.aiEnabled
                ? .identity
                : CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.aiButton.backgroundColor = self.aiEnabled
                ? UIColor(white: 0.10, alpha: 0.75)
                : UIColor(white: 0.15, alpha: 0.6)
        }
    }

    @objc private func restartGame() {
        restartHandler?()
        UIView.animate(withDuration: 0.15, animations: {
            self.restartButton.transform = CGAffineTransform(rotationAngle: .pi)
        }, completion: { _ in
            UIView.animate(withDuration: 0.15) {
                self.restartButton.transform = .identity
            }
        })
    }
}
