// Created by Julian Dunskus

import UIKit

final class RegisterViewController: UIViewController {
	fileprivate typealias Localization = L10n.Register
	
	private static let defaultWebsite = "app.baupen.ch"
	
	@IBOutlet private var windowView: UIView!
	@IBOutlet private var formView: UIView!
	
	@IBOutlet private var emailField: UITextField!
	@IBOutlet private var websiteField: UITextField!
	@IBOutlet private var useOtherWebsiteSwitch: UISwitch!
	
	@IBOutlet private var activityIndicator: UIActivityIndicatorView!
	
	@IBOutlet private var emailExplanation: UIView!
	
	@IBOutlet private var registerButton: UIButton!
	
	@IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
		emailField.resignFirstResponder()
		websiteField.resignFirstResponder()
	}
	
	@IBAction func useOtherWebsiteToggled() {
		canEditWebsite = useOtherWebsiteSwitch.isOn
	}
	
	@IBAction func register() {
		let email = emailField.text!
		guard email.contains("@") else {
			return showAlert(
				titled: Localization.Alert.InvalidEmail.title,
				message: Localization.Alert.InvalidEmail.message(email)
			)
		}
		let website = websiteField.isEnabled ? websiteField.text! : Self.defaultWebsite
		
		let scheme = "https://"
		guard let url = URL(string: website.hasPrefix(scheme) ? website : scheme + website) else {
			return showAlert(
				titled: Localization.Alert.InvalidWebsite.title,
				message: Localization.Alert.InvalidWebsite.message(website)
			)
		}
		
		canEdit = false
		isLoading = true
		Client.shared.register(asEmail: email, at: url)
			.on(.main)
			.always { self.isLoading = false }
			.catch { error in
				error.printDetails(context: "Registration failed!")
				self.canEdit = true
				self.showAlert(for: error)
			}
			.then {
				self.registerButton.isHidden = true
				self.emailExplanation.isHidden = false
			}
	}
	
	// unwind segue
	@IBAction func logOut(_ segue: UIStoryboardSegue) {}
	
	/// - note: only ever change this from the main queue
	var isLoading = false {
		didSet {
			formView.alpha = isLoading ? 0.5 : 1
			if isLoading {
				activityIndicator.startAnimating()
			} else {
				activityIndicator.stopAnimating()
			}
		}
	}
	
	var canEditWebsite = false {
		didSet {
			websiteField.isEnabled = canEditWebsite
			websiteField.alpha = canEditWebsite ? 1 : 0.75
		}
	}
	
	var canEdit = true {
		didSet {
			emailField.isEnabled = canEdit
			websiteField.isEnabled = canEdit && canEditWebsite
			
			registerButton.isEnabled = canEdit
		}
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		.lightContent
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		transitioningDelegate = self
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		canEditWebsite = false
		websiteField.text = Self.defaultWebsite
	}
	
	func showAlert(for error: Error) {
		switch error {
		case RequestError.communicationError:
			showAlert(
				titled: L10n.Alert.ConnectionIssues.title,
				message: L10n.Alert.ConnectionIssues.message
			)
		case let error:
			showAlert(
				titled: Localization.Alert.UnknownError.title,
				message: Localization.Alert.UnknownError.message(error.dumpedDescription())
			)
		}
	}
}

extension RegisterViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		switch textField {
		case emailField:
			if websiteField.isEnabled {
				websiteField.becomeFirstResponder()
			} else {
				emailField.resignFirstResponder()
				register()
			}
		case websiteField:
			websiteField.resignFirstResponder()
			register()
		default:
			return true // default handling
		}
		return false // custom handling
	}
}

extension RegisterViewController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		VerticalSlideTransitionAnimator(shouldMoveDown: false)
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		VerticalSlideTransitionAnimator(shouldMoveDown: true)
	}
}

fileprivate final class VerticalSlideTransitionAnimator: TransitionAnimator {
	let shouldMoveDown: Bool
	
	init(shouldMoveDown: Bool) {
		self.shouldMoveDown = shouldMoveDown
		
		super.init()
	}
	
	override func animateTransition(using transitionContext: Context) {
		let fromView = transitionContext.viewController(forKey: .from)!.view!
		let toView = transitionContext.viewController(forKey: .to)!.view!
		
		transitionContext.containerView.addSubview(toView)
		let bounds = transitionContext.containerView.bounds
		let offset = bounds.height * (shouldMoveDown ? -1 : +1)
		
		toView.frame = bounds.offsetBy(dx: 0, dy: offset)
		
		animate(using: transitionContext) { 
			fromView.frame = bounds.offsetBy(dx: 0, dy: -offset)
			toView.frame = bounds
		}
	}
}
