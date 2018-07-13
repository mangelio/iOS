// Created by Julian Dunskus

import UIKit

fileprivate let markerSize = CGSize(width: 32, height: 32)

class IssueMarker: UIView {
	var issue: Issue!
	
	var zoomScale: CGFloat = 1 {
		didSet {
			resize()
		}
	}
	
	var buttonAction: (() -> Void)!
	
	private let button = UIButton()
	
	init() {
		super.init(frame: CGRect(origin: .zero, size: markerSize))
		autoresizingMask = [ // keep relative position during superview resize
			.flexibleTopMargin,
			.flexibleBottomMargin,
			.flexibleLeftMargin,
			.flexibleRightMargin,
		]
		
		addSubview(button)
		button.frame = self.bounds
		button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}
	
	@objc func buttonPressed(_ sender: UIButton) {
		buttonAction()
	}
	
	func update() {
		button.setImage(issue.status.simplified.shadedIcon, for: .normal)
		
		reposition()
	}
	
	private func resize() {
		// for some reason the size is rounded to nearest integer values anyway, but the view is off-center if that happens, so it's best to manually round it here.
		bounds.size = markerSize
			.map { max(round($0 / zoomScale), 1) }
	}
	
	private func reposition() {
		if let position = issue.position {
			center.x = superview!.bounds.width * CGFloat(position.x)
			center.y = superview!.bounds.height * CGFloat(position.y)
			isHidden = false
		} else {
			isHidden = true
		}
	}
}
