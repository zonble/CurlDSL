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
	case invalidURL
	case noSuchOption(String)
	case inValidParameter(String)
	case otherSyntaxError

	public var errorDescription: String? {
		switch self {
		case .invalidBegin:
			return #"Your command should start with "curl""#
		case .noURL:
			return #"You did not specific a URL in your command."#
		case .invalidURL:
			return #"The URL is invalid. We suppports only http and https protocol right now."#
		case .noSuchOption(let option):
			return "\(option) is not supported."
		case .inValidParameter(let option):
			return "The parameter for \(option) is not supported."
		default:
			return nil
		}
	}
}

enum Token {
	case commandBegin
	case shortCommand(String)
	case longCommand(String)
	case string(String)
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

public struct Parser {
	public private(set) var command: String

	public init(command: String) {
		self.command = command
	}

	static func slice(_ str: String) -> [String] {
		var slices = [String]()
		let scanner = Scanner(string: str)

		func findQuote(_ str: String) -> (String.Index, String)? {
			for i in str.indices {
				switch str[i] {
				case "\"":
					return (i, "\"")
				case "\'":
					return (i, "\'")
				default:
					continue
				}
			}
			return nil
		}

		while scanner.isAtEnd == false {
			if let result = scanner.scanUpToString(" ") {
				if let (index, quote) = findQuote(result) {
					let beforeQuote = result[result.startIndex..<index]
					var buffer = String(beforeQuote)
					let offset = (result.count - result.distance(from: result.startIndex, to: index) - 1) * -1
					scanner.currentIndex = str.index(scanner.currentIndex, offsetBy: offset)
					scanner.charactersToBeSkipped = nil
					while true {
						if let scannedString = scanner.scanUpToString(quote) {
							buffer.append(scannedString)
							if scanner.isAtEnd {
								slices.append(buffer)
								break
							}
							scanner.currentIndex = str.index(scanner.currentIndex, offsetBy: 1)
							if scannedString[scannedString.index(before: scannedString.endIndex)] != "\\" {
								slices.append(buffer)
								break
							} else {
								buffer.remove(at: buffer.index(before: buffer.endIndex))
								buffer.append(quote)
							}
						}
					}
					scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines
				} else {
					slices.append(result)
				}
			}
		}
		return slices
	}

	static func tokenize(_ slices: [String]) -> [Token] {
		var tokens = [Token]()

		for (i, slice) in slices.enumerated() {
			if i == 0 && slice == "curl" {
				tokens.append(.commandBegin)
				continue
			}
			if slice.hasPrefix("--") {
				tokens.append(.longCommand(slice))
				continue
			}
			if slice.hasPrefix("-") {
				tokens.append(.shortCommand(slice))
				continue
			}
			tokens.append(.string(slice))
		}
		return tokens
	}

	static func convertTokensToOptions(_ tokens: [Token]) throws -> [Option] {
		switch tokens.first {
		case .commandBegin: break
		default: throw ParserError.invalidBegin
		}
		if tokens.count < 2 {
			throw ParserError.noURL
		}
		var options = [Option]()
		var index = 1
		while index < tokens.count {
			let token = tokens[index]
			if case let Token.shortCommand(command) = token {
				index += 1
				if index >= tokens.count {
					throw ParserError.inValidParameter(command)
				}
				let nextToken = tokens[index]
				guard case let Token.string(str) = nextToken else {
					throw ParserError.inValidParameter(command)
				}
				switch command {
				case "-d":
					options.append(.data(str))
				case "-F":
					let components = str.components(separatedBy: "=")
					if components.count < 2 {
						throw ParserError.inValidParameter(command)
					}
					options.append(.form(components[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), components[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)))
				case "-H":
					let components = str.components(separatedBy: ":")
					if components.count < 2 {
						throw ParserError.inValidParameter(command)
					}
					options.append(.header(components[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), components[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)))
				case "-e":
					options.append(.referer(str))
				case "-A":
					options.append(.userAgent(str))
				case "-X":
					options.append(.requestMethod(str))
				case "-u":
					let components = str.components(separatedBy: ":")
					if components.count >= 2 {
						options.append(.user(components[0], components[1]))
					} else {
						options.append(.user(components[0], nil))
					}
				default:
					throw ParserError.noSuchOption(command)
				}
			} else if case let Token.longCommand(command) = token {
				let components = command.components(separatedBy: "=")
				switch components[0] {
				case "--data":
					if components.count < 2 {
						throw ParserError.inValidParameter(components[0])
					}
					options.append(.data(components[1]))
				case "--form", "-form-string":
					if components.count < 2 {
						throw ParserError.inValidParameter(components[0])
					}
					let keyValue = components[1].components(separatedBy: "=")
					if keyValue.count < 2 {
						throw ParserError.inValidParameter(components[0])
					}
					options.append(.form(keyValue[0], keyValue[1]))
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
					throw ParserError.noSuchOption(components[1])
				}

			} else if case let Token.string(str) = token {
				options.append(.url(str))
			}
			index += 1
		}
		return options
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
			throw ParserError.invalidURL
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
			throw ParserError.invalidURL
		}

		return ParseResult(url: finalUrl, user: user, password: password, postData: postData, headers: headers, postFields: postFields, files: files, httpMethod: finalHTTPMethod)
	}

	func parse() throws -> ParseResult {
		let command = self.command.trimmingCharacters(in: CharacterSet.whitespaces)
		let slices = Parser.slice(command)
		let tokens = Parser.tokenize(slices)
		let options = try Parser.convertTokensToOptions(tokens)
		let result = try Parser.compile(options)
		return result
	}
}
