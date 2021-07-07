// Created by Julian Dunskus

import UIKit
import GRDB
import Promise
import UserDefault

final class EditIssueNavigationController: UINavigationController {
	var editIssueController: EditIssueViewController {
		topViewController as! EditIssueViewController
	}
}

final class EditIssueViewController: UITableViewController, InstantiableViewController {
	typealias Localization = L10n.ViewIssue
	
	static let storyboardName = "Edit Issue"
	
	@IBOutlet private var numberLabel: UILabel!
	@IBOutlet private var markButton: UIButton!
	
	@IBOutlet private var noImageLabel: UILabel!
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
		issue.isMarked.toggle()
		Haptics.mediumImpact.impactOccurred()
	}
	
	@IBAction func descriptionBeganEditing() {
		// make suggestions visible
		guard let indexPath = tableView.indexPath(for: descriptionCell)
			else { return } // description cell not visible; not sure how this could happen but we shouldn't rely on it
		// after the table view scrolls by itself
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [tableView] in
			tableView!.scrollToRow(at: indexPath, at: .top, animated: true)
		}
	}
	
	@IBAction func descriptionChanged() {
		suggestionsHandler.currentDescription = descriptionField.text
		issue.description = descriptionField.text
	}
	
	@IBAction func removeImage() {
		issue.image = nil
	}
	
	@IBAction func openCamera(_ sender: UIView) {
		guard let picker = cameraView.prepareImagePicker(for: .camera) else {
			showAlert(titled: Localization.couldNotActivateCamera)
			return
		}
		present(picker, animated: true)
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
		picker.popoverPresentationController! <- {
			$0.sourceView = sender
			$0.sourceRect = sender.bounds
		}
		present(picker, animated: true)
	}
	
	@IBAction func retryCamera() {
		cameraView.configure()
	}
	
	// the markup editor's buttons link to this
	@IBAction func backToIssueEditor(_ segue: UIStoryboardSegue) {}
	
	var isCreating = false
	
	private var issue: Issue! {
		didSet {
			guard issue != oldValue else { return }
			update()
		}
	}
	private var original: Issue?
	private var site: ConstructionSite!
	
	private var trade: String? {
		didSet {
			craftsmanTradeLabel.setText(to: trade, fallback: Localization.noTrade)
			suggestionsHandler.trade = trade
			
			if trade != craftsman?.trade {
				let options = possibleCraftsmen()
				if trade != nil, options.count == 1 {
					issue.craftsmanID = options.first!.id
				} else {
					issue.craftsmanID = nil
				}
			}
		}
	}
	
	private var craftsman: Craftsman?
	
	private var loadedImage: UIImage? {
		didSet {
			imageView.image = loadedImage
			noImageLabel.isHidden = loadedImage != nil
			cameraContainerView.isHidden = loadedImage != nil
			markupLabel.isEnabled = loadedImage != nil
		}
	}
	
	private var suggestionsHandler = SuggestionsHandler()
	
	@UserDefault("hasTakenPhoto") private var hasTakenPhoto = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		suggestionsHeight.constant = SuggestionsHandler.intrinsicHeight
		suggestionsHandler.tableView = suggestionsTableView
		suggestionsHandler.delegate = self
		
		cameraView.delegate = self
		
		cameraControlHintView.isHidden = hasTakenPhoto
		
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
		let file = File<Issue>(urlPath: "/local/\(UUID()).jpg")
		
		let url = Issue.localURL(for: file)
		do {
			try image.saveJPEG(to: url)
			issue.image = file
		} catch {
			showAlert(titled: Localization.CouldNotSaveImage.title, message: error.localizedFailureReason)
			issue.image = nil
		}
	}
	
	// only call this when absolutely necessary; overwrites content in text fields
	private func update() {
		assert(issue.isRegistered != true)
		guard isViewLoaded else { return }
		
		site = Repository.read(issue.site.fetchOne)!
		
		navigationItem.title = isCreating ? Localization.titleCreating : Localization.titleEditing
		
		numberLabel.setText(to: issue.number.map { "#\($0)" }, fallback: L10n.Issue.unregistered)
		markButton.setImage(issue.isMarked ? #imageLiteral(resourceName: "mark_marked.pdf") : #imageLiteral(resourceName: "mark_unmarked.pdf"), for: .normal)
		
		craftsman = Repository.read(issue.craftsman)
		craftsmanNameLabel.setText(to: craftsman?.company, fallback: L10n.Issue.noCraftsman)
		trade = craftsman?.trade
		
		if descriptionField.text != issue.description {
			// this also resets the cursor position, which is why it should be conditional
			descriptionField.text = issue.description
		}
		descriptionChanged()
		
		loadedImage = issue.image.flatMap { nil
			?? UIImage(contentsOfFile: Issue.localURL(for: $0).path)
		}
	}
	
	private func onSave() {
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
			$0 = $0.order(Craftsman.Columns.company)
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
			onSave()
			let mapController = segue.destination as! MapViewController
			issue.saveAndSync().then(mapController.updateFromRepository)
		case "delete":
			issue.delete()
			let mapController = segue.destination as! MapViewController
			issue.saveAndSync().then(mapController.updateFromRepository)
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
			) { [unowned self] in self.trade = $0 }.wrapped()
		case "select craftsman":
			let selectionController = segue.destination as! SelectionViewController
			selectionController.handler = CraftsmanSelectionHandler(
				options: possibleCraftsmen(),
				trade: trade,
				current: craftsman
			) { [unowned self] in self.issue.craftsmanID = $0?.id }.wrapped()
		default:
			fatalError("unrecognized segue named \(segue.identifier ?? "<no identifier>")")
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		isCreating ? 3 : 4 // can't delete issue when creating
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		// can't localize from storyboard
		switch section {
		case 0: return nil
		case 1: return Localization.craftsman
		case 2: return Localization.description
		case 3: return Localization.actions
		default: fatalError("unrecognized section \(section)!")
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		section == 0 ? .leastNormalMagnitude : UITableView.automaticDimension
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
		issue.description = suggestion.text
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
		hasTakenPhoto = true
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
		try? FileManager.default.createDirectory(
			at: url.deletingLastPathComponent(),
			withIntermediateDirectories: true
		)
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
