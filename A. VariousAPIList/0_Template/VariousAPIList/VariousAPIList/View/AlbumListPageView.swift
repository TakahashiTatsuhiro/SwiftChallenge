import SwiftUI
import Combine

struct AlbumListPageView: View {
    @StateObject var viewModel: AlbumViewModel
    
    var body: some View {
        ScrollView {
            ForEach(viewModel.albumList, id: \.self) { album in
                AlbumView(album: album)
                Divider()
            }
        }
        .onAppear() {
            viewModel.onAppear()
        }
    }
}

extension AlbumListPageView {
    
    class AlbumViewModel: ObservableObject {
        @Published var albumList: [Album] = []
        private var cancellable: AnyCancellable?
        
        func onAppear() {
            // https://www.bravesoft.co.jp/blog/archives/15610
            cancellable = fetchAlbumMyAPIClientWithFuture()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("Finished")
                        case .failure(let error):
                            print("Failed: \(error)")
                        }
                    },
                    receiveValue: { albums in
                        self.albumList = albums
                    }
                )
        }
        
        // 問２
        func fetchAlbum(completion: @escaping ([Album]?, Error?) -> Void) {
            //参考 https://zenn.dev/masakatsu_tagi/articles/f5374dd3153bdc
            let requestUrl = URL(string: "https://jsonplaceholder.typicode.com/albums")!
            let task = URLSession.shared.dataTask(with: requestUrl) { data, response, error in
                
                if let error = error {
                    completion(nil, error)
                } else if let data = data {
                    let decoder = JSONDecoder()
                    do {
                        let decoded = try decoder.decode([Album].self, from: data)
                        completion(decoded, nil)
                    } catch {
                        print("error")
                    }
                }
            }
            task.resume()
        }
        
        // 問３
        func fetchAlbumAPIClientWithComp(completion: @escaping ([Album]?, Error?) -> Void) {
            let getAlbumRequest = GetAlbumsRequest()
            let apiClient = APIClientImpl(defaultBaseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
            apiClient.executeWithCompletion(getAlbumRequest, completion: completion)
        }
        
        func fetchAlbumAPIClientWithFuture() -> Future<GetAlbumsRequest.ResponseType, Error> {
            let getAlbumRequest = GetAlbumsRequest()
            let apiClient = APIClientImpl(defaultBaseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
            return apiClient.executeWithFuture(getAlbumRequest)
        }
        
        func fetchAlbumAPIClientWithAsyncThrows() async throws -> GetAlbumsRequest.ResponseType {
            let getAlbumRequest =  GetAlbumsRequest()
            let apiClient = APIClientImpl(defaultBaseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
            let response = try await apiClient.executeWithAsyncThrows(getAlbumRequest)
            return response
        }
        
        func fetchAlbumAPIClientWithAsyncResult() async -> Result<GetAlbumsRequest.ResponseType, any Error> {
            let getAlbumRequest = GetAlbumsRequest()
            let apiClient = APIClientImpl(defaultBaseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
            let response = await apiClient.executeWithAsyncResult(getAlbumRequest)
            
            switch response {
            case .success(let result):
                return Result.success(result)
            case .failure(let error):
                return Result.failure(error)
            }
        }
        
        // 問５、６
        func fetchAlbumMyAPIClientWithComp(completion: @escaping ([Album]?, Error?) -> Void) {
            let getAlbumRequest = GetAlbumsRequest()
            let myAPIClient = MyAPIClient(defaultBaseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
            myAPIClient.executeWithCompletion(getAlbumRequest, completion: completion)
        }
        
        func fetchAlbumMyAPIClientWithFuture() -> Future<GetAlbumsRequest.ResponseType, Error> {
            let getAlbumRequest = GetAlbumsRequest()
            let myAPIClient = MyAPIClient(defaultBaseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
            return myAPIClient.executeWithFuture(getAlbumRequest)
        }
        
        func fetchAlbumMyAPIClientWithAsyncThrows() async throws -> GetAlbumsRequest.ResponseType {
            let getAlbumRequest =  GetAlbumsRequest()
            let myAPIClient = MyAPIClient(defaultBaseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
            let response = try await myAPIClient.executeWithAsyncThrows(getAlbumRequest)
            return response
        }
        
        func fetchAlbumAMyPIClientWithAsyncResult() async -> Result<GetAlbumsRequest.ResponseType, any Error> {
            let getAlbumRequest = GetAlbumsRequest()
            let myAPIClient = MyAPIClient(defaultBaseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
            let response = await myAPIClient.executeWithAsyncResult(getAlbumRequest)
            
            switch response {
            case .success(let result):
                return Result.success(result)
            case .failure(let error):
                return Result.failure(error)
            }
        }
    }
}

struct AlbumView : View {
    let album: Album
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("userId: \(album.userId)")
            Text("id: \(album.id)")
            Text("title: \(album.title)")
        }
    }
}

//#Preview {
//    AlbumListPageView()
//}
