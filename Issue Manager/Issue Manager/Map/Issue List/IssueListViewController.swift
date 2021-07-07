// Created by Julian Dunskus

import UIKit
import PullToExpand

final class IssueListViewController: UIViewController {
	typealias Localization = L10n.Map.IssueList
	
	@IBOutlet private var summaryLabel: UILabel!
	@IBOutlet private var separatorView: UIView!
	@IBOutlet private var issueTableView: UITableView!
	
	/// - note: set this _before_ the list loads its data
	weak var issueCellDelegate: IssueCellDelegate?
	
	var pullableView: PullableView! {
		didSet { pullableView.tapRecognizer.delegate = self }
	}
	
	/// set this before setting `map` initially or before loading the view to avoid calculating stuff twice
	var visibleStatuses = Issue.allStatuses {
		didSet { update() }
	}
	
	var map: Map? {
		didSet { update() }
	}
	
	private var issues: [Issue] = [] {
		didSet { issueTableView.reloadData() }
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		separatorView.backgroundColor = issueTableView.separatorColor
		
		issueTableView.panGestureRecognizer.addTarget(self, action: #selector(listPanned))
		
		update()
		
		scrollViewDidScroll(issueTableView)
	}
	
	func update() {
		guard isViewLoaded, let map = map else { return }
		
		let allIssues = Repository.read(map.sortedIssues.fetchAll)
		issues = allIssues.filter {
			visibleStatuses.contains($0.status.simplified)
		}
		
		let openCount = issues.count { $0.isOpen }
		let totalCount = allIssues.count
		if visibleStatuses == Issue.allStatuses {
			summaryLabel.text = Localization.summary(String(openCount), String(totalCount))
		} else {
			summaryLabel.text = Localization.summaryFiltered(String(issues.count), String(totalCount))
		}
	}
	
	// MARK: PullableView-UIScrollView interaction 
	// close pullable view when scrollview is dragged down while at top
	
	private var pullRecognizer: FakePanRecognizer?
	private var pullDistance: CGFloat = 0
	
	@objc private func listPanned(_ recognizer: UIPanGestureRecognizer) {
		switch recognizer.state {
		case .possible:
			break
		case .began:
			pullRecognizer = nil
			pullDistance = 0
			fallthrough
		case .changed:
			handleScrolling()
		case .ended, .cancelled, .failed:
			handleScrolling()
			if let pullRecognizer = pullRecognizer {
				pullRecognizer.state = recognizer.state // transfer cancelled-/failedness
				// don't love this, but it helps stuff feel smoother without having to implement good logic for velocity calculations
				pullRecognizer.fakeVelocity = recognizer.velocity(in: pullableView.superview!)
				pullableView.viewPulled(pullRecognizer)
			}
		@unknown default:
			break
		}
	}
	
	private func handleScrolling() {
		var contentOffset: CGFloat {
			get { issueTableView.contentOffset.y }
			set { issueTableView.contentOffset.y = newValue }
		}
		
		let minOffset: CGFloat = -20 // if the list is overscrolled past this point, we won't let the user pull it down because it would become jumpy (believe me, i've tried all kinds of approaches)
		// adjust pull offset
		if pullRecognizer == nil, (minOffset...1).contains(contentOffset) {
			// start pulling pullable view
			pullRecognizer = FakePanRecognizer() <- {
				$0.state = .began
				pullableView.viewPulled($0)
				$0.state = .changed
			}
		}
		guard let pullRecognizer = pullRecognizer else { return } // not currently pulling down the view
		
		pullDistance -= contentOffset
		if pullDistance > 0 {
			contentOffset = 0
		} else {
			pullDistance = 0
		}
		
		pullRecognizer.fakeTranslation.y = pullDistance
		pullableView.viewPulled(pullRecognizer)
	}
}

extension IssueListViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		issues.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		tableView.dequeue(IssueCell.self, for: indexPath)! <- {
			$0.delegate = issueCellDelegate
			$0.issue = issues[indexPath.row]
		}
	}
}

extension IssueListViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath == tableView.indexPathForSelectedRow {
			return UITableView.automaticDimension
		} else {
			return 44 // bit of a magic number but eh. also it's the recommended minimum tap target size so ¯\_(ツ)_/¯
		}
	}
	
	// Using willSelect for animations over didSelect because it allows us to do everything during the batch update, rather than having isSelected already set by the table. This makes the animations look a lot nicer. 
	
	func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		let currentSelection = tableView.indexPathForSelectedRow

		// instantly select the cell so `indexPathForSelectedRow` matches up for the height calculations
		tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
		// we don't need to deselect it later because it would be selected anyway, so we're not breaking anything
		
		tableView.performBatchUpdates({
			if let previous = currentSelection {
				tableView.deselectRow(at: previous, animated: true)
			}
			
			tableView.cellForRow(at: indexPath)?.isSelected = true
		}, completion: nil)
		
		return indexPath
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		// scrolling works correctly at this point because the table now knows the cell's actual height
		tableView.scrollToRow(at: indexPath, at: .none, animated: true)
	}
	
	func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
		tableView.performBatchUpdates({
			tableView.deselectRow(at: indexPath, animated: true)
		}, completion: nil)
		
		return indexPath
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if scrollView.contentOffset.y == 0 {
			// block iOS from collapsing the view controller by pretending we're not actually at the top
			scrollView.contentOffset.y = 1
		}
	}
}

extension IssueListViewController: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ recognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		switch recognizer {
		case pullableView.tapRecognizer:
			if let view = touch.view, view.isDescendant(of: issueTableView) {
				return false // don't interfere with taps in table
			} else {
				return true
			}
		default:
			return true
		}
	}
}
