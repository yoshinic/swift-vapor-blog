@testable import App
import XCTVapor

final class TagTests: XCTestCase {
    
    let tagsURI = "/api/tags/"
    let tagName = "Teenager"
    
    override func setUp() { }
    override func tearDown() { }
    
    func testTagsCanBeRetrievedFromAPI() throws {
        try _test { app in
            let tag = try Tag.create(name: tagName, on: app.db)
            _ = try Tag.create(on: app.db)
            try app
                .test(
                    .GET,
                    tagsURI,
                    beforeRequest: { _ in },
                    afterResponse: { response in
                        let tags = try response.content.decode([App.Tag].self)
                        XCTAssertEqual(tags.count, 2)
                        XCTAssertEqual(tags[0].name, tagName)
                        XCTAssertEqual(tags[0].id, tag.id)
                }
            )
        }
    }
    
    func testTagCanBeSavedWithAPI() throws {
        try _testAfterLoggedIn(loggedInRequest: true) { app, headers in
            var headers = headers
            headers.add(name: "Content-Type", value: "application/json")
            let tag = Tag(name: tagName)
            try app
                .test(
                    .POST,
                    tagsURI,
                    headers: headers,
                    beforeRequest: { request in
                        try request.content.encode(tag)
                },
                    afterResponse: { response in
                        let receivedTag = try response.content.decode(App.Tag.self)
                        XCTAssertEqual(receivedTag.name, tagName)
                        XCTAssertNotNil(receivedTag.id)
                        
                        try app.test(
                            .GET,
                            tagsURI,
                            beforeRequest: { _ in },
                            afterResponse: { response in
                                let tags = try response.content.decode([App.Tag].self)
                                XCTAssertEqual(tags.count, 1)
                                XCTAssertEqual(tags[0].name, tagName)
                                XCTAssertEqual(tags[0].id, receivedTag.id)
                        })
                })
        }
    }
    
    func testGettingASingleTagFromTheAPI() throws {
        try _test { app in
            let tag = try Tag.create(name: tagName, on: app.db)
            try app
                .test(
                    .GET,
                    "\(tagsURI)\(tag.id!)",
                    afterResponse: { response in
                        let returnedTag = try response.content.decode(App.Tag.self)
                        XCTAssertEqual(returnedTag.name, tagName)
                        XCTAssertEqual(returnedTag.id, tag.id)
                })
        }
    }
    
    func testGettingATagsBlogsFromTheAPI() throws {
        try _testAfterLoggedIn(loggedInRequest: true) { app, headers in
            let blogTitle = "タイトル"
            let blogContents = "内容"
            
            let blog = try Blog.create(
                title: blogTitle,
                contents: blogContents,
                on: app.db)
            let blog2 = try Blog.create(on: app.db)
            let tag = try Tag.create(name: tagName, on: app.db)
            
            let blog1URL = "/api/blogs/\(blog.id!)/tags/\(tag.id!)"
            let blog2URL = "/api/blogs/\(blog2.id!)/tags/\(tag.id!)"
            
            try app
                .test(.POST, blog1URL, headers: headers)
                .test(.POST, blog2URL, headers: headers)
                .test(
                    .GET,
                    "\(tagsURI)\(tag.id!)/blogs",
                    headers: headers,
                    afterResponse: { response in
                        let blogs = try response.content.decode([Blog].self)
                        XCTAssertEqual(blogs.count, 2)
                        XCTAssertEqual(blogs[0].id, blog.id)
                        XCTAssertEqual(blogs[0].title, blogTitle)
                        XCTAssertEqual(blogs[0].contents, blogContents)
                }
            )
        }
    }
    
    static let allTests = [
        ("testTagsCanBeRetrievedFromAPI", testTagsCanBeRetrievedFromAPI),
        ("testTagCanBeSavedWithAPI", testTagCanBeSavedWithAPI),
        ("testGettingASingleTagFromTheAPI", testGettingASingleTagFromTheAPI),
        ("testGettingATagsBlogsFromTheAPI", testGettingATagsBlogsFromTheAPI),
    ]
}

