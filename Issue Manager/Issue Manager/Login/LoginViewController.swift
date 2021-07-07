// Created by Julian Dunskus

import UIKit
import UserDefault

final class LoginViewController: UIViewController {
	private typealias Localization = L10n.Login
	
	var isLoggingIn = false
	
	// unwind segue
	@IBAction func logOut(_ segue: UIStoryboardSegue) {
		Client.shared.localUser = nil
	}
	
	// unwind segue
	@IBAction func backToLogin(_ segue: UIStoryboardSegue) {}
	
	private var shouldRestoreState = true
	
	override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		guard shouldRestoreState else { return }
		shouldRestoreState = false
		
		guard Client.shared.isLoggedIn, presentedViewController == nil else { return }
		
		showSiteList(userInitiated: false)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.destination {
		case let qrScanner as QRScannerViewController:
			qrScanner.delegate = self
		case is RegisterViewController:
			break
		default:
			fatalError("unrecognized segue to \(segue.destination)")
		}
	}
	
	func logIn(with info: LoginInfo) {
		shouldRestoreState = false
		
		// dismiss any presented view controllers
		dismiss(animated: false) // don't have to animate since we're not visible until done anyway
		
		Client.shared.logIn(with: info)
			.on(.main)
			.catch(showAlert(for:))
			.then { self.showSiteList() }
	}
	
	func showAlert(for error: Error) {
		switch error {
		case RequestError.communicationError: // likely connection failure
			showAlert(
				titled: L10n.Alert.ConnectionIssues.title,
				message: L10n.Alert.ConnectionIssues.message
			)
		case RequestError.notAuthenticated: // probably invalid qr code/link
			// TODO: more specific alert?
			showAlert(
				titled: L10n.Alert.InvalidSession.title,
				message: L10n.Alert.InvalidSession.message
			)
		default:
			print("login error!")
			dump(error)
			showAlert(
				titled: Localization.Alert.LoginError.title,
				message: Localization.Alert.LoginError.message
					+ "\n\n" + error.dumpedDescription()
			)
		}
	}
	
	func showSiteList(userInitiated: Bool = true) {
		let siteList = SiteListViewController.instantiate()!
		if !userInitiated {
			siteList.needsRefresh = true
		}
		present(siteList, animated: userInitiated)
	}
}

extension LoginViewController: QRScannerViewDelegate {
	func cameraFailed(with error: Error) {
		switch error {
		case QRScannerViewError.noCameraAvailable:
			break // just ignore
		case let error:
			print("camera error!")
			dump(error)
			dismiss(animated: true)
			showAlert(
				titled: "Kamera konnte nicht aktiviert werden!",
				message: error.localizedFailureReason
			)
		}
	}
	
	func qrsFound(by scanner: QRScannerView, with contents: [String]) {
		let decoder = JSONDecoder()
		let infos = contents.compactMap {
			DeepLink(from: $0)?.loginInfo
				?? (try? decoder.decode(LoginInfo.self, from: $0.data(using: .utf8)!))
		}
		guard let info = infos.first else { return }
		scanner.isProcessing = true
		// dismiss presented qr scanner
		dismiss(animated: true)
		logIn(with: info)
	}
}
