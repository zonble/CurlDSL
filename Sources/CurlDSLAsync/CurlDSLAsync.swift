import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import CurlDSL

/// Errors that can occur when executing a cURL command asynchronously.
public enum CURLError: Error, LocalizedError, Sendable {
    /// Indicates that the response contained no data.
    case noData

    public var errorDescription: String? {
        switch self {
        case .noData:
            return "No data was fetched from the response."
        }
    }
}


extension CURL {
    /// Executes the fetch command asynchronously and returns the raw response
    /// data.
    ///
    /// - Returns: The `Data` retrieved from the request.
    /// - Throws: An error if the network request fails, or `CURLError.noData`
    ///   if the response contains no data.
    @available(iOS 15.0.0, macOS 12.0.0, *)
    public func run() async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            self.run { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data = data else {
                    continuation.resume(throwing: CURLError.noData)
                    return
                }
                continuation.resume(returning: data)
            }
        }
    }

    /// Executes the fetch command asynchronously and processes the response
    /// using the specified handler type.
    ///
    /// - Parameter handlerType: A subclass of `Handler` used to process the
    ///   response data (e.g., `JsonDictionaryHandler.self`).
    /// - Returns: The processed result of type `T`, as determined by the
    ///   provided handler.
    /// - Throws: An error if the network request or the handler's processing
    ///   fails.
    @available(iOS 15.0.0, macOS 12.0.0, *)
    public func run<T>(_ handlerType: Handler<T>.Type) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            let handler = handlerType.init { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            self.run(handler: handler)
        }
    }

}
