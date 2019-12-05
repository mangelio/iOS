// Created by Julian Dunskus

import Foundation

struct IssueDeletionRequest: JSONJSONRequest, BacklogStorable {
	static let storageID = "issue deletion"
	
	static let isIndependent = false
	
	var method: String { "issue/delete" }
	
	var authenticationToken: String
	let issueID: ID<Issue>
	
	func applyToClient(_ response: ExpectedResponse) {
		if let issue = Repository.object(issueID) {
			Repository.shared.remove(issue, notifyingServer: false)
		}
	}
	
	struct ExpectedResponse: Response {}
}

extension Client {
	func issueRemoved(_ issue: Issue) {
		let result = getUser()
			.map { user in
				IssueDeletionRequest(
					authenticationToken: user.authenticationToken,
					issueID: issue.id
				)
			}.flatMap(send)
		
		logOutcome(of: result, as: "issue deletion")
	}
}
