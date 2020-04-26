@testable import App
import XCTVapor
import FluentPostgresDriver

final class BlogTests: XCTestCase {
    
    let blogsURI = "/api/blogs/"
    let blogTitle = "テスト"
    let blogContents = "データ"
    
    override func setUp() { }
    
    override func tearDown() { }
    
    // Blogを複数作成したとき区別されているか確認
    func testBlogsCanBeRetrievedFromAPI() throws {
        try _test { app in
            let blog1 = try Blog.create(title: blogTitle, contents: blogContents, on: app.db)
            _ = try Blog.create(on: app.db)
            try app.test(.GET, blogsURI) { response in
                let blogs = try response.content.decode([Blog].self)
                XCTAssertEqual(blogs.count, 2)
                XCTAssertEqual(blogs[0].title, blogTitle)
                XCTAssertEqual(blogs[0].contents, blogContents)
                XCTAssertEqual(blogs[0].id, blog1.id)
            }
        }
    }
    
    // Blog が保存されるか確認
    func testBlogCanBeSavedWithAPI() throws {
        try _test { app in
            let blog = Blog(title: blogTitle, contents: blogContents)
            try app
                .test(
                    .POST,
                    blogsURI,
                    headers: .init([("Content-Type", "application/json")]),
                    beforeRequest: { request in
                        try request.content.encode(blog)
                },
                    afterResponse: { response in
                        let receivedBlog = try response.content.decode(Blog.self)
                        XCTAssertEqual(receivedBlog.title, blogTitle)
                        XCTAssertEqual(receivedBlog.contents, blogContents)
                        XCTAssertNotNil(receivedBlog.id)
                        
                        try app.test(.GET, blogsURI) { response in
                            let blogs = try response.content.decode([Blog].self)
                            XCTAssertEqual(blogs.count, 1)
                            XCTAssertEqual(blogs[0].title, blogTitle)
                            XCTAssertEqual(blogs[0].contents, blogContents)
                            XCTAssertEqual(blogs[0].id, receivedBlog.id)
                        }
                })
        }
    }
    
    // Blog を１つ取得できるか確認
    func testGettingASingleBlogFromTheAPI() throws {
        try _test { app in
            let blog = try Blog.create(title: blogTitle, contents: blogContents, on: app.db)
            try app.test(.GET, "\(blogsURI)\(blog.id!)") { response in
                let returnedBlog = try response.content.decode(Blog.self)
                XCTAssertEqual(returnedBlog.title, blogTitle)
                XCTAssertEqual(returnedBlog.contents, blogContents)
                XCTAssertEqual(returnedBlog.id, blog.id)
            }
        }
    }
    
    // 保存した Blog を更新できるか確認
    func testUpdatingAnBlog() throws {
        try _test { app in
            let blog = try Blog.create(title: blogTitle, contents: blogContents, on: app.db)
            let newContents = "更新内容"
            let updatedBlog = Blog(title: blogTitle, contents: newContents)
            try app
                .test(
                    .PUT,
                    "\(blogsURI)\(blog.id!)",
                    headers: .init([("Content-Type", "application/json")]),
                    beforeRequest: { request in
                        try request.content.encode(updatedBlog)
                },
                    afterResponse: { response in
                        try app.test(.GET, "\(blogsURI)\(blog.id!)") { response in
                            let returnedBlog = try response.content.decode(Blog.self)
                            XCTAssertEqual(returnedBlog.title, blogTitle)
                            XCTAssertEqual(returnedBlog.contents, newContents)
                        }
                })
        }
    }
    
    // 保存した Blog を削除できるか確認
    func testDeletingAnBlog() throws {
        try _test { app in
            let blog = try Blog.create(on: app.db)
            try app.test(.GET, blogsURI) { response in
                var blogs = try response.content.decode([Blog].self)
                XCTAssertEqual(blogs.count, 1)
                
                try app
                    .test(.DELETE, "\(blogsURI)\(blog.id!)")
                    .test(.GET, blogsURI) { response in
                        blogs = try response.content.decode([Blog].self)
                        XCTAssertEqual(blogs.count, 0)
                }
            }
        }
    }
    
    static let allTests = [
        ("testBlogsCanBeRetrievedFromAPI", testBlogsCanBeRetrievedFromAPI),
        ("testBlogCanBeSavedWithAPI", testBlogCanBeSavedWithAPI),
        ("testGettingASingleBlogFromTheAPI", testGettingASingleBlogFromTheAPI),
        ("testUpdatingAnBlog", testUpdatingAnBlog),
        ("testDeletingAnBlog", testDeletingAnBlog),
    ]
}
