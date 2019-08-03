import Foundation

public typealias Callback<T> = (Result<T, Error>)->()

public enum HandlerError: Error {
	case noData
	case invalidFormat
}

public class Handler<T> {
	var callback: Callback<T>
	public init(_ callback:@escaping Callback<T>) {
		self.callback = callback
	}
	public func handle(_: Data?, _: URLResponse?, _: Error?) {
		fatalError("Not implemented")
	}
}

public class CodableHandler<T:Codable>: Handler<T> {
	public var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
	public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
	public var dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .deferredToData
	public var nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy = .throw

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

public class DataHandler: Handler <Data> {
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

public class JsonDictionaryHandler: Handler <[AnyHashable:Any]> {
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
			if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable:Any] {
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
