//
//  SceneDelegate.swift
//  TestAutomationPilot
//
//  Created by Rodney Zhang on 2025-09-30.
//

import UIKit
import SpriteKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let root = GameViewController()
        
        window.rootViewController = root
        window.makeKeyAndVisible()
        self.window = window
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
