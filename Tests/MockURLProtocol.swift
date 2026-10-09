import Foundation

/// Intercepta todas as requisições URLSession em testes.
final class MockURLProtocol: URLProtocol {
    struct Response {
        let data: Data
        let statusCode: Int
    }

    static var handlers: [URL: Response] = [:]
    static var networkError: Error? = nil
    /// URLs pedidas, em ordem (zerar no setUp).
    static var requestedURLs: [URL] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        defer { client?.urlProtocolDidFinishLoading(self) }
        if let u = request.url { MockURLProtocol.requestedURLs.append(u) }

        if let error = MockURLProtocol.networkError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        guard let url = request.url, let handler = MockURLProtocol.handlers[url] else {
            client?.urlProtocol(self, didFailWithError: URLError(.fileDoesNotExist))
            return
        }

        let resp = HTTPURLResponse(url: url, statusCode: handler.statusCode,
                                   httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: handler.data)
    }

    override func stopLoading() {}
}
