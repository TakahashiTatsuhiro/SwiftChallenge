import Foundation
import Combine

enum HttpMethod: String {
    case GET
}


protocol APIClient {
    func executeWithCompletion<T: APIRequest>(_ request: T, completion: @escaping (T.ResponseType?, Error?) -> Void)
    func executeWithFuture<T: APIRequest>(_ request: T) -> Future<T.ResponseType, Error>
    func executeWithAsyncThrows<T: APIRequest>(_ request: T) async throws -> T.ResponseType
    func executeWithAsyncResult<T: APIRequest>(_ request: T) async -> Result<T.ResponseType, Error>
}


class APIClientImpl: APIClient {
    let defaultBaseURL: URL
    private var cancellables = Set<AnyCancellable>()
    
    init(defaultBaseURL: URL) {
        self.defaultBaseURL = defaultBaseURL
    }
    
    private func makeURL(with request: any APIRequest) -> URL {
        var urlComponent = URLComponents()
        if let baseURL = request.baseURL {
            urlComponent = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
        } else {
            urlComponent = URLComponents(url: defaultBaseURL, resolvingAgainstBaseURL: true)!
        }
        urlComponent.path = request.endpoint
        
        var queryItems: [URLQueryItem] = []
        for param in request.parameters {
            queryItems.append(
                URLQueryItem(name: param.key, value: param.value)
            )
        }
        urlComponent.queryItems = queryItems
        
        return urlComponent.url!
    }
    
    private func makeURLRequest(with request: any APIRequest) -> URLRequest {
        let url = makeURL(with: request)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return urlRequest
    }
    
    func executeWithCompletion<T>(_ request: T, completion: @escaping (T.ResponseType?, (any Error)?) -> Void) where T: APIRequest {
        let urlRequest = makeURLRequest(with: request)
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode >= 200,
                  httpResponse.statusCode < 300,
                  let data = data,
                  let json = try? JSONDecoder().decode(T.ResponseType.self, from: data)
            else {
                completion(nil, URLError(.badServerResponse))
                return
            }
            completion(json, nil)
        }
        task.resume()
    }
    
    func executeWithFuture<T: APIRequest>(_ request: T) -> Future<T.ResponseType, Error> {
        // https://tech.stmn.co.jp/entry/2023/07/03/163842
        return Future { promise in
            let urlRequest = self.makeURLRequest(with: request)
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode >= 200,
                      httpResponse.statusCode < 300,
                      let data = data else {
                    promise(.failure(URLError(.badServerResponse)))
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(T.ResponseType.self, from: data)
                    promise(.success(decoded))
                } catch {
                    promise(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    func executeWithAsyncThrows<T>(_ request: T) async throws -> T.ResponseType where T : APIRequest {
        let urlRequest = makeURLRequest(with: request)
        let (data, response) = try await URLSession.shared.data(from: urlRequest.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode >= 200,
              httpResponse.statusCode < 300
        else {
            throw URLError(.badServerResponse)
        }
        
//        do {
            let decoded = try JSONDecoder().decode(T.ResponseType.self, from: data)
            return decoded
//        } catch {
//            throw error
//        }
    }
    
    func executeWithAsyncResult<T>(_ request: T) async -> Result<T.ResponseType, any Error> where T : APIRequest {
        let urlRequest = makeURLRequest(with: request)
        do {
            let (data, response) = try await URLSession.shared.data(from: urlRequest.url!)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode >= 200,
                  httpResponse.statusCode < 300
            else {
                return Result.failure(URLError(.badServerResponse))
            }
            let decoded = try JSONDecoder().decode(T.ResponseType.self, from: data)
            return Result.success(decoded)
        } catch {
            return Result.failure(error)
        }
    }
}


class APIClientKentaro: APIClient {
    let defaultBaseURL: URL
    private var cancellables = Set<AnyCancellable>()
    
    init(defaultBaseURL: URL) {
        self.defaultBaseURL = defaultBaseURL
    }
    
    private func makeURL(with request: any APIRequest) -> URL {
        var urlComponent = URLComponents()
        if let baseURL = request.baseURL {
            urlComponent = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
        } else {
            urlComponent = URLComponents(url: defaultBaseURL, resolvingAgainstBaseURL: true)!
        }
        urlComponent.path = request.endpoint
        
        var queryItems: [URLQueryItem] = []
        for param in request.parameters {
            queryItems.append(
                URLQueryItem(name: param.key, value: param.value)
            )
        }
        urlComponent.queryItems = queryItems
        
        return urlComponent.url!
    }
    
    private func makeURLRequest(with request: any APIRequest) -> URLRequest {
        let url = makeURL(with: request)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return urlRequest
    }
    
    func executeWithFutureKentaro<T>(_ request: T) -> Future<T.ResponseType, Error> where T: APIRequest {
        let urlRequest = makeURLRequest(with: request)
        return Future { promise in
            URLSession.shared.dataTaskPublisher(for: urlRequest)
                .tryMap { data, response in
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode >= 200,
                          httpResponse.statusCode < 300
                    else {
                        throw URLError(.badServerResponse)
                    }
                    return data
                }
                .decode(type: T.ResponseType.self, decoder: JSONDecoder())
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        promise(.failure(error))
                    }
                } receiveValue: { json in
                    promise(.success(json))
                }
                .store(in: &self.cancellables)
        }
    }

    
    func executeWithCompletion<T>(_ request: T, completion: @escaping (T.ResponseType?, (any Error)?) -> Void) where T : APIRequest {
        
    }
    
    func executeWithFuture<T>(_ request: T) -> Future<T.ResponseType, any Error> where T : APIRequest {
        return Future { promise in
            return promise(.failure(NSError()))
        }
    }
    
    func executeWithAsyncThrows<T>(_ request: T) async throws -> T.ResponseType where T : APIRequest {
        throw NSError()
    }
    
    func executeWithAsyncResult<T>(_ request: T) async -> Result<T.ResponseType, any Error> where T : APIRequest {
        return .failure(NSError())
    }
    
}
