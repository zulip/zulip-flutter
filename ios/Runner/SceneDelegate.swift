import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    // Use `DesignVariables.mainBackground` color as the background color
    // of the window.
    window?.backgroundColor = UIColor(named: "LaunchBackground")
  }
}
