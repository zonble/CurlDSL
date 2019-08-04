import Foundation

public enum Option {
	case url(String)
	case data(String)
	case form(_ key: String, _ value: String)
	case header(_ key: String, _ value: String)
	case referer(String)
	case userAgent(String)
	case user(_ user: String, _ password: String?)
	case requestMethod(String)
}

/// Errors for `Parser`.
public enum ParserError: Error, LocalizedError {
	case invalidBegin
	case noURL
	case invalidURL(String)
	case noSuchOption(String)
	case inValidParameter(String)
	case otherSyntaxError

	public var errorDescription: String? {
		switch self {
		case .invalidBegin:
			return "Your command should start with \"curl\"."
		case .noURL:
			return "You did not specific a URL in your command."
		case .invalidURL(let url):
			return "The URL \(url) is invalid. We suppports only http and https protocol right now."
		case .noSuchOption(let option):
			return "\(option) is not supported."
		case .inValidParameter(let option):
			return "The parameter for \(option) is not supported."
		default:
			return nil
		}
	}
}

struct Lexer {
	static func tokenize(_ str: String) -> [String] {
		var slices = [String]()
		let scanner = Scanner(string: str)

		while scanner.isAtEnd == false {
			let result = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: " \n\"\'") )
			if result == nil {
				scanner.currentIndex = str.index(after: scanner.currentIndex)
			}
			if scanner.isAtEnd {
				if let result = result {
					slices.append(result)
				}
				break
			}

			let lastChar = String(str[scanner.currentIndex])

			if lastChar == "\"" || lastChar == "\'" {
				let quote = lastChar
				var buffer = result ?? ""
				scanner.charactersToBeSkipped = nil
				scanner.currentIndex = str.index(after: scanner.currentIndex)
				while true {
					if let scannedString = scanner.scanUpToString(quote) {
						buffer.append(scannedString)
						if scanner.isAtEnd {
							slices.append(buffer)
							break
						}
						scanner.currentIndex = str.index(after: scanner.currentIndex)
						if scannedString[scannedString.index(before: scannedString.endIndex)] != "\\" {
							// Find matching quote mark.
							slices.append(buffer)
							break
						} else {
							// The quote mark is escaped. Continue.
							buffer.remove(at: buffer.index(before: buffer.endIndex))
							buffer.append(quote)
						}
					} else {
						if buffer.count > 0 {
							slices.append(buffer)
						}
						break
					}
				}
				scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines
			} else {
				if let result = result {
					slices.append(result)
				}
			}
		}
		return slices
	}

	fileprivate static func handleShortCommands(_ tokens: [String], _ index: Int, _ token: String, _ options: inout [Option]) throws {
		let nextToken = tokens[index]
		switch token {
		case "-d":
			options.append(.data(nextToken))
		case "-F":
			let components = nextToken.components(separatedBy: "=")
			if components.count < 2 {
				throw ParserError.inValidParameter(token)
			}
			options.append(.form(components[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), components[1]))
		case "-H":
			let components = nextToken.components(separatedBy: ":")
			if components.count < 2 {
				throw ParserError.inValidParameter(token)
			}
			options.append(.header(components[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), components[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)))
		case "-e":
			options.append(.referer(nextToken))
		case "-A":
			options.append(.userAgent(nextToken))
		case "-X":
			options.append(.requestMethod(nextToken))
		case "-u":
			let components = nextToken.components(separatedBy: ":")
			if components.count >= 2 {
				options.append(.user(components[0], components[1]))
			} else {
				options.append(.user(components[0], nil))
			}
		default:
			throw ParserError.noSuchOption(token)
		}
	}

	fileprivate static func handleLongCommands(_ token: String, _ options: inout [Option]) throws {
		let components = token.components(separatedBy: "=")
		switch components[0] {
		case "--data":
			if components.count < 2 {
				throw ParserError.inValidParameter(components[0])
			}
			options.append(.data(components[1]))
		case "--form", "-form-string":
			if components.count < 3 {
				throw ParserError.inValidParameter(components[0])
			}
			options.append(.form(components[1], components[2]))
		case "--header":
			if components.count < 2 {
				throw ParserError.inValidParameter(components[0])
			}
			let keyValue = components[1].components(separatedBy: ":")
			if keyValue.count < 2 {
				throw ParserError.inValidParameter(components[0])
			}
			options.append(.header(keyValue[0], keyValue[1]))
		case "--referer":
			if components.count < 2 {
				throw ParserError.inValidParameter(components[0])
			}
			options.append(.referer(components[1]))
		case "--user-agent":
			if components.count < 2 {
				throw ParserError.inValidParameter(components[0])
			}
			options.append(.userAgent(components[1]))
		case "--request":
			if components.count < 2 {
				throw ParserError.inValidParameter(components[0])
			}
			options.append(.requestMethod(components[1]))
		case "--user":
			if components.count < 2 {
				throw ParserError.inValidParameter(components[0])
			}
			let userPassword = components[1].components(separatedBy: ":")
			if userPassword.count >= 2 {
				options.append(.user(userPassword[0], userPassword[1]))
			} else {
				options.append(.user(userPassword[0], nil))
			}
		default:
			throw ParserError.noSuchOption(components[0])
		}
	}

	static func convertTokensToOptions(_ tokens: [String]) throws -> [Option] {
		switch tokens.first {
		case "curl": break
		default: throw ParserError.invalidBegin
		}
		if tokens.count < 2 {
			throw ParserError.noURL
		}
		var options = [Option]()
		var index = 1
		while index < tokens.count {
			let token = tokens[index]
			if token.hasPrefix("--") {
				try handleLongCommands(token, &options)
			}
			else if token.hasPrefix("-") {
				index += 1
				if index >= tokens.count {
					throw ParserError.inValidParameter(token)
				}
				try handleShortCommands(tokens, index, token, &options)
			}  else {
				options.append(.url(token))
			}
			index += 1
		}
		return options
	}
}

struct ParseResult {
	var url: URL
	var user: String?
	var password: String?
	var postData: String?
	var headers: [String: String]
	var postFields: [String: String]
	var files: [String: String]
	var httpMethod: String
}

struct Parser {
	public private(set) var command: String

	init(command: String) {
		self.command = command
	}

	static func compile(_ options: [Option]) throws -> ParseResult {
		var url: String = ""
		var user: String?
		var password: String?
		var postData: String?
		var headers: [String: String] = [:]
		var postFields: [String: String] = [:]
		var files: [String: String] = [:]
		var httpMethod: String?

		for option in options {
			switch option {
			case .url(let str):
				url = str
			case .data(let data):
				postData = data
			case .form(let key, let value):
				if value.hasPrefix("@") {
					files[key] = value
				} else {
					postFields[key] = value
				}
			case .header(let key, let value):
				headers[key] = value
			case .referer(let str):
				headers["Referer"] = str
			case .userAgent(let str):
				headers["User-Agent"] = str
			case .user(let aUser, let aPassword):
				user = aUser
				password = aPassword
			case .requestMethod(let method):
				httpMethod = method
			}
		}

		let finalHTTPMethod: String = {
			if let httpMethod = httpMethod {
				return httpMethod
			}
			if postData != nil {
				return "POST"
			}
			if !postFields.isEmpty {
				return "POST"
			}
			if !files.isEmpty {
				return "POST"
			}
			return "GET"
		}()

		url = url.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		if !url.hasPrefix("https://") && !url.hasPrefix("http://") {
			throw ParserError.invalidURL(url)
		}

		do {
			let pattern = "https?://(.*)@(.*)"
			let regex = try NSRegularExpression(pattern: pattern, options: [])
			let matches = regex.matches(in: url, options: [], range: NSMakeRange(0, url.count))
			if matches.count > 0 {
				let usernameRange = matches[0].range(at: 1)
				let start = url.index(url.startIndex, offsetBy: usernameRange.location)
				let end = url.index(url.startIndex, offsetBy: usernameRange.location + usernameRange.length)
				let substring = url[start..<end]
				let components = substring.components(separatedBy: ":")
				if user == nil {
					user = components[0]
					if components.count >= 2 {
						password = components[1]
					}
				}
				url.removeSubrange(start...end)
			}
		} catch {
		}

		guard let finalUrl = URL(string: url) else {
			throw ParserError.invalidURL(url)
		}

		return ParseResult(url: finalUrl, user: user, password: password, postData: postData, headers: headers, postFields: postFields, files: files, httpMethod: finalHTTPMethod)
	}

	func parse() throws -> ParseResult {
		let command = self.command.trimmingCharacters(in: CharacterSet.whitespaces)
		let slices = Lexer.tokenize(command)
		let options = try Lexer.convertTokensToOptions(slices)
		let result = try Parser.compile(options)
		return result
	}
}
