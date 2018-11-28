// Created by Julian Dunskus

import UIKit

final class SectorView: UIView {
	let sector: Map.Sector
	let color: UIColor!
	
	weak var delegate: SectorViewDelegate?
	
	private var path: CGPath!
	private var isHighlighted = false {
		didSet { drawingView.alpha = isHighlighted ? 0.8 : 0.3 }
	}
	
	private let drawingView = DrawingView() <- {
		$0.autoresizingMask = .flexibleSize
		$0.isOpaque = false
	}
	
	private let nameLabel = UILabel() <- {
		$0.autoresizingMask = .flexibleSize
		$0.alpha = 0.75
		$0.textAlignment = .center
	}
	
	init(_ sector: Map.Sector) {
		self.sector = sector
		color = sector.color.map(UIColor.init) ?? #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
		
		super.init(frame: .zero)
		autoresizingMask = [.flexibleMargins, .flexibleSize] // keep relative position and size during superview resize
		
		addSubview(drawingView)
		drawingView.drawingBlock = { [unowned self] in self._draw($0) }
		defer { isHighlighted = false } // trigger alpha change
		
		addSubview(nameLabel)
		nameLabel.text = sector.name
		nameLabel.textColor = color
		
		let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
		longPressRecognizer.minimumPressDuration = 0.1
		longPressRecognizer.allowableMovement = 1
		addGestureRecognizer(longPressRecognizer)
		
		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
		tapRecognizer.numberOfTapsRequired = 2
		addGestureRecognizer(tapRecognizer)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}
	
	override func didMoveToSuperview() {
		super.didMoveToSuperview()
		
		if let superview = superview {
			let scaledPoints = sector.points.map { CGPoint($0) * superview.bounds.size }
			path = CGPath.polygon(corners: scaledPoints)
			frame = path.boundingBox
		}
	}
	
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		guard super.point(inside: point, with: event) else { return false }
		
		return path.contains(point + frame.origin)
	}
	
	/// called by `DrawingView`
	func _draw(_ rect: CGRect) {
		let context = UIGraphicsGetCurrentContext()!
		context.translateBy(x: -frame.origin.x, y: -frame.origin.y)
		
		context.setLineWidth(0.005 * superview!.bounds.size.length)
		
		context.setFillColor(color.withAlphaComponent(0.5).cgColor)
		context.setStrokeColor(color.cgColor)
		
		context.addPath(path)
		context.clip()
		
		context.addPath(path)
		context.fillPath()
		
		context.addPath(path)
		context.strokePath()
	}
	
	@objc func handleTap(_ recognizer: UITapGestureRecognizer) {
		delegate?.zoomMap(to: sector)
		self.isHighlighted = true
		UIView.animate(withDuration: 0.3) {
			self.isHighlighted = false
		}
	}
	
	@objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
		let isInside = point(inside: recognizer.location(in: self), with: nil)
		switch recognizer.state {
		case .began:
			isHighlighted = true
		case .changed:
			if isInside != isHighlighted {
				UIView.animate(withDuration: 0.1) {
					self.isHighlighted = isInside
				}
			}
		case .ended:
			if isInside {
				delegate?.zoomMap(to: sector)
			}
			fallthrough
		case .cancelled:
			UIView.animate(withDuration: 0.3) {
				self.isHighlighted = false
			}
		case .failed, .possible:
			break
		}
	}
}

protocol SectorViewDelegate: AnyObject {
	func zoomMap(to sector: Map.Sector)
}
