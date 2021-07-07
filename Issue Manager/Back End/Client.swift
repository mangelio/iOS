// Created by Julian Dunskus

import Foundation
import Promise
import UserDefault

typealias TaskResult = (data: Data, response: HTTPURLResponse)

final class Client {
	static let shared = Client()
	static let dateFormatter = ISO8601DateFormatter()
	
	private static let baseServerURL = URL(string: "https://app.baupen.ch")!
	
	@UserDefault("client.loginInfo") var loginInfo: LoginInfo?
	
	/// the user we're currently logged in as
	@UserDefault("client.localUser") var localUser: ConstructionManager?
	
	var isLoggedIn: Bool { loginInfo != nil && localUser != nil }
	
	private let urlSession = URLSession.shared
	
	private let requestEncoder = JSONEncoder() <- {
		$0.dateEncodingStrategy = .iso8601
	}
	private let responseDecoder = JSONDecoder() <- {
		$0.dateDecodingStrategy = .iso8601
	}
	
	/// any dependent requests are executed on this queue, so as to avoid bad interleavings and races and such
	private let linearQueue = DispatchQueue(label: "dependent request execution")
	
	func assertOnLinearQueue() {
		dispatchPrecondition(condition: .onQueue(linearQueue))
	}
	
	private init() {}
	
	func wipeAllData() {
		loginInfo = nil
		localUser = nil
	}
	
	func send<R: Request>(_ request: R) -> Future<R.Response> {
		Future { try urlRequest(for: request) }
			.flatMap { rawRequest in
				let bodyDesc = rawRequest.httpBody
					.map { "\"\(debugRepresentation(of: $0))\"" }
					?? "request without body"
				print("\(request.path): \(rawRequest.httpMethod!)ing \(bodyDesc) to \(rawRequest.url!)")
				
				return self.send(rawRequest)
					.catch { _ in print("\(request.path): failed!") }
			}
			.map { try self.extractData(from: $0, for: request) }
	}
	
	func pushChangesThen<T>(perform task: @escaping () throws -> T) -> Future<T> {
		Future(asyncOn: linearQueue) {
			let errors = self.synchronouslyPushLocalChanges()
			guard errors.isEmpty else {
				throw RequestError.pushFailed(errors)
			}
			return try task()
		}
	}
	
	private func extractData<R: Request>(from taskResult: TaskResult, for request: R) throws -> R.Response {
		let (data, response) = taskResult
		print("\(request.path): status code: \(response.statusCode), body: \(debugRepresentation(of: data))")
		
		switch response.statusCode {
		case 200..<300:
			return try request.decode(from: data, using: responseDecoder)
		case 401:
			throw RequestError.notAuthenticated
		case let statusCode:
			var hydraError: HydraError?
			if
				response.contentType?.hasPrefix("application/ld+json") == true,
				let metadata = try? responseDecoder.decode(HydraMetadata.self, from: data),
				metadata.type == HydraError.type
			{
				hydraError = try? responseDecoder.decode(from: data)
			}
			throw RequestError.apiError(hydraError, statusCode: statusCode)
		}
	}
	
	private func urlRequest<R: Request>(for request: R) throws -> URLRequest {
		try URLRequest(url: apiURL(for: request)) <- { rawRequest in
			rawRequest.httpMethod = R.httpMethod
			try request.encode(using: requestEncoder, into: &rawRequest)
			if let token = loginInfo?.token {
				rawRequest.setValue(token, forHTTPHeaderField: "X-Authentication")
			}
			if let contentType = R.contentType {
				rawRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
			}
		}
	}
	
	private func apiURL<R: Request>(for request: R) -> URL {
		(URLComponents(
			url: request.baseURLOverride ?? loginInfo?.origin ?? Self.baseServerURL,
			resolvingAgainstBaseURL: false
		)! <- {
			$0.percentEncodedPath += request.path
			$0.queryItems = request.collectURLQueryItems()
				.map { URLQueryItem(name: $0, value: "\($1)") }
				.nonEmptyOptional
		}).url!
	}
	
	private func send(_ request: URLRequest) -> Future<TaskResult> {
		urlSession.dataTask(with: request)
			.transformError { _, error in throw RequestError.communicationError(error) }
	}
}

extension HTTPURLResponse {
	var contentType: String? {
		allHeaderFields["Content-Type"] as? String
	}
}

/// An error that occurs while interfacing with the server.
enum RequestError: Error {
	/// You tried to do something that requires authentication without being authenticated.
	case notAuthenticated
	/// An error occurred during communication with the server. Likely causes include an unstable internet connection and the server being down.
	case communicationError(Error)
	/// There was an error fulfilling the request.
	case apiError(HydraError? = nil, statusCode: Int)
	/// The client was unable to push local changes. This should succeed before any remote changes are pulled.
	case pushFailed([IssuePushError])
	/// The client is outdated, so we'd rather not risk further communication.
	// TODO: reimplement outdated client logic
}

fileprivate func debugRepresentation(of data: Data, maxLength: Int = 5000) -> String {
	guard data.count <= maxLength else { return "<\(data.count) bytes>" }
	
	return String(bytes: data, encoding: .utf8)?
		.replacingOccurrences(of: "\n", with: "\\n")
		.replacingOccurrences(of: "\r", with: "\\r")
		?? "<\(data.count) bytes not UTF-8 decodable data>"
}

extension LoginInfo: DefaultsValueConvertible {}
extension ConstructionManager: DefaultsValueConvertible {}
