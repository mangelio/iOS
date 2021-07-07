// Created by Julian Dunskus

import Foundation
import ArrayBuilder

/// a request that is encoded as a multipart form
protocol MultipartEncodingRequest: Request, Encodable {
	var fileURL: URL { get }
	
	@ArrayBuilder<MultipartPart>
	var parts: [MultipartPart] { get }
}

private let multipartBoundary = "boundary-\(UUID())-boundary"
extension MultipartEncodingRequest {
	static var httpMethod: String { "POST" }
	static var contentType: String? { "multipart/form-data; charset=utf-8; boundary=\(multipartBoundary)" }
	
	func encode(using encoder: JSONEncoder, into request: inout URLRequest) throws {
		let rawBoundary = "--\(multipartBoundary)\r\n".data(using: .utf8)!
		
		request.httpBody = try parts
			.lazy
			.map { try rawBoundary + $0.makeFormData() }
			.joined()
			+ "--\(multipartBoundary)--\r\n".data(using: .utf8)!
	}
}

struct MultipartPart {
	var name: String
	var content: Content
	
	func makeFormData() throws -> Data {
		let contentHeader: String
		if let header = content.header {
			contentHeader = "; \(header)"
		} else {
			contentHeader = ""
		}
		
		var data = """
			Content-Disposition: form-data; name="\(name)"\(contentHeader)\r
			Content-Type: \(content.type)\r
			\r
			
			""".data(using: .utf8)!
		
		switch content {
		case .json(let jsonData):
			data += jsonData
		case .jpeg(at: let url):
			data += try Data(contentsOf: url)
		}
		
		data += "\r\n".data(using: .utf8)!
		
		return data
	}
	
	enum Content {
		case json(Data)
		case jpeg(at: URL)
		
		var type: String {
			switch self {
			case .json:
				return "application/json"
			case .jpeg:
				return "image/jpeg"
			}
		}
		
		var header: String? {
			switch self {
			case .jpeg(let url):
				return "filename=\(url.lastPathComponent)"
			default:
				return nil
			}
		}
	}
}
