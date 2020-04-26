@testable import App
import XCTVapor
import Fluent

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
    
    func _testAfterLoggedIn(
        loggedInRequest: Bool = false,
        loggedInUser: User? = nil,
        test: (Application, HTTPHeaders) throws -> Void
    ) throws {
        try _test { app in
            
            let adminName = "Admin"
            let adminUsername = "admin"
            let adminPassword = "password"
            
            let existedAdminUser
                = try User.query(on: app.db).filter(\.$username == adminUsername).first().wait()
            if existedAdminUser == nil {
                let _ = try User.create(name: adminName,
                                        username: adminUsername,
                                        password: adminPassword,
                                        on: app.db)
            }
            
            var headers: HTTPHeaders = .init()
            if (loggedInRequest || loggedInUser != nil) {
                let username: String
                if let user = loggedInUser {
                    username = user.username
                } else {
                    username = adminUsername
                }
                let credentials = BasicAuthorization(
                    username: username,
                    password: adminPassword
                )
                
                var tokenHeaders = HTTPHeaders()
                tokenHeaders.basicAuthorization = credentials
                
                try app.test(.POST, "/api/users/login", headers: tokenHeaders) { tokenResponse in
                    let token = try tokenResponse.content.decode(UserToken.self)
                    headers.add(name: .authorization, value: "Bearer \(token.value)")
                    try test(app, headers)
                }
            }
        }
    }
}
