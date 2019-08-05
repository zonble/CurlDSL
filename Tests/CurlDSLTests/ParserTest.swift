import XCTest
@testable import CurlDSL

final class LexerptionsTests: XCTestCase {

	func testFull1() {
		let str = "curl --form=message=\" I like it \" -X POST --header=\"Accept: application/json\" https://httpbin.org/post"
		let result = Lexer.tokenize(str)
		do {
			let options = try Lexer.convertTokensToOptions(result)
			switch options[0] {
			case .form(let key, let value):
				XCTAssert(key == "message")
				XCTAssert(value == " I like it ")
			default:
				XCTFail()
			}
			switch options[1] {
			case .requestMethod(let method):
				XCTAssert(method == "POST")
			default:
				XCTFail()
			}
			switch options[2] {
			case .header(let key, let value):
				XCTAssert(key == "Accept")
				XCTAssert(value == "application/json", "-\(value)-")
			default:
				XCTFail()
			}
			switch options[3] {
			case .url(let url):
				XCTAssert(url == "https://httpbin.org/post")
			default:
				XCTFail()
			}
		} catch {
			XCTFail()
		}
	}

	func testFull2() {
		let str = "curl --referer=\"http://zonble.net\" --request=POST --user-agent=\"CURL 12345\" https://httpbin.org/post"
		let result = Lexer.tokenize(str)
		do {
			let options = try Lexer.convertTokensToOptions(result)
			switch options[0] {
			case .referer(let value):
				XCTAssert(value == "http://zonble.net")
			default:
				XCTFail()
			}
			switch options[1] {
			case .requestMethod(let method):
				XCTAssert(method == "POST")
			default:
				XCTFail()
			}
			switch options[2] {
			case .userAgent(let value):
				XCTAssert(value == "CURL 12345", "-\(value)-")
			default:
				XCTFail()
			}
			switch options[3] {
			case .url(let url):
				XCTAssert(url == "https://httpbin.org/post")
			default:
				XCTFail()
			}
		} catch {
			XCTFail()
		}
	}

	func testOptions1() {
		let str = ""
		let result = Lexer.tokenize(str)
		do {
			_ = try Lexer.convertTokensToOptions(result)
			XCTFail()
		} catch ParserError.invalidBegin {
		} catch {
			XCTFail()
		}
	}

	func testOptions1_1() {
		let str = " curl "
		let result = Lexer.tokenize(str)
		do {
			let tokens = try Lexer.convertTokensToOptions(result)
			XCTFail("\(tokens)")
		} catch ParserError.noURL {
		} catch {
			XCTFail()
		}
	}

	func testOptions2() {
		let str = "curl \"https://kkbox.com\""
		let result = Lexer.tokenize(str)
		do {
			let options = try Lexer.convertTokensToOptions(result)
			switch options[0] {
			case .url(let url):
				XCTAssert(url == "https://kkbox.com")
			default:
				XCTFail()
			}
		} catch {
			XCTFail()
		}
	}

	func testInvalidOption1() {
		let str = "curl -F -F"
		let result = Lexer.tokenize(str)
		do {
			_ = try Lexer.convertTokensToOptions(result)
			XCTFail()
		} catch ParserError.inValidParameter {
		} catch {
			XCTFail()
		}
	}

	func testInvalidOption2() {
		let str = "curl -F"
		let result = Lexer.tokenize(str)
		do {
			_ = try Lexer.convertTokensToOptions(result)
			XCTFail()
		} catch ParserError.inValidParameter {
		} catch {
			XCTFail()
		}
	}

	func testInvalidOption3() {
		let str = "curl --form --form"
		let result = Lexer.tokenize(str)
		do {
			_ = try Lexer.convertTokensToOptions(result)
			XCTFail()
		} catch ParserError.inValidParameter {
		} catch {
			XCTFail()
		}
	}
}

final class LexerTokenizingTests: XCTestCase {
	func testTokenize1() {
		let str = "curl"
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl"])
	}

	func testTokenize2() {
		let str = ""
		let result = Lexer.tokenize(str)
		XCTAssert(result == [])
	}

	func testTokenize3() {
		let str = "  "
		let result = Lexer.tokenize(str)
		XCTAssert(result == [], "\(result)")
	}

	func testTokenize4() {
		let str = "curl http://kkbox.com"
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "http://kkbox.com"])
	}

	func testTokenize5() {
		let str = "curl \"http://kkbox.com\""
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}

	func testTokenize5_1() {
		let str = "curl \'http://kkbox.com\'"
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}

	func testTokenize6() {
		let str = "curl http\"://kkbox.com\""
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}

	func testTokenize6_1() {
		let str = "curl http\'://kkbox.com\'"
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}

	func testTokenize7() {
		let str = "curl http\"  ://kkbox.com  \""
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "http  ://kkbox.com  "], "\(result)")
	}

	func testTokenize7_1() {
		let str = "curl http\'  ://kkbox.com  \'"
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "http  ://kkbox.com  "], "\(result)")
	}

	func testTokenize8() {
		let str = "curl \"  \'http://kkbox.com\'  \""
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "  \'http://kkbox.com\'  "], "\(result)")
	}

	func testTokenize8_1() {
		let str = "curl \'  \"http://kkbox.com\"  \'"
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "  \"http://kkbox.com\"  "], "\(result)")
	}

	func testTokenize9() {
		let str = #"curl -F "{ \"name\"=\"name\" }" "http://kkbox.com""#
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "-F", "{ \"name\"=\"name\" }", "http://kkbox.com"], "\(result)")
	}

	func testTokenize10() {
		let str = #"curl "http://kkbox.com"#
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}

	func testTokenize11() {
		let str = #"curl http://kkbox.com""#
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}

	func testTokenize12() {
		let str = #"curl "http:"//kkbox."com""#
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}

	func testTokenize13() {
		let str = #"curl "ht"tp://kkbox."com""#
		let result = Lexer.tokenize(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}



	//    static var allTests = [
	//        ("testExample", testExample),
	//    ]
}
