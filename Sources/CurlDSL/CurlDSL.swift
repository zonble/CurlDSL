import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Combine)
import Combine
#endif

/// `CURL` converts a line of curl command into a `URLRequest` object. It helps
/// you to create HTTP clients for your iOS/macOS/tvOS apps easier once you have
/// a example curl command.
///
/// For example. if you want to fetch a file in JSON format from httpbin.org,
/// you can use only one line of Swift code:
///
/// ``` swift
/// try URL("https://httpbin.org/json").run { data, response, error in ... }
/// ```
public struct CURL {
	private var result: ParseResult

	/// Creates a new instance.
	///
	/// Please note that the method throws errors if the syntax is invalid in your
	/// curl command.
	///
	/// - Parameter str: The command in string format.
	public init(_ str: String) throws {
		let paser = Parser(command: str)
		self.result = try paser.parse()
	}

	/// Builds a `URLRequest` object from the given command.
	public func buildRequest() -> URLRequest {
		var request = URLRequest(url: result.url)
		request.httpMethod = result.httpMethod
		for header in result.headers {
			request.addValue(header.value, forHTTPHeaderField: header.key)
		}
		if let data = result.postData {
			request.httpBody = data.data(using: .utf8)
		} else {
			let joined = result.postFields.map { k, v in
				"\(k.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")=\(v.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")"
			}.joined(separator: "&")
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

	/// Runs the fetch command with a callback closure.
	///
	/// - Parameter completionHandler: The callback closure.
	public func run(completionHandler: @escaping (Data?, URLResponse?, Error?) -> ()) {
		let request = self.buildRequest()
		let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
		task.resume()
	}

	/// Runs the fetch command and handles the reponse with a handler object.
	///
	/// The handler should be a subclass of `Handler`.
	///
	/// - Parameter handler: The handler.
	public func run<T>(handler: Handler<T>) {
		let request = self.buildRequest()
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			handler.handle(data, response, error)
		}
		task.resume()
	}

	/// Runs the fetch command and you can receive the response from a
	/// publisher.
	#if canImport(Combine)
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	func run() -> URLSession.DataTaskPublisher {
		let request = self.buildRequest()
		let publisher = URLSession.shared.dataTaskPublisher(for: request)
		return publisher
	}
	#endif
}
