// Created by Julian Dunskus

import Foundation
import Promise

private struct FileDownloadRequest: GetDataRequest {
	var path: String
	
	var size: String? = "full"
	
	init(file: AnyFile) {
		path = file.urlPath
	}
	
	func collectURLQueryItems() -> [(String, Any)] {
		if let size = size {
			("size", size)
		}
	}
}

extension Client {
	/// limit max concurrent file downloads
	/// (otherwise we start getting overrun with timeouts, though URLSession automatically limits concurrent connections per host)
	private static let downloadLimiter = ConcurrencyLimiter(label: "file download", maxConcurrency: 3)
	
	// TODO: cancel requests if already downloaded?
	
	func download(_ file: AnyFile) -> Future<Data> {
		Self.downloadLimiter.dispatch {
			self.send(FileDownloadRequest(file: file))
		}
	}
}
