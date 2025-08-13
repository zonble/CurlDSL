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
public struct CURL: Sendable {
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
		} else if !result.files.isEmpty {
			// Handle multipart/form-data when files are present
			let boundary = "Boundary-\(UUID().uuidString)"
			request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
			request.httpBody = buildMultipartBody(boundary: boundary, postFields: result.postFields, files: result.files)
		} else if !result.postFields.isEmpty {
			// Handle application/x-www-form-urlencoded for simple form data
			request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
			let joined = result.postFields.map { k, v in
				"\(k.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")=\(v.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")"
			}.joined(separator: "&")
			request.httpBody = joined.data(using: .utf8)
		}

		if let user = result.user {
			let loginData = String(format: "%@:%@", user, result.password ?? "").data(using: String.Encoding.utf8)!
			let base64LoginData = loginData.base64EncodedString()
			request.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")
		}
		return request
	}
	
	/// Builds multipart/form-data body for requests containing files or mixed form data.
	///
	/// - Parameters:
	///   - boundary: The boundary string to separate parts
	///   - postFields: Form fields to include
	///   - files: Files to upload (key-value pairs where value starts with @)
	/// - Returns: Data containing the multipart body
	private func buildMultipartBody(boundary: String, postFields: [String: String], files: [String: String]) -> Data {
		var body = Data()
		let boundaryData = "--\(boundary)\r\n".data(using: .utf8)!
		let endBoundaryData = "--\(boundary)--\r\n".data(using: .utf8)!
		
		// Add form fields
		for (key, value) in postFields {
			body.append(boundaryData)
			let fieldHeader = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!
			body.append(fieldHeader)
			body.append(value.data(using: .utf8) ?? Data())
			body.append("\r\n".data(using: .utf8)!)
		}
		
		// Add files
		for (key, filePath) in files {
			body.append(boundaryData)
			
			// Remove the @ prefix from file path
			let actualPath = String(filePath.dropFirst())
			let filename = URL(fileURLWithPath: actualPath).lastPathComponent
			
			let fileHeader = "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!
			body.append(fileHeader)
			
			// Try to determine content type based on file extension
			let contentType = mimeType(for: filename)
			let contentTypeHeader = "Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!
			body.append(contentTypeHeader)
			
			// Read file data
			if let fileData = try? Data(contentsOf: URL(fileURLWithPath: actualPath)) {
				body.append(fileData)
			} else {
				// If file can't be read, append placeholder
				let errorData = "[File not found or unreadable: \(actualPath)]".data(using: .utf8) ?? Data()
				body.append(errorData)
			}
			
			body.append("\r\n".data(using: .utf8)!)
		}
		
		body.append(endBoundaryData)
		return body
	}
	
	/// Determines MIME type based on file extension.
	///
	/// - Parameter filename: The filename to check
	/// - Returns: MIME type string
	private func mimeType(for filename: String) -> String {
		let ext = URL(fileURLWithPath: filename).pathExtension.lowercased()
		switch ext {
		case "jpg", "jpeg":
			return "image/jpeg"
		case "png":
			return "image/png"
		case "gif":
			return "image/gif"
		case "txt":
			return "text/plain"
		case "json":
			return "application/json"
		case "xml":
			return "application/xml"
		case "pdf":
			return "application/pdf"
		case "zip":
			return "application/zip"
		default:
			return "application/octet-stream"
		}
	}

	/// Runs the fetch command with a callback closure.
	///
	/// - Parameter completionHandler: The callback closure.
	public func run(completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> ()) {
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
