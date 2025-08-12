import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import CurlDSL

public enum CURLError: Error, LocalizedError, Sendable {
    case noData

    var localizedDescription: String {
        get {
            switch self {
            case .noData:
                return "No data fetched"
            }
        }
    }
}


extension CURL {
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
