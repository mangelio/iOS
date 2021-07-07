// Created by Julian Dunskus

import Foundation

enum DeepLink {
	case login(LoginInfo)
	case wipe
	
	var loginInfo: LoginInfo? {
		switch self {
		case .login(let loginInfo):
			return loginInfo
		default:
			return nil
		}
	}
	
	init?(from url: URL) {
		self.init(from: url.absoluteString)
	}
	
	init?(from urlString: String) {
		guard
			let components = URLComponents(string: urlString),
			components.scheme == "mangelio" || components.scheme == "baupen"
		else { return nil }
		
		switch components.host {
		case "login":
			guard
				let queryItems = components.queryItems,
				let payload = queryItems.first(where: { $0.name == "payload" })?.value,
				let rawPayload = Data(base64Encoded: payload),
				let loginInfo = try? JSONDecoder().decode(LoginInfo.self, from: rawPayload)
			else {
				print("malformed custom url: \(urlString)")
				return nil
			}
			self = .login(loginInfo)
		case "wipe":
			self = .wipe
		default:
			print("unrecognized custom url host in \(urlString)")
			return nil
		}
	}
}
