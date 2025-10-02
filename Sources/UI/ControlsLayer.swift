import UIKit

final class ControlsLayer: UIView {
    private weak var inputSystem: InputSystem?
    private var buttons: [UIButton] = []

    private let clusterPadding: CGFloat = 16
    private let clusterSpacing: CGFloat = 12

    func bindInputSystem(_ input: InputSystem) {
        self.inputSystem = input
        setupIfNeeded()
    }

    private func setupIfNeeded() {
        guard buttons.isEmpty else { return }
        backgroundColor = .clear
        isUserInteractionEnabled = true
        createButton(title: "UP",     id: "control_up",     cmd: .up)
        createButton(title: "LEFT",   id: "control_left",   cmd: .left)
        createButton(title: "RIGHT",  id: "control_right",  cmd: .right)
        createButton(title: "ATTACK", id: "control_attack", cmd: .attack)
    }

    private func createButton(title: String, id: String, cmd: InputCommand) {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.backgroundColor = UIColor(white: 1, alpha: 0.50)
        b.layer.masksToBounds = true
        b.translatesAutoresizingMaskIntoConstraints = true
        b.tintColor = .white
        b.setTitleColor(.white, for: .normal)
        b.accessibilityIdentifier = id
        b.accessibilityHint = hint(for: cmd)
        b.addTarget(self, action: #selector(down(_:)), for: [.touchDown, .touchDragEnter])
        b.addTarget(self, action: #selector(up(_:)), for: [.touchUpInside, .touchCancel, .touchDragExit])
        addSubview(b)
        buttons.append(b)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        place()
    }

    private func place() {
        guard buttons.count == 4 else { return }
        let d = GameConfig.buttonDiameter
        let insets = safeAreaInsets

        func button(_ id: String) -> UIButton? {
            buttons.first { $0.accessibilityIdentifier == id }
        }

        guard
            let upButton = button("control_up"),
            let leftButton = button("control_left"),
            let rightButton = button("control_right"),
            let attackButton = button("control_attack")
        else { return }

        for b in [upButton, leftButton, rightButton, attackButton] {
            if b.bounds.size != CGSize(width: d, height: d) {
                b.bounds = CGRect(x: 0, y: 0, width: d, height: d)
                b.layer.cornerRadius = d / 2
            }
        }

        let bottomCenterY = bounds.height - insets.bottom - clusterPadding - d / 2
        let leftCenterX = insets.left + clusterPadding + d / 2

        leftButton.center = CGPoint(x: leftCenterX, y: bottomCenterY)
        rightButton.center = CGPoint(x: leftButton.center.x + (d + clusterSpacing), y: bottomCenterY)
        upButton.center = CGPoint(x: (leftButton.center.x + rightButton.center.x) / 2,
                                  y: bottomCenterY - d )

        let rightCenterX = bounds.width - insets.right - clusterPadding - d / 2
        attackButton.center = CGPoint(x: rightCenterX, y: bottomCenterY)
    }

    @objc private func down(_ sender: UIButton) {
        guard let cmd = command(from: sender) else { return }
        inputSystem?.press(cmd)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func up(_ sender: UIButton) {
        if let cmd = command(from: sender) {
            inputSystem?.release(cmd)
        }
    }

    private func hint(for cmd: InputCommand) -> String {
        switch cmd {
        case .up: return "up"
        case .left: return "left"
        case .right: return "right"
        case .attack: return "attack"
        }
    }

    private func command(from button: UIButton) -> InputCommand? {
        switch button.accessibilityHint {
        case "up": return .up
        case "left": return .left
        case "right": return .right
        case "attack": return .attack
        default: return nil
        }
    }
}
