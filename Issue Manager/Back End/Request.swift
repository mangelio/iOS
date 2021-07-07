// Created by Julian Dunskus

import Foundation
import ArrayBuilder

/// Conform to one of the more specific protocols rather than this.
protocol Request {
	associatedtype Response
	
	/// The http method the request uses.
	static var httpMethod: String { get }
	/// The content type of the request's body
	static var contentType: String? { get }
	
	var path: String { get }
	/// If non-nil, the client uses this as the base URL rather than its default.
	var baseURLOverride: URL? { get }
	
	@ArrayBuilder<(String, Any)>
	func collectURLQueryItems() -> [(String, Any)]
	
	func encode(using encoder: JSONEncoder, into request: inout URLRequest) throws
	func decode(from data: Data, using decoder: JSONDecoder) throws -> Response
}

extension Request {
	var baseURLOverride: URL? { nil }
	
	func collectURLQueryItems() -> [(String, Any)] { [] }
}

typealias GetJSONRequest = GetRequest & JSONDecodingRequest
typealias GetDataRequest = GetRequest & DataDecodingRequest
typealias JSONJSONRequest = JSONEncodingRequest & JSONDecodingRequest

/// a request that has no body
protocol GetRequest: Request {}

extension GetRequest {
	static var httpMethod: String { "GET" }
	static var contentType: String? { nil }
	
	func encode(using encoder: JSONEncoder, into request: inout URLRequest) throws {}
}

/// a request that is encoded as simple JSON
protocol JSONEncodingRequest: Request {
	associatedtype Body: Encodable
	
	var body: Body { get }
}

extension JSONEncodingRequest where Body == Self, Self: Encodable {
	var body: Self { self }
}

extension JSONEncodingRequest {
	static var httpMethod: String { "POST" }
	static var contentType: String? { "application/json" }
	
	func encode(using encoder: JSONEncoder, into request: inout URLRequest) throws {
		request.httpBody = try encoder.encode(body)
	}
}

protocol StatusCodeRequest: Request where Response == Void {}

extension StatusCodeRequest {
	func decode(from data: Data, using decoder: JSONDecoder) throws -> Response {}
}

/// a request that expects a JSON-decodable response
protocol JSONDecodingRequest: Request where Response: Decodable {}

extension JSONDecodingRequest {
	func decode(from data: Data, using decoder: JSONDecoder) throws -> Response {
		try decoder.decode(from: data)
	}
}

/// a request that expects a binary data response
protocol DataDecodingRequest: Request where Response == Data {}

extension DataDecodingRequest {
	func decode(from data: Data, using decoder: JSONDecoder) throws -> Data { data }
}
