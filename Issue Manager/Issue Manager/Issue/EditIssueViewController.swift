// Created by Julian Dunskus

import UIKit
import GRDB

final class EditIssueNavigationController: UINavigationController {
	var editIssueController: EditIssueViewController {
		topViewController as! EditIssueViewController
	}
}

final class EditIssueViewController: UITableViewController, Reusable {
	typealias Localization = L10n.ViewIssue
	
	@IBOutlet private var markButton: UIButton!
	
	@IBOutlet private var imageView: UIImageView!
	@IBOutlet private var cameraContainerView: CameraContainerView!
	@IBOutlet private var cameraView: CameraView!
	@IBOutlet private var markupLabel: UILabel!
	@IBOutlet private var cameraControlHintView: UIView!
	
	@IBOutlet private var craftsmanTradeLabel: UILabel!
	@IBOutlet private var craftsmanNameLabel: UILabel!
	
	@IBOutlet private var descriptionCell: UITableViewCell!
	@IBOutlet private var descriptionField: UITextField!
	@IBOutlet private var suggestionsHeight: NSLayoutConstraint!
	@IBOutlet private var suggestionsTableView: UITableView!
	
	@IBAction func markIssue() {
		isIssueMarked.toggle()
		Haptics.mediumImpact.impactOccurred()
	}
	
	@IBAction func descriptionBeganEditing() {
		// make suggestions visible
		let indexPath = tableView.indexPath(for: descriptionCell)!
		// after the table view scrolls by itself
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [tableView] in
			tableView!.scrollToRow(at: indexPath, at: .top, animated: true)
		}
	}
	
	@IBAction func descriptionChanged() {
		suggestionsHandler.currentDescription = descriptionField.text
	}
	
	@IBAction func removeImage() {
		imageFile = nil
	}
	
	@IBAction func openImagePicker(_ sender: UIView) {
		guard let picker = cameraView.prepareImagePicker(for: .photoLibrary) else {
			showAlert(
				titled: Localization.CouldNotOpenLibrary.title,
				message: Localization.CouldNotOpenLibrary.message
			)
			return
		}
		picker.modalPresentationStyle = .popover
		let popover = picker.popoverPresentationController!
		popover.sourceView = sender
		popover.sourceRect = sender.bounds
		present(picker, animated: true)
	}
	
	@IBAction func retryCamera() {
		cameraView.configure()
	}
	
	// the markup editor's buttons link to this
	@IBAction func backToIssueEditor(_ segue: UIStoryboardSegue) {}
	
	var isCreating = false
	
	private var issue: Issue!
	private var original: Issue?
	private var site: ConstructionSite!
	
	private var isIssueMarked = false {
		didSet {
			guard isViewLoaded else { return }
			
			markButton.setImage(isIssueMarked ? #imageLiteral(resourceName: "mark_marked.pdf") : #imageLiteral(resourceName: "mark_unmarked.pdf"), for: .normal)
		}
	}
	
	private var trade: String? {
		didSet {
			craftsmanTradeLabel.setText(to: trade, fallback: Localization.noTrade)
			suggestionsHandler.trade = trade
			
			if trade != craftsman?.trade {
				let options = possibleCraftsmen()
				if trade != nil, options.count == 1 {
					craftsman = options.first
				} else {
					craftsman = nil
				}
			}
		}
	}
	
	private var craftsman: Craftsman? {
		didSet {
			craftsmanNameLabel.setText(to: craftsman?.name, fallback: L10n.Issue.noCraftsman)
			
			if let craftsman = craftsman, craftsman.trade != trade {
				trade = craftsman.trade
			}
		}
	}
	
	private var imageFile: File<Issue>? {
		didSet {
			loadedImage = imageFile.flatMap {
				nil
					?? UIImage(contentsOfFile: Issue.cacheURL(for: $0).path)
					?? UIImage(contentsOfFile: Issue.localURL(for: $0).path)
			}
		}
	}
	
	private var loadedImage: UIImage? {
		didSet {
			imageView.image = loadedImage
			cameraContainerView.isHidden = loadedImage != nil
			markupLabel.isEnabled = loadedImage != nil
		}
	}
	
	private var suggestionsHandler = SuggestionsHandler()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		suggestionsHeight.constant = SuggestionsHandler.intrinsicHeight
		suggestionsHandler.tableView = suggestionsTableView
		suggestionsHandler.delegate = self
		
		cameraView.delegate = self
		
		cameraControlHintView.isHidden = defaults.hasTakenPhoto
		
		update()
		
		if #available(iOS 13.0, *) {
			isModalInPresentation = true // don't just dismiss
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		tableView.reloadData()
	}
	
	func present(_ issue: Issue) {
		self.issue = issue
		original = issue
		update()
	}
	
	func store(_ image: UIImage) {
		let file = File<Issue>(filename: "\(UUID()).jpg")
		
		let url = Issue.localURL(for: file)
		do {
			try image.saveJPEG(to: url)
			imageFile = file
		} catch {
			showAlert(titled: Localization.CouldNotSaveImage.title, message: error.localizedFailureReason)
			imageFile = nil
		}
	}
	
	// only call this when absolutely necessary; overwrites content in text fields
	private func update() {
		assert(issue.isRegistered != true)
		guard isViewLoaded else { return }
		
		site = Repository.read(issue.site.fetchOne)!
		
		navigationItem.title = isCreating ? Localization.titleCreating : Localization.titleEditing
		
		isIssueMarked = issue.isMarked
		
		craftsman = Repository.read(issue.craftsman)
		trade = craftsman?.trade
		
		descriptionField.text = issue.description
		descriptionChanged()
		
		imageFile = issue.image
	}
	
	private func save() {
		func update(_ details: inout Issue.Details) {
			details.isMarked = isIssueMarked
			details.craftsman = craftsman?.id
			details.description = descriptionField.text
			details.image = imageFile
		}
		
		if isCreating {
			issue.create(transform: update)
		} else {
			issue.change(transform: update)
		}
		
		let originalTrade = (original?.craftsman).flatMap(Repository.shared.read)?.trade
		if trade != originalTrade || issue.description != original?.description {
			SuggestionStorage.shared.decrementSuggestion(
				description: original?.description,
				forTrade: originalTrade
			)
			SuggestionStorage.shared.used(
				description: issue.description,
				forTrade: trade
			)
		}
	}
	
	func possibleCraftsmen() -> [Craftsman] {
		let request = site.craftsmen <- {
			if let trade = trade {
				$0 = $0.filter(Craftsman.Columns.trade == trade)
			}
			$0 = $0.order(Craftsman.Columns.name)
		}
		return Repository.read(request.fetchAll)
	}
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		switch identifier {
		case "lightbox", "markup":
			return loadedImage != nil
		default:
			return true
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "cancel":
			break
		case "save":
			save()
		case "delete":
			Repository.shared.remove(issue)
		case "lightbox":
			let lightboxController = segue.destination as! LightboxViewController
			lightboxController.image = loadedImage!
			lightboxController.sourceView = imageView
		case "markup":
			let markupNavController = segue.destination as! MarkupNavigationController
			markupNavController.markupController.image = loadedImage!
		case "select trade":
			let selectionController = segue.destination as! SelectionViewController
			selectionController.handler = TradeSelectionHandler(
				in: site,
				currentTrade: trade
			) { self.trade = $0 }.wrapped()
		case "select craftsman":
			let selectionController = segue.destination as! SelectionViewController
			selectionController.handler = CraftsmanSelectionHandler(
				options: possibleCraftsmen(),
				trade: trade,
				current: craftsman
			) { self.craftsman = $0 }.wrapped()
		default:
			fatalError("unrecognized segue named \(segue.identifier ?? "<no identifier>")")
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		isCreating ? 4 : 5 // can't delete issue when creating
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		// can't localize from storyboard
		switch section {
		case 0: return nil
		case 1: return Localization.image
		case 2: return Localization.craftsman
		case 3: return Localization.description
		case 4: return Localization.actions
		default: fatalError("unrecognized section \(section)!")
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		UITableView.automaticDimension
	}
}

extension EditIssueViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return false
	}
}

extension EditIssueViewController: SuggestionsHandlerDelegate {
	func use(_ suggestion: Suggestion) {
		descriptionField.text = suggestion.text
	}
}

extension EditIssueViewController: CameraViewDelegate {
	func cameraFailed(with error: Error) {
		showAlert(titled: Localization.couldNotActivateCamera, message: error.localizedFailureReason)
	}
	
	func pictureFailed(with error: Error) {
		showAlert(titled: Localization.CouldNotTakePicture.title, message: error.localizedFailureReason)
	}
	
	func pictureTaken(_ image: UIImage) {
		defaults.hasTakenPhoto = true
		cameraControlHintView.isHidden = true
		store(image)
	}
	
	func pictureSelected(_ image: UIImage) {
		store(image)
	}
}

extension UIImage {
	func saveJPEG(to url: URL) throws {
		guard let jpg = jpegData(compressionQuality: 0.75) else {
			throw ImageSavingError.couldNotGenerateRepresentation
		}
		print("Saving file to", url)
		try jpg.write(to: url)
	}
}

enum ImageSavingError: Error {
	case couldNotGenerateRepresentation
	
	var localizedDescription: String { // """localized"""
		switch self {
		case .couldNotGenerateRepresentation:
			return "Could not generate JPEG representation for image!"
		}
	}
}

@IBDesignable
final class ImageControlButton: UIButton {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		layer.shadowColor = UIColor.main.cgColor
		layer.shadowOpacity = 0.75
		layer.shadowOffset = CGSize(width: 0, height: 1)
		layer.shadowRadius = 4
	}
}
