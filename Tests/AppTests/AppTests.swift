@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    func testStub() throws {
        XCTAssert(true)
    }
    
    static let allTests = [
        ("testStub", testStub),
    ]
}

extension XCTestCase {
    func _test(_ test: (Application) throws -> Void) throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
        
        try test(app)
    }
}
