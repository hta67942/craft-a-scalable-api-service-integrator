import Foundation

// API Service Integrator Protocol
protocol APIServiceIntegrator {
    associatedtype ServiceProvider
    associatedtype ServiceResponse
    
    var serviceProvider: ServiceProvider { get set }
    var request: URLRequest { get set }
    
    func integrate(request: URLRequest, completion: @escaping (ServiceResponse) -> Void) -> Void
}

// Scalable API Service Integrator Class
class ScalableAPIServiceIntegrator<T: ServiceProvider, U: Decodable>: APIServiceIntegrator {
    var serviceProvider: T
    var request: URLRequest
    
    init(serviceProvider: T, request: URLRequest) {
        self.serviceProvider = serviceProvider
        self.request = request
    }
    
    func integrate(request: URLRequest, completion: @escaping (U) -> Void) -> Void {
        serviceProvider.provider(request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(U.init(from: Data())!) // Return default value or throw error
                return
            }
            
            guard let data = data else {
                print("No data returned")
                completion(U.init(from: Data())!) // Return default value or throw error
                return
            }
            
            do {
                let response = try JSONDecoder().decode(U.self, from: data)
                completion(response)
            } catch {
                print("Error decoding response: \(error.localizedDescription)")
                completion(U.init(from: Data())!) // Return default value or throw error
            }
        }
    }
}

// ServiceProvider Protocol
protocol ServiceProvider {
    func provider(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> Void
}

// ExampleServiceProvider Class
class ExampleServiceProvider: ServiceProvider {
    func provider(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> Void {
        // Implement your networking logic here
        // For example, using URLSession
        URLSession.shared.dataTask(with: request) { data, response, error in
            completion(data, response, error)
        }.resume()
    }
}

// Example Usage
struct User: Decodable {
    let id: Int
    let name: String
    let email: String
}

let request = URLRequest(url: URL(string: "https://example.com/api/users")!, cachePolicy: .useProtocolCachePolicy)
let serviceProvider = ExampleServiceProvider()
let apiServiceIntegrator = ScalableAPIServiceIntegrator(serviceProvider: serviceProvider, request: request)

apiServiceIntegrator.integrate(request: request) { (user: User) in
    print("Received user: \(user)")
}