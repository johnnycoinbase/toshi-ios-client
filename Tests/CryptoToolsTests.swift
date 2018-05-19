import XCTest

class CryptoToolsTests: XCTestCase {
    
    func testHashWithSha256() {
        var hashed = CryptoTools.hash(withSha256: "test")
        XCTAssertEqual(hashed?.uppercased(), "9F86D081884C7D659A2FEAA0C55AD015A3BF4F1B2B0B822CD15D6C15B0F00A08")
    }
}
