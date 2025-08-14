# CurlDSL
CurlDSL is a Swift Package Manager library that converts cURL commands into `URLRequest` objects for iOS, macOS, tvOS, and watchOS applications. It provides a simple interpreter that parses cURL commands at runtime and supports HTTP/HTTPS protocols.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Platform Requirements
**CRITICAL: This project ONLY builds and runs on Apple platforms (macOS, iOS, tvOS, watchOS). It uses the Combine framework which is not available on Linux/Windows.**

- Swift 5.5 or above
- macOS 10.15+ (for development)
- Xcode 13.0+ (recommended)
- Target platforms: iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+

## Working Effectively

### Bootstrap and Build
- **NEVER CANCEL**: Swift builds typically take 10-30 seconds. Set timeout to 120+ seconds for safety.
- Ensure you are on macOS with Xcode installed
- `swift build` -- builds all targets (CurlDSL + CurlDSLAsync). Takes 10-30 seconds. NEVER CANCEL.
- `swift test` -- runs the complete test suite. Takes 5-15 seconds. NEVER CANCEL.

### Build Validation
- The build succeeds on macOS with Xcode and we can run tests with network access
- If building on Linux/Windows: **DO NOT attempt to build** - it will fail due to missing Combine framework
- Always build and test your changes on macOS before committing

### Development Commands
- `swift package generate-xcodeproj` -- generates Xcode project file (optional, for Xcode development)
- `swift package resolve` -- resolves package dependencies
- `swift package clean` -- cleans build artifacts

## Testing and Validation

### Running Tests
- `swift test` -- runs all tests including network integration tests. Takes 5-15 seconds. NEVER CANCEL.
- Tests include real network calls to httpbin.org and Facebook Graph API endpoints
- Tests validate cURL command parsing, URLRequest generation, and network execution

### Manual Validation Scenarios
After making changes, ALWAYS test these complete scenarios:

#### Basic GET Request Validation
```swift
// Test this exact scenario in a playground or test
let curl = try CURL("curl -X GET https://httpbin.org/json")
let request = curl.buildRequest()
// Verify: URL, method, headers are correct
```

#### POST Request with Data Validation  
```swift
// Test this exact scenario
let curl = try CURL("curl -X POST -d 'key=value' https://httpbin.org/post")
curl.run { data, response, error in
    // Verify: request completes successfully and data is posted
}
```

#### Header and Authentication Validation
```swift
// Test this exact scenario
let curl = try CURL("curl -H 'Authorization: Bearer token' -u user:pass https://httpbin.org/basic-auth/user/pass")
let request = curl.buildRequest()
// Verify: Authorization header is set correctly
```

### CI Validation
- CI runs on macOS-11 with Xcode 13.0
- Always ensure your changes pass both `swift build` and `swift test` before committing
- The `.github/workflows/ci.yml` will automatically validate your changes

## Project Structure

### Key Source Files
- `Sources/CurlDSL/CurlDSL.swift` -- Main CURL struct and URLRequest building logic
- `Sources/CurlDSL/Parser.swift` -- cURL command parsing implementation  
- `Sources/CurlDSL/Handlers.swift` -- Response handlers (JSON, Codable, Data)
- `Sources/CurlDSLAsync/CurlDSLAsync.swift` -- Async/await extensions (iOS 15+/macOS 12+)

### Key Test Files  
- `Tests/CurlDSLTests/CurlDSLTests.swift` -- Main functionality tests with live network calls
- `Tests/CurlDSLTests/ParserTest.swift` -- cURL command parsing unit tests

### Configuration Files
- `Package.swift` -- Swift Package Manager configuration, defines CurlDSL and CurlDSLAsync products
- `CurlDSL.podspec` -- CocoaPods support configuration
- `.github/workflows/ci.yml` -- GitHub Actions CI pipeline
- `.github/workflows/jazzy.yml` -- Documentation generation pipeline

## Supported cURL Options
When testing changes, verify these supported cURL options work correctly:
```
-d, --data=DATA                    HTTP POST data
-F, --form=KEY=VALUE              HTTP multipart POST data  
--form-string=KEY=VALUE           HTTP multipart POST data
-H, --header=LINE                 Custom headers
-e, --referer=                    Referer URL
-X, --request=COMMAND             HTTP method
--url=URL                         Target URL
-u, --user=USER[:PASSWORD]        Basic authentication
-A, --user-agent=STRING           User-Agent header
```

## Common Tasks

### Adding New cURL Option Support
1. Update `Parser.swift` to recognize the new option
2. Modify `ParseResult` struct to store the parsed data
3. Update `CurlDSL.swift` `buildRequest()` method to apply the option to URLRequest
4. Add tests in `ParserTest.swift` for parsing
5. Add integration tests in `CurlDSLTests.swift` for functionality

### Testing New Response Handlers
1. Create new handler class extending `Handler<T>` in `Handlers.swift`
2. Test with real network requests using `curl.run(handler: YourHandler())`
3. Validate both success and error scenarios

### Documentation Updates
- Run `jazzy` to generate documentation (requires `gem install jazzy`)
- Documentation is automatically deployed to GitHub Pages via CI
- Focus on code comments in public APIs for Jazzy generation

## Development Environment Setup
- Install Xcode from Mac App Store or Apple Developer portal
- No additional dependencies required - uses only Foundation and Combine from Apple SDKs
- Optional: Install Jazzy for documentation generation: `gem install jazzy`

## Common Issues and Solutions
- **"No such module 'Combine'"**: You are not on macOS or Xcode is not properly installed
- **Network test failures**: Check internet connectivity and firewall settings
- **Build failures after changes**: Ensure your code follows Swift 5.5+ syntax and uses supported APIs
- **Test timeouts**: Network tests may take longer with slow connections, this is normal

## Performance Expectations
- Build time: 10-30 seconds (clean build)
- Test execution: 5-15 seconds (includes network requests)
- Documentation generation: 30-60 seconds

Always validate these timings match your experience and adjust timeout values accordingly.