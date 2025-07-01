import XCTest

class SimplePrintTest: XCTestCase {
    
    func testSimplePrint() {
        
        NSLog("This is a test")
        
        // Add some assertions with custom messages
        XCTAssertEqual("Hello", "Hello", "Custom message: The strings match as expected")
        XCTAssertTrue(true, "This test should always pass")
        
        // Add a failing assertion to see the message
        XCTAssertEqual("Expected", "Actual", "CUSTOM TEST OUTPUT: Expected value was 'Expected' but got 'Actual'")
    }
    
    func testMultiplePrints() {
        for i in 1...5 {
            print("Test iteration \(i)")
        }
    }
}
