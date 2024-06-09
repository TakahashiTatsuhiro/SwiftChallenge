import Foundation

// https://sussan-po.com/2022/08/17/mocking-url-session/
protocol MyURLSession {
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: MyURLSession {}
