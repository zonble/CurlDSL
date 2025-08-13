import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CurlDSLTests.allTests),
        testCase(LineContinuationTests.allTests),
        testCase(UserScenarioTests.allTests),
    ]
}
#endif
