// Created by Julian Dunskus

import UIKit

final class StatusFilterNavigationController: UINavigationController {
	var statusFilterController: StatusFilterViewController {
		topViewController as! StatusFilterViewController
	}
}

final class StatusFilterViewController: UITableViewController {
	typealias Localization = L10n.Map.StatusFilter
	typealias Status = Issue.Status.Simplified
	
	weak var delegate: StatusFilterViewControllerDelegate?
	var selected: Set<Status>!
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int { 1 }
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		Status.allCases.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeue(StatusCell.self, for: indexPath)!
		let status = Status.allCases[indexPath.row]
		
		cell.status = status
		cell.accessoryType = selected.contains(status) ? .checkmark : .none
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		switch selected.count {
		case Status.allCases.count:
			return Localization.allSelected
		case 0:
			return Localization.noneSelected
		default:
			return Localization.someSelected
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let status = Status.allCases[indexPath.row]
		
		selected.formSymmetricDifference([status])
		tableView.reloadData()
		
		delegate?.statusFilterChanged(to: selected)
	}
}

protocol StatusFilterViewControllerDelegate: AnyObject {
	func statusFilterChanged(to newValue: Set<Issue.Status.Simplified>)
}

final class StatusCell: UITableViewCell, Reusable {
	@IBOutlet private var iconView: UIImageView!
	@IBOutlet private var nameLabel: UILabel!
	
	var status: Issue.Status.Simplified! {
		didSet {
			iconView.image = status.flatIcon
			nameLabel.text = status.localizedName.capitalized
		}
	}
}

final class TrilinearImageView: UIImageView {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		layer.minificationFilter = .trilinear
	}
}
