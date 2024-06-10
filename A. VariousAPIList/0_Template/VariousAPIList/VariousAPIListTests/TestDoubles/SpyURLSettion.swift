import Foundation

@testable import VariousAPIList

class SpyURLSettion: MyURLSession {
    var spyTask: SpyURLSessionDataTask?
    var dataTask_arg: URLRequest?
    
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
        
        let task = URLSessionTask()
        return URLSessionDataTask()
    }
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        return (Data(), URLResponse())
    }
}

class SpyURLSessionDataTask: URLSessionTask {
    var data: Data?
    var _response: URLResponse?
    var _error: Error?
    var completionHandler:  (@Sendable (Data?, URLResponse?, (any Error)?) -> Void)?
    
    override func resume() {
        completionHandler?(data, _response, _error)
    }
}
