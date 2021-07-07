/*
MIT License
Copyright (c) 2018 Julian Dunskus
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// from https://gist.github.com/juliand665/f7d80fc063b717f745dae35993f0f7ee

import UIKit

protocol Reusable {
	static var reuseID: String { get }
}

extension Reusable where Self: AnyObject {
	static var reuseID: String {
		String(describing: self)
	}
}

extension UITableView {
	func dequeue<Cell>(_ type: Cell.Type, for indexPath: IndexPath) -> Cell? where Cell: Reusable, Cell: UITableViewCell {
		dequeueReusableCell(withIdentifier: Cell.reuseID, for: indexPath) as? Cell
	}
}

extension UICollectionView {
	func dequeue<Cell>(_ type: Cell.Type, for indexPath: IndexPath) -> Cell? where Cell: Reusable, Cell: UICollectionViewCell {
		dequeueReusableCell(withReuseIdentifier: Cell.reuseID, for: indexPath) as? Cell
	}
}

protocol InstantiableViewController: Reusable where Self: UIViewController {
	static var storyboardName: String { get }
}

extension InstantiableViewController {
	static func instantiate() -> Self? {
		UIStoryboard(name: storyboardName, bundle: nil)
			.instantiateViewController(withIdentifier: reuseID) as? Self
	}
}
