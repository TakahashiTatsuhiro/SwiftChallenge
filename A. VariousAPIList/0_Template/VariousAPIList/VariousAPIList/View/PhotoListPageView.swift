import SwiftUI

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
            Task {
                try await viewModel.onAppear()
            }
        }
    }
}

extension PhotoListPageView {
    
    class PhotoViewModel: ObservableObject {
        @Published var photoList: [Photo] = []
                
        func onAppear() async throws {
            Task {
                let response = await fetchPhotoAPIClient_withAsyncResult()
                switch response {
                case .success(let result):
                    self.photoList = result
                case .failure(let error):
                    throw error
                }
            }
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
        
        func fetchPhotoAPIClient_withComp(completion: @escaping ([Photo]?, Error?) -> Void) {
            let getPhotoRequest = GetPhotosRequest(
                parameters: ["albumId":"1"]
            )
            let apiClient = APIClientImpl()
            apiClient.executeWithCompletion (
                getPhotoRequest,
                completion: completion)
        }
        
        func fetchPhotoAPIClient_withAsyncThrows() async throws -> GetPhotosRequest.ResponseType {
            let getPhotoRequest = GetPhotosRequest(
                parameters: ["albumId" : "1"]
            )
            let apiClient = APIClientImpl()
            let response = try await apiClient.executeWithAsyncThrows(getPhotoRequest)
            return response
        }
        
        func fetchPhotoAPIClient_withAsyncResult() async -> Result<GetPhotosRequest.ResponseType, any Error> {
            let getPhotoRequest = GetPhotosRequest(
                parameters: ["albumId":"1"]
            )
            let apiClient = APIClientImpl()
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
