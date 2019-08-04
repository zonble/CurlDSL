import XCTest
@testable import CurlDSL

final class LexerptionsTests: XCTestCase {

	func testOptions1() {
		let str = ""
		let result = Lexer.slice(str)
		let tokens = Lexer.tokenize(result)
		do {
			_ = try Lexer.convertTokensToOptions(tokens)
			XCTFail()
		} catch ParserError.invalidBegin {
		} catch {
			XCTFail()
		}
	}

	func testOptions1_1() {
		let str = " curl "
		let result = Lexer.slice(str)
		let tokens = Lexer.tokenize(result)
		do {
			_ = try Lexer.convertTokensToOptions(tokens)
			XCTFail()
		} catch ParserError.noURL {
		} catch {
			XCTFail()
		}
	}

	func testOptions2() {
		let str = "curl \"https://kkbox.com\""
		let result = Lexer.slice(str)
		let tokens = Lexer.tokenize(result)
		do {
			let options = try Lexer.convertTokensToOptions(tokens)
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
		let result = Lexer.slice(str)
		let tokens = Lexer.tokenize(result)
		do {
			_ = try Lexer.convertTokensToOptions(tokens)
			XCTFail()
		} catch ParserError.inValidParameter {
		} catch {
			XCTFail()
		}
	}

	func testInvalidOption2() {
		let str = "curl -F"
		let result = Lexer.slice(str)
		let tokens = Lexer.tokenize(result)
		do {
			_ = try Lexer.convertTokensToOptions(tokens)
			XCTFail()
		} catch ParserError.inValidParameter {
		} catch {
			XCTFail()
		}
	}

	func testInvalidOption3() {
		let str = "curl --form --form"
		let result = Lexer.slice(str)
		let tokens = Lexer.tokenize(result)
		do {
			_ = try Lexer.convertTokensToOptions(tokens)
			XCTFail()
		} catch ParserError.inValidParameter {
		} catch {
			XCTFail()
		}
	}

}

final class LexerTokenizingTests: XCTestCase {

	func testMultiLines() {
		let str = """
curl
http://kkbox.com
"""
		let result = Lexer.slice(str)
		let tokens = Lexer.tokenize(result)
		switch tokens[0] {
		case Token.commandBegin:
			break
		default:
			XCTFail()
		}
		switch tokens[1] {
		case Token.string(let str):
			XCTAssert(str == "http://kkbox.com")
		default:
			XCTFail()
		}
	}

	func testTokenize1() {
		let str = "curl"
		let result = Lexer.slice(str)
		let tokens = Lexer.tokenize(result)
		switch tokens.first! {
		case Token.commandBegin:
			break
		default:
			XCTFail()
		}
	}

	func testTokenize2() {
		let str = "curl http://kkbox.com"
		let result = Lexer.slice(str)
		let tokens = Lexer.tokenize(result)
		switch tokens[0] {
		case Token.commandBegin:
			break
		default:
			XCTFail()
		}
		switch tokens[1] {
		case Token.string(let str):
			XCTAssert(str == "http://kkbox.com")
		default:
			XCTFail()
		}
	}

	func testTokenize3() {
		let str = "curl -F x=x http://kkbox.com"
		let result = Lexer.slice(str)
		let tokens = Lexer.tokenize(result)
		switch tokens[0] {
		case Token.commandBegin:
			break
		default:
			XCTFail()
		}
		switch tokens[1] {
		case Token.shortCommand(let str):
			XCTAssert(str == "-F")
		default:
			XCTFail("\(tokens[1])")
		}
		switch tokens[2] {
		case Token.string(let str):
			XCTAssert(str == "x=x")
		default:
			XCTFail("\(tokens[2])")
		}
		switch tokens[3] {
		case Token.string(let str):
			XCTAssert(str == "http://kkbox.com")
		default:
			XCTFail()
		}
	}

	func testTokenize4() {
		let str = "curl --form=x=x http://kkbox.com"
		let result = Lexer.slice(str)
		let tokens = Lexer.tokenize(result)
		switch tokens[0] {
		case Token.commandBegin:
			break
		default:
			XCTFail()
		}
		switch tokens[1] {
		case Token.longCommand(let str):
			XCTAssert(str == "--form=x=x")
		default:
			XCTFail("\(tokens[1])")
		}
		switch tokens[2] {
		case Token.string(let str):
			XCTAssert(str == "http://kkbox.com")
		default:
			XCTFail()
		}
	}

}

final class LexerSlicingTests: XCTestCase {
	func testSlice1() {
		let str = "curl"
		let result = Lexer.slice(str)
		XCTAssert(result == ["curl"])
	}

	func testSlice2() {
		let str = ""
		let result = Lexer.slice(str)
		XCTAssert(result == [])
	}

	func testSlice3() {
		let str = "  "
		let result = Lexer.slice(str)
		XCTAssert(result == [])
	}

	func testSlice4() {
		let str = "curl http://kkbox.com"
		let result = Lexer.slice(str)
		XCTAssert(result == ["curl", "http://kkbox.com"])
	}

	func testSlice5() {
		let str = "curl \"http://kkbox.com\""
		let result = Lexer.slice(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}

	func testSlice5_1() {
		let str = "curl \'http://kkbox.com\'"
		let result = Lexer.slice(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}

	func testSlice6() {
		let str = "curl http\"://kkbox.com\""
		let result = Lexer.slice(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}

	func testSlice6_1() {
		let str = "curl http\'://kkbox.com\'"
		let result = Lexer.slice(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}

	func testSlice7() {
		let str = "curl http\"  ://kkbox.com  \""
		let result = Lexer.slice(str)
		XCTAssert(result == ["curl", "http  ://kkbox.com  "], "\(result)")
	}

	func testSlice7_1() {
		let str = "curl http\'  ://kkbox.com  \'"
		let result = Lexer.slice(str)
		XCTAssert(result == ["curl", "http  ://kkbox.com  "], "\(result)")
	}

	func testSlice8() {
		let str = "curl \"  \'http://kkbox.com\'  \""
		let result = Lexer.slice(str)
		XCTAssert(result == ["curl", "  \'http://kkbox.com\'  "], "\(result)")
	}

	func testSlice8_1() {
		let str = "curl \'  \"http://kkbox.com\"  \'"
		let result = Lexer.slice(str)
		XCTAssert(result == ["curl", "  \"http://kkbox.com\"  "], "\(result)")
	}

	func testSlice9() {
		let str = #"curl -F "{ \"name\"=\"name\" }" "http://kkbox.com""#
		let result = Lexer.slice(str)
		XCTAssert(result == ["curl", "-F", "{ \"name\"=\"name\" }", "http://kkbox.com"], "\(result)")
	}

	func testSlice10() {
		let str = #"curl "http://kkbox.com"#
		let result = Lexer.slice(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}

	func testSlice11() {
		let str = #"curl http://kkbox.com""#
		let result = Lexer.slice(str)
		XCTAssert(result == ["curl", "http://kkbox.com"], "\(result)")
	}


	//    static var allTests = [
	//        ("testExample", testExample),
	//    ]
}
