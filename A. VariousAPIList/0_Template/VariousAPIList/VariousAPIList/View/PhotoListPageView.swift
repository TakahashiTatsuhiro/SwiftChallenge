import SwiftUI
import Combine

struct PhotoListPageView: View {
    @StateObject var viewModel: PhotoViewModel
    
    var body: some View {
        ScrollView {
            ForEach(viewModel.photoList, id: \.self) { photo in
                PhotoView(photo: photo)
                Divider()
            }
        }
        .onAppear() {
            viewModel.onAppear()
        }
    }
}

extension PhotoListPageView {
    
    class PhotoViewModel: ObservableObject {
        @Published var photoList: [Photo] = []
        private var cancellable: AnyCancellable?
                
        func onAppear() {
            // https://www.bravesoft.co.jp/blog/archives/15610
            cancellable = fetchPhotoAPIClientWithFuture()
                .sink(
                    receiveCompletion: {completion in
                        switch completion {
                        case .finished:
                            print("Finished")
                        case .failure(let error):
                            print("Failed: \(error)")
                        }
                    },
                    receiveValue: {photos in
                        self.photoList = photos
                    })
        }
        
        func fetchPhoto(completion: @escaping ([Photo]?, Error?) -> Void) {
            //参考 https://zenn.dev/masakatsu_tagi/articles/f5374dd3153bdc
            let requestUrl = URL(string: "https://jsonplaceholder.typicode.com/photos?albumId=1")!
            let task = URLSession.shared.dataTask(with: requestUrl) {data, response, error in
                if let error = error {
                    completion(nil, error)
                } else if let data = data {
                    let decoder = JSONDecoder()
                    do {
                        let decoded = try decoder.decode([Photo].self, from: data)
                        completion(decoded, nil)
                    } catch {
                        print("error")
                    }
                }
            }
            task.resume()
        }
        
        func fetchPhotoAPIClientWithComp(completion: @escaping ([Photo]?, Error?) -> Void) {
            let getPhotoRequest = GetPhotosRequest(
                parameters: ["albumId":"1"]
            )
            let apiClient = APIClientImpl(defaultBaseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
            apiClient.executeWithCompletion (
                getPhotoRequest,
                completion: completion)
        }
        
        func fetchPhotoAPIClientWithFuture() -> Future<GetPhotosRequest.ResponseType, Error> {
            let getPhotoRequest = GetPhotosRequest(
                parameters: ["albumId":"1"]
            )
            let apiClient = APIClientImpl(defaultBaseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
            return apiClient.executeWithFuture(getPhotoRequest)
        }
        
        func fetchPhotoAPIClientWithAsyncThrows() async throws -> GetPhotosRequest.ResponseType {
            let getPhotoRequest = GetPhotosRequest(
                parameters: ["albumId" : "1"]
            )
            let apiClient = APIClientImpl(defaultBaseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
            let response = try await apiClient.executeWithAsyncThrows(getPhotoRequest)
            return response
        }
        
        func fetchPhotoAPIClientWithAsyncResult() async -> Result<GetPhotosRequest.ResponseType, any Error> {
            let getPhotoRequest = GetPhotosRequest(
                parameters: ["albumId":"1"]
            )
            let apiClient = APIClientImpl(defaultBaseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
            let response = await apiClient.executeWithAsyncResult(getPhotoRequest)
            
            switch response {
            case .success(let result):
                return Result.success(result)
            case .failure(let error):
                return Result.failure(error)
            }
        }
    }
}

struct PhotoView : View {
    let photo: Photo
    
    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: photo.thumbnailUrl){ image in
                image.resizable().frame(width: 50, height: 50)
            } placeholder: {
                ProgressView()
            }
            Text("id: \(photo.id)")
            Text("albumId: \(photo.albumId)")
            Text("title: \(photo.title)")
        }
    }
}

//#Preview {
//    PhotoListPageView()
//}
