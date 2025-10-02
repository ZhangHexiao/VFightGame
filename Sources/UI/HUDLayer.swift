import UIKit

final class HUDLayer: UIView {
    private let playerHealthBar = UIProgressView(progressViewStyle: .bar)
    private let enemyHealthBar = UIProgressView(progressViewStyle: .bar)
    private let timerLabel = UILabel()
    private let statusLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func setup() {
        backgroundColor = UIColor(white: 0, alpha: 0.25)

        playerHealthBar.progressTintColor = .systemGreen
        enemyHealthBar.progressTintColor = .systemRed
        playerHealthBar.trackTintColor = .darkGray
        enemyHealthBar.trackTintColor = .darkGray

        [playerHealthBar, enemyHealthBar, timerLabel, statusLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 26, weight: .bold)
        timerLabel.textColor = .white

        statusLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 1
        statusLabel.alpha = 0   // hidden until setStatus called

        NSLayoutConstraint.activate([
            playerHealthBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 48),
            playerHealthBar.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            playerHealthBar.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.4),

            enemyHealthBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -48),
            enemyHealthBar.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            enemyHealthBar.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.4),

            timerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),

            // Place status directly under the timer
            statusLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 4),
            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.9)
        ])
    }

    func updateHealth(player: Int, enemy: Int) {
        playerHealthBar.progress = Float(player) / Float(GameConfig.maxHealth)
        enemyHealthBar.progress = Float(enemy) / Float(GameConfig.maxHealth)
    }

    func updateTimer(_ seconds: Int) {
        timerLabel.text = String(format: "%02d", max(0, seconds))
    }

    func setStatus(_ text: String) {
        statusLabel.text = text
        statusLabel.alpha = 1
    }
    
    func clearStatus() {
        statusLabel.text = nil
        statusLabel.alpha = 0
    }
}
