import SwiftUI
import UIKit

final class ShakeDetectorViewController: UIViewController {
    var onShake: (() -> Void)?
    override var canBecomeFirstResponder: Bool { true }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake { onShake?() }
    }
}

struct ShakeDetector: UIViewControllerRepresentable {
    let onShake: () -> Void
    func makeUIViewController(context: Context) -> ShakeDetectorViewController {
        let vc = ShakeDetectorViewController()
        vc.onShake = onShake
        vc.view.isUserInteractionEnabled = false
        vc.view.backgroundColor = .clear
        return vc
    }
    func updateUIViewController(_ vc: ShakeDetectorViewController, context: Context) {
        vc.onShake = onShake
    }
}

struct DeviceShakeModifier: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        content.background(ShakeDetector(onShake: action))
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(DeviceShakeModifier(action: action))
    }
}
