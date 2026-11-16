import Flutter
import UIKit
import FirebaseAuth

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    if Auth.auth().canHandle(url) {
      return
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
