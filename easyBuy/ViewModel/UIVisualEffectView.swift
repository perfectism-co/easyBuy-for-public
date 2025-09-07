
import SwiftUI

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    var intensity: CGFloat = 1.0

    // Custom container UIView with a UIVisualEffectView inside
    class BlurContainerView: UIView {
        let blurView: UIVisualEffectView

        init(style: UIBlurEffect.Style, intensity: CGFloat) {
            blurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
            super.init(frame: .zero)

            blurView.translatesAutoresizingMaskIntoConstraints = false
            blurView.alpha = intensity
            blurView.backgroundColor = .clear

            addSubview(blurView)

            // Add Auto Layout constraints to make the blur view fill its container UIView
            NSLayoutConstraint.activate([
                blurView.topAnchor.constraint(equalTo: topAnchor),
                blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
                blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    func makeUIView(context: Context) -> BlurContainerView {
        return BlurContainerView(style: blurStyle, intensity: intensity)
    }

    func updateUIView(_ uiView: BlurContainerView, context: Context) {
        uiView.blurView.effect = UIBlurEffect(style: blurStyle)
        uiView.blurView.alpha = intensity
    }
}

