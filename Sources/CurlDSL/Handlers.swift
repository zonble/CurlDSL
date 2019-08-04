import Foundation

public typealias Callback<T> = (Result<T, Error>) -> ()

public enum HandlerError: Error {
	case noData
	case invalidFormat
}

public class Handler<T> {
	var callback: Callback<T>

	public init(_ callback: @escaping Callback<T>) {
		self.callback = callback
	}

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
