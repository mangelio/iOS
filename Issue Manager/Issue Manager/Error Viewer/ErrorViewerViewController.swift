// Created by Julian Dunskus

import UIKit

final class ErrorViewerNavigationController: UINavigationController {
	var errorViewerController: ErrorViewerViewController {
		topViewController as! ErrorViewerViewController
	}
}

extension ErrorViewerNavigationController: InstantiableViewController {
	static let storyboardName = "Error Viewer"
}

final class ErrorViewerViewController: UIViewController {
	private typealias Localization = L10n.ErrorViewer
	
	@IBOutlet private var errorDescriptionLabel: UILabel!
	@IBOutlet private var resolveButton: UIButton!
	
	@IBAction func close(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func resolve() {
		resolveHandler?()
	}
	
	private var resolveHandler: (() -> Void)?
	
	var error: Error? = nil {
		didSet { update() }
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		update()
	}
	
	private func update() {
		guard isViewLoaded, let error = error else { return }
		
		errorDescriptionLabel.attributedText = .init(
			string: description(for: error),
			attributes: [
				.paragraphStyle: NSMutableParagraphStyle()
					<- { $0.lineHeightMultiple = 1.2 }
			]
		)
		
		let (text, handler) = resolveCommand(for: error)
		resolveButton.setTitle(text, for: .normal)
		resolveHandler = handler
	}
	
	private func description(for error: Error) -> String {
		switch error {
		case RequestError.pushFailed(let errors):
			return Localization.PushFailed.message(
				errors
					.map(\.quickIssueIdentifier)
					.map { "• \($0)" }
					.joined(separator: "\n"),
				errors
					.map(\.description)
					.joined(separator: "\n\n")
			)
		case let error:
			return Localization.UnknownError.message("" <- { dump(error, to: &$0) })
		}
	}
	
	private func resolveCommand(for error: Error) -> (text: String, handler: () -> Void) {
		switch error {
		case RequestError.pushFailed(let errors):
			typealias L = Localization.PushFailed
			return (L.discardChanges, { [unowned self] in
				errors.forEach { error in
					if error.issue.wasUploaded, case .patch = error.stage {
						Repository.shared.save(error.issue <- { $0.discardChangePatch() })
					} else {
						// the only way we could lose something here is if an uploaded issue was changed along with its image, which would have been blocked be the former.
						// we already handle this case above though.
						Repository.shared.remove(error.issue)
					}
				}
				self.showAlert(
					titled: L.ChangesDiscarded.title,
					message: L.ChangesDiscarded.message
				) {
					self.dismiss(animated: true)
				}
			})
		default:
			typealias L = Localization.WipeAllData
			return (L.button, { [unowned self] in
				let sheet = UIAlertController(
					title: L.warning,
					message: nil,
					preferredStyle: .actionSheet
				) <- {
					$0.addAction(.init(
						title: L.cancel,
						style: .cancel
					))
					$0.addAction(.init(
						title: L.confirm,
						style: .destructive
					) { _ in
						AppDelegate.shared.wipeAllDataThenExit()
					})
				}
				self.presentOnTop(sheet)
			})
		}
	}
}

extension IssuePushError {
	var quickIssueIdentifier: String {
		issueIdentifier(isAdvanced: false)
	}
	
	var advancedIssueIdentifier: String {
		issueIdentifier(isAdvanced: true)
	}
	
	private func issueIdentifier(isAdvanced: Bool) -> String {
		[String].init {
			if issue.wasUploaded, case .patch = stage {
				L10n.ErrorViewer.PushFailed.Stage.create
			} else {
				stage.description
			}
			
			issue.number.map { "#\($0)" }
			
			if let description = issue.description?.nonEmptyOptional {
				let maxDescLength = 50
				if isAdvanced || description.count <= maxDescLength {
					description
				} else {
					String(description.prefix(maxDescLength))
				}
			}
			
			if isAdvanced {
				issue.rawID
			}
		}.joined(separator: " – ")
	}
	
	var description: String {
		"""
		\(advancedIssueIdentifier):
		\("" <- { dump(cause, to: &$0) })
		"""
	}
}

extension IssuePushError.Stage {
	var description: String {
		typealias L = L10n.ErrorViewer.PushFailed.Stage
		switch self {
		case .patch:
			return L.patch
		case .imageUpload:
			return L.imageUpload
		case .deletion:
			return L.deletion
		}
	}
}
