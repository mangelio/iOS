// Created by Julian Dunskus

import UIKit

extension UIViewController {
	@IBInspectable
	var forceModalInPresentation: Bool {
		get { false } // dummy
		set {
			if #available(iOS 13, *), newValue {
				isModalInPresentation = true
			}
		}
	}
	
	func showAlert(
		titled title: String?,
		message: String? = nil,
		canCancel: Bool = false,
		okMessage: String = L10n.Alert.okay,
		okStyle: UIAlertAction.Style = .default,
		okHandler: (() -> Void)? = nil
	) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		if canCancel {
			alert.addAction(UIAlertAction(title: L10n.Alert.cancel, style: .cancel, handler: nil))
		}
		alert.addAction(UIAlertAction(title: okMessage, style: okStyle) { _ in
			okHandler?()
		})
		presentOnTop(alert)
	}
	
	func presentOnTop(_ modal: UIViewController) {
		let topController = sequence(first: self, next: \UIViewController.presentedViewController)
			.reduce(self) { $1 }
		topController.present(modal, animated: true)
	}
	
	func embed(_ child: UIViewController, within view: UIView) {
		addChild(child)
		view.addSubview(child.view)
		child.didMove(toParent: self)
	}
	
	func unembed(_ child: UIViewController) {
		child.willMove(toParent: nil)
		child.view.removeFromSuperview()
		child.removeFromParent()
	}
}
