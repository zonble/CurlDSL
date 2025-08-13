import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import CurlDSL

final class UserScenarioTests: XCTestCase {

    func testUserReportedInstagramOAuthScenario() {
        // This is the exact type of curl command the user was trying to use,
        // which previously would give "Invalid escape sequence in literal" 
        // and "Missing argument for parameter #1 in call" errors.
        
        // Before fix: This would fail
        // After fix: This should work
        let requestCurl = try? CURL("""
curl -X POST \\
https://api.instagram.com/oauth/access_token \\
-F client_id=990602627938098 \\
-F client_secret=eb8c7abc123456 \\
-F grant_type=authorization_code \\
-F redirect_uri=https://socialsizzle.herokuapp.com/auth/ \\
-F code=AQBx-hBsH3abc123
""").buildRequest()
        
        // Should successfully create the request
        XCTAssertNotNil(requestCurl, "Should successfully parse multiline curl command with line continuations")
        
        if let request = requestCurl {
            // Verify the request is correctly constructed
            XCTAssertEqual(request.url?.absoluteString, "https://api.instagram.com/oauth/access_token")
            XCTAssertEqual(request.httpMethod, "POST")
            
            // Verify form data is present
            XCTAssertNotNil(request.httpBody, "Should have form data in HTTP body")
            
            if let body = request.httpBody,
               let bodyString = String(data: body, encoding: .utf8) {
                // All the OAuth parameters should be present
                XCTAssertTrue(bodyString.contains("client_id=990602627938098"))
                XCTAssertTrue(bodyString.contains("grant_type=authorization_code"))
                XCTAssertTrue(bodyString.contains("redirect_uri="))
                XCTAssertTrue(bodyString.contains("code="))
            }
        }
    }
    
    func testUserWorkflowExample() {
        // Show a typical workflow where users copy curl commands from documentation
        // and paste them directly into their Swift code
        
        let curlFromDocumentation = """
curl -X POST \\
  https://api.example.com/endpoint \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer token123" \\
  -d '{"key": "value"}'
"""
        
        do {
            let curl = try CURL(curlFromDocumentation)
            let request = curl.buildRequest()
            
            XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/endpoint")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token123")
            
            if let body = request.httpBody,
               let bodyString = String(data: body, encoding: .utf8) {
                XCTAssertEqual(bodyString, #"{"key": "value"}"#)
            }
        } catch {
            XCTFail("Should successfully parse curl command copied from documentation: \(error)")
        }
    }
    
    static var allTests = [
        ("testUserReportedInstagramOAuthScenario", testUserReportedInstagramOAuthScenario),
        ("testUserWorkflowExample", testUserWorkflowExample),
    ]
}