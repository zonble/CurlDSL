import Foundation

public struct CURL {
	private var result: ParseResult

	public init(_ str: String) throws {
		let paser = Parser(command: str)
		self.result = try paser.parse()
	}

	public func buildRequest() -> URLRequest {
		var request = URLRequest(url: result.url)
		request.httpMethod = result.httpMethod
		for header in result.headers {
			request.addValue(header.value, forHTTPHeaderField: header.key)
		}
		if let data = result.postData {
			request.httpBody = data.data(using: .utf8)
		}
		else {
			let joined = result.postFields.map { k, v in
				"\(k.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")=\(v.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")"
			}.joined(separator:"&")
			request.httpBody = joined.data(using: .utf8)

			// TODO: handle files and multi-part
		}

		if let user = result.user {
			let loginData = String(format: "%@:%@", user, result.password ?? "").data(using: String.Encoding.utf8)!
			let base64LoginData = loginData.base64EncodedString()
			request.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")
		}
		return request
	}

	public func run(completionHandler: @escaping (Data?, URLResponse?, Error?) -> ()) {
		let request = self.buildRequest()
		let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
		task.resume()
	}

	public func run<T>(handler: Handler<T>) {
		let request = self.buildRequest()
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			handler.handle(data, response, error)
		}
		task.resume()
	}
}
