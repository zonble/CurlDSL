import XCTest
import Combine
@testable import CurlDSL

final class CurlDSLTests: XCTestCase {

	func testFB() {
		let exp = self.expectation(description: "FB")
		do {

		let c = try CURL("curl -X POST \"https://graph.facebook.com/4?fields=id,name&access_token=EAAClKuzpQyQBAETe39Fry4buuom6WH2eFI4hgyuFZBW0NE8zzmLwj0jskQdK0zAK3W7kuqoKmdK5nGImq5VosqNz1uKnBBHr75SLa3M488KEtzc4dWbAgKXnCy1j9ZBKZBiw5yzCGDILvAUPnlAsdBTZAZCZCKEb9eGCgOoFuiFxDwJIj0GkeONyMoq2z3rA3SDmKC4R4qugZDZD\"")
			c.run { data, response, error in
				exp.fulfill()
			}
			self.wait(for: [exp], timeout: 3)

		} catch {
		}
	}

	func testInvliadURL() {
		do {
			_ = try CURL("curl taliyugatalimba")
			XCTFail()
		} catch ParserError.invalidURL {
		} catch {
			XCTFail()
		}
	}

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

	func testAuth1() {
		let exp = self.expectation(description: "POST")
		do {
			let curl = try CURL("curl --user=user:password -X GET \"https://httpbin.org/basic-auth/user/password\" -H \"Accept: application/json\"")
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
			XCTFail("\(error)")
		}
	}

	func testAuth2() {
		let exp = self.expectation(description: "POST")
		do {
			let curl = try CURL("curl -X GET \"https://user:password@httpbin.org/basic-auth/user/password\" -H \"Accept: application/json\"")
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
			XCTFail("\(error)")
		}
	}

	func testAuth3() {
		let exp = self.expectation(description: "POST")
		do {
			let curl = try CURL("curl -u user:password -X GET \"https://httpbin.org/basic-auth/user/password\" -H \"Accept: application/json\"")
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
			let curl = try CURL("curl -e http://zonble.net -F k=v -X POST -H \"Accept: application/json\" https://httpbin.org/post")
			let handler = JsonDictionaryHandler { result in
				exp.fulfill()
				switch result {
				case .success(let dict):
					XCTAssert((dict["form"] as? [AnyHashable:Any])?["k"] as? String == "v")
					XCTAssert((dict["headers"] as? [AnyHashable:Any])?["Referer"] as? String == "http://zonble.net")
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

	func testPOST2() {
		let exp = self.expectation(description: "POST")
		do {
			let curl = try CURL("curl -F message=\" I like it \" -X POST -H \"Accept: application/json\" https://httpbin.org/post")
			let handler = JsonDictionaryHandler { result in
				exp.fulfill()
				switch result {
				case .success(let dict):
					XCTAssert((dict["form"] as? [AnyHashable:Any])?["message"] as? String == " I like it ", "\(String(describing: dict["form"]))")
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

	func testPOST3() {
		let exp = self.expectation(description: "POST")
		do {
			let curl = try CURL("curl --form=message=\" I like it \" -X POST --header=\"Accept: application/json\" https://httpbin.org/post")
			let handler = JsonDictionaryHandler { result in
				exp.fulfill()
				switch result {
				case .success(let dict):
					XCTAssert((dict["form"] as? [AnyHashable:Any])?["message"] as? String == " I like it ", "\(String(describing: dict["form"]))")
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
			let curl = try CURL(#"curl -d "{ \"k\"=\"v\" }" -H "Content-Type: application/json" -X POST -H "Accept: application/json" https://httpbin.org/post"#)
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

	func testPOSTJson2() {
		let exp = self.expectation(description: "POST")
		do {
			let curl = try CURL(
#"""
curl -d "{
\"k\"=\"v\"
}"
-H "Content-Type: application/json"
-H "Accept: application/json"
-A CurlDSL
"https://httpbin.org/post"
"""#)
			let handler = JsonDictionaryHandler { result in
				exp.fulfill()
				switch result {
				case .success(let dict):
					XCTAssertTrue(dict["data"] as? String ==
"""
{
\"k\"=\"v\"
}
"""
						, dict["data"] as? String ?? "")
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
