import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Combine)
import Combine
#endif

/// `CURL` converts a cURL command string into a `URLRequest` object. This makes
/// it easier to build HTTP clients for iOS, macOS, or tvOS applications using
/// example cURL commands.
///
/// For example, if you want to fetch a JSON file from httpbin.org, you can do
/// so with a single line of Swift code:
///
/// ``` swift
/// try CURL("https://httpbin.org/json").run { data, response, error in ... }
/// ```
public struct CURL: Sendable {
	private var result: ParseResult

	/// Initializes a new instance.
	///
	/// Note that this initializer throws an error if the provided cURL command
	/// has invalid syntax.
	///
	/// - Parameter str: The cURL command as a string.
	public init(_ str: String) throws {
		let paser = Parser(command: str)
		self.result = try paser.parse()
	}

	/// Constructs a `URLRequest` object from the parsed cURL command.
	public func buildRequest() -> URLRequest {
		var request = URLRequest(url: result.url)
		request.httpMethod = result.httpMethod
		for header in result.headers {
			request.addValue(header.value, forHTTPHeaderField: header.key)
		}
		if let data = result.postData {
			request.httpBody = data.data(using: .utf8)
		} else if !result.files.isEmpty {
			// Handle multipart/form-data when files are present.
			let boundary = "Boundary-\(UUID().uuidString)"
			request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
			request.httpBody = buildMultipartBody(boundary: boundary, postFields: result.postFields, files: result.files)
		} else if !result.postFields.isEmpty {
			// Handle application/x-www-form-urlencoded for simple form data.
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
	
	/// Constructs a multipart/form-data body for requests containing files or
	/// mixed form data.
	///
	/// - Parameters:
	///   - boundary: The boundary string used to separate parts.
	///   - postFields: The form fields to include.
	///   - files: The files to upload (key-value pairs where the value starts
	///     with @).
	/// - Returns: `Data` representing the multipart body.
	private func buildMultipartBody(boundary: String, postFields: [String: String], files: [String: String]) -> Data {
		var body = Data()
		let boundaryData = "--\(boundary)\r\n".data(using: .utf8)!
		let endBoundaryData = "--\(boundary)--\r\n".data(using: .utf8)!
		
		// Add the form fields.
		for (key, value) in postFields {
			body.append(boundaryData)
			let fieldHeader = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!
			body.append(fieldHeader)
			body.append(value.data(using: .utf8) ?? Data())
			body.append("\r\n".data(using: .utf8)!)
		}
		
		// Add the files.
		for (key, filePath) in files {
			body.append(boundaryData)
			
			// Remove the @ prefix from the file path.
			let actualPath = String(filePath.dropFirst())
			let filename = URL(fileURLWithPath: actualPath).lastPathComponent
			
			let fileHeader = "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!
			body.append(fileHeader)
			
			// Attempt to determine the content type based on the file extension.
			let contentType = mimeType(for: filename)
			let contentTypeHeader = "Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!
			body.append(contentTypeHeader)
			
			// Read the file data.
			if let fileData = try? Data(contentsOf: URL(fileURLWithPath: actualPath)) {
				body.append(fileData)
			} else {
				// If the file cannot be read, append an error placeholder.
				let errorData = "[File not found or unreadable: \(actualPath)]".data(using: .utf8) ?? Data()
				body.append(errorData)
			}
			
			body.append("\r\n".data(using: .utf8)!)
		}
		
		body.append(endBoundaryData)
		return body
	}
	
	/// Determines the MIME type based on a file's extension.
	///
	/// - Parameter filename: The name of the file to evaluate.
	/// - Returns: The corresponding MIME type as a string.
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

	/// Executes the fetch command and returns the result via a callback closure.
	///
	/// - Parameter completionHandler: The closure to call upon completion.
	public func run(completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> ()) {
		let request = self.buildRequest()
		let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
		task.resume()
	}

	/// Executes the fetch command and processes the response using a handler
	/// object.
	///
	/// The handler must be a subclass of `Handler`.
	///
	/// - Parameter handler: The handler.
	public func run<T>(handler: Handler<T>) {
		let request = self.buildRequest()
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			handler.handle(data, response, error)
		}
		task.resume()
	}

	/// Executes the fetch command and returns a publisher that emits the
	/// response.
	#if canImport(Combine)
	func run() -> URLSession.DataTaskPublisher {
		let request = self.buildRequest()
		let publisher = URLSession.shared.dataTaskPublisher(for: request)
		return publisher
	}
	#endif
}
