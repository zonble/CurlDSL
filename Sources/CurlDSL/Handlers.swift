import Foundation

public typealias Callback<T> = (Result<T, Error>) -> ()

/// The errors that could happen during using `Handler` to handle HTTP responses.
public enum HandlerError: Error, LocalizedError {
	/// There is no data in the response.
	case noData
	/// The format of the response is invalid.
	case invalidFormat

	public var errorDescription: String? {
		switch self {
		case .noData:
			return "There is no data in the response."
		case .invalidFormat:
			return "The format of the response is invalid."
		}
	}
}

/// A common interface for handlers that handles HTTP responses.
public class Handler<T> {
	/// The callback block.
    var callback: Callback<T>

	/// Creates a new instance with a callback block.
    required public init(_ callback: @escaping Callback<T>) {
		self.callback = callback
	}

	/// Handles the incoming data. A subclass should override the method.
	public func handle(_: Data?, _: URLResponse?, _: Error?) {
		fatalError("Not implemented")
	}
}

/// A handler that coverts JSON response into cadable objects.
public class CodableHandler<T: Codable>: Handler<T> {
	/// The strategy to use for decoding keys. Defaults to `.useDefaultKeys`.
	public var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
	/// The strategy to use in decoding dates. Defaults to `.deferredToDate`.
	public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
	/// The strategy to use in decoding binary data. Defaults to `.base64`.
	public var dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .base64
	/// The strategy to use in decoding non-conforming numbers. Defaults to `.throw`.
	public var nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy = .throw

	/// :nodoc:
	public override func handle(_ data: Data?, _ response: URLResponse?, _ apiError: Error?) {
		if let apiError = apiError {
			DispatchQueue.main.async {
				self.callback(.failure(apiError))
			}
			return
		}
		guard let data = data else {
			DispatchQueue.main.async {
				self.callback(.failure(HandlerError.noData))
			}
			return
		}
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = keyDecodingStrategy
		decoder.dateDecodingStrategy = dateDecodingStrategy
		decoder.dataDecodingStrategy = dataDecodingStrategy
		decoder.nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy

		do {
			let object = try decoder.decode(T.self, from: data)
			DispatchQueue.main.async {
				self.callback(.success(object))
			}
		} catch {
			DispatchQueue.main.async {
				self.callback(.failure(error))
			}
		}
	}
}

/// A handler that returns the raw data.
public class DataHandler: Handler<Data> {
	/// :nodoc:
	public override func handle(_ data: Data?, _ response: URLResponse?, _ apiError: Error?) {
		if let apiError = apiError {
			DispatchQueue.main.async {
				self.callback(.failure(apiError))
			}
			return
		}
		guard let data = data else {
			DispatchQueue.main.async {
				self.callback(.failure(HandlerError.noData))
			}
			return
		}
		DispatchQueue.main.async {
			self.callback(.success(data))
		}
	}
}

/// A handler that coverts JSON response into a dictionary.
public class JsonDictionaryHandler: Handler<[AnyHashable: Any]> {
	/// :nodoc:
	public override func handle(_ data: Data?, _ response: URLResponse?, _ apiError: Error?) {
		if let apiError = apiError {
			DispatchQueue.main.async {
				self.callback(.failure(apiError))
			}
			return
		}
		guard let data = data else {
			DispatchQueue.main.async {
				self.callback(.failure(HandlerError.noData))
			}
			return
		}
		do {
			if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any] {
				DispatchQueue.main.async {
					self.callback(.success(dict))
				}
			} else {
				DispatchQueue.main.async {
					self.callback(.failure(HandlerError.invalidFormat))
				}
			}
		} catch {
			DispatchQueue.main.async {
				self.callback(.failure(error))
			}
		}
	}
}
