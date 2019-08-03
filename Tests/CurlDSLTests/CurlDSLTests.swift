import XCTest
import Combine
@testable import CurlDSL

final class CurlDSLTests: XCTestCase {
	func testPublisher() {

		let exp = self.expectation(description: "POST")
		do {
			_ = try CURL("curl https://httpbin.org/json").run().receive(on: DispatchQueue.main).sink(receiveCompletion: { error in
				exp.fulfill()
			}, receiveValue: { data, response in
				JsonDictionaryHandler { result in
					switch result {
					case .success(let dict):
						XCTAssertNotNil(dict["slideshow"])
					default:
						break
					}
				}.handle(data, response, nil)
			})
			self.wait(for: [exp], timeout: 10)
		} catch {
			XCTFail()
		}
	}

	func testAuth() {
		let exp = self.expectation(description: "POST")
		do {
			let curl = try CURL("curl -u user:password -X GET \"https://httpbin.org/basic-auth/user/password\" -H \"accept: application/json\"")
			let handler = JsonDictionaryHandler { result in
				exp.fulfill()
				switch result {
				case .success(let dict):
					XCTAssertTrue(dict["user"] as? String == "user")
					XCTAssertTrue(dict["authenticated"] as? Int == 1)
				case .failure(_):
					XCTFail()
				}
			}
			curl.run(handler: handler)
			self.wait(for: [exp], timeout: 10)
		} catch {
			XCTFail()
		}
	}

	func testPOST() {
		let exp = self.expectation(description: "POST")
		do {
			let curl = try CURL("curl -F k=v -X POST -H \"accept: application/json\" https://httpbin.org/post")
			let handler = JsonDictionaryHandler { result in
				exp.fulfill()
				switch result {
				case .success(let dict):
					XCTAssert((dict["form"] as? [AnyHashable:Any])?["k"] as? String == "v")
				case .failure(_):
					XCTFail()
				}
			}
			curl.run(handler: handler)
			self.wait(for: [exp], timeout: 10)
		} catch  {
			XCTFail()
		}
	}

	func testPOST2() {
		let exp = self.expectation(description: "POST")
		do {
			let curl = try CURL("curl -F message=\" I like it \" -X POST -H \"accept: application/json\" https://httpbin.org/post")
			let handler = JsonDictionaryHandler { result in
				exp.fulfill()
				switch result {
				case .success(let dict):
					XCTAssert((dict["form"] as? [AnyHashable:Any])?["message"] as? String == "I like it", "\(String(describing: dict["form"]))")
				case .failure(_):
					XCTFail()
				}
			}
			curl.run(handler: handler)
			self.wait(for: [exp], timeout: 10)
		} catch  {
			XCTFail("\(error)")
		}
	}

	func testPOSTJson() {
		let exp = self.expectation(description: "POST")
		do {
			let curl = try CURL(#"curl -d "{ \"k\"=\"v\" }" -H "Content-Type: application/json" -X POST -H "accept: application/json" https://httpbin.org/post"#)
			let handler = JsonDictionaryHandler { result in
				exp.fulfill()
				switch result {
				case .success(let dict):
					XCTAssertTrue(dict["data"] as? String == #"{ "k"="v" }"#)
				case .failure(_):
					XCTFail()
				}
			}
			curl.run(handler: handler)
			self.wait(for: [exp], timeout: 10)
		} catch  {
			XCTFail("\(error)")
		}
	}

	func testGET() {
		let exp = self.expectation(description: "GET")

		do {
			let curl = try CURL("curl https://httpbin.org/json")
			let handler = JsonDictionaryHandler { result in
				exp.fulfill()
				switch result {
				case .success(let dict):
					XCTAssertNotNil(dict["slideshow"])
				case .failure(_):
					XCTFail()
				}
			}
			curl.run(handler: handler)
			self.wait(for: [exp], timeout: 10)
		} catch  {
			XCTFail("\(error)")
		}
	}

	//    func testExample() {
	//        // This is an example of a functional test case.
	//        // Use XCTAssert and related functions to verify your tests produce the correct
	//        // results.
	//        XCTAssertEqual(CurlDSL().text, "Hello, World!")
	//    }
	//
	//    static var allTests = [
	//        ("testExample", testExample),
	//    ]
}
