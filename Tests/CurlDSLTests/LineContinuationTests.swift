import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import CurlDSL

final class LineContinuationTests: XCTestCase {

    func testLineContinuationInCurlCommand() {
        // Test a curl command with line continuation characters like the user reported
        let curlCommandWithLineContinuation = """
curl -X POST \\
https://api.instagram.com/oauth/access_token \\
-F client_id=990602627938098 \\
-F client_secret=eb8c7abc123 \\
-F grant_type=authorization_code \\
-F redirect_uri=https://socialsizzle.herokuapp.com/auth/ \\
-F code=AQBx-hBsH3abc123
"""
        
        do {
            let curl = try CURL(curlCommandWithLineContinuation)
            let request = curl.buildRequest()
            
            // Verify that the request was built correctly
            XCTAssertEqual(request.url?.absoluteString, "https://api.instagram.com/oauth/access_token")
            XCTAssertEqual(request.httpMethod, "POST")
            
            // Check that form fields are parsed correctly
            if let httpBody = request.httpBody,
               let bodyString = String(data: httpBody, encoding: .utf8) {
                XCTAssertTrue(bodyString.contains("client_id=990602627938098"))
                XCTAssertTrue(bodyString.contains("grant_type=authorization_code"))
                XCTAssertTrue(bodyString.contains("code=AQBx-hBsH3abc123"))
            } else {
                XCTFail("HTTP body should not be nil for POST request with form data")
            }
        } catch {
            XCTFail("Should be able to parse curl command with line continuations: \(error)")
        }
    }
    
    func testLineContinuationWithSpaces() {
        // Test with spaces after backslash
        let curlCommand = """
curl -X GET \\ 
https://httpbin.org/json \\ 
-H "Accept: application/json"
"""
        
        do {
            let curl = try CURL(curlCommand)
            let request = curl.buildRequest()
            
            XCTAssertEqual(request.url?.absoluteString, "https://httpbin.org/json")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        } catch {
            XCTFail("Should be able to parse curl command with line continuations and spaces: \(error)")
        }
    }
    
    func testLineContinuationWithTabs() {
        // Test with tabs after backslash  
        let curlCommand = "curl -X GET \\\t\nhttps://httpbin.org/json"
        
        do {
            let curl = try CURL(curlCommand)
            let request = curl.buildRequest()
            
            XCTAssertEqual(request.url?.absoluteString, "https://httpbin.org/json")
            XCTAssertEqual(request.httpMethod, "GET")
        } catch {
            XCTFail("Should be able to parse curl command with line continuations and tabs: \(error)")
        }
    }
}