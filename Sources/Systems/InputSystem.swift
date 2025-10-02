import CoreGraphics

public enum InputCommand {
    case left, right, up, attack
}

final class InputSystem {
    private(set) var active: Set<InputCommand> = []
    var enabled: Bool = true

    private(set) var horizontal: CGFloat = 0
    private(set) var wantsJump: Bool = false
    private(set) var wantsAttack: Bool = false

    func press(_ command: InputCommand) {
        guard enabled else { return }
        active.insert(command)
    }

    func release(_ command: InputCommand) {
        active.remove(command)
    }

    func update() {
        horizontal = 0
        wantsJump = false
        wantsAttack = false
        /// Translates button presses into per-frame intents.
        if active.contains(.left) { horizontal -= 1 }
        if active.contains(.right) { horizontal += 1 }
        if active.contains(.up) { wantsJump = true }
        if active.contains(.attack) { wantsAttack = true }
    }
}
