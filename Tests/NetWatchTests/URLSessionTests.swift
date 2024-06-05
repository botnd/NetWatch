import XCTest
@testable import NetWatch

final class URLSessionTests: XCTestCase {
    override class func setUp() {
        NetWatch.configure()
    }

    private var request: URLRequest {
        .init(url: URL(string: "http://localhost/")!)
    }

    private var successExpectation: XCTestExpectation?
    private var failureExpectation: XCTestExpectation?

    func testURLSessionErrorIsPropagated() async throws {
        failureExpectation = expectation(description: "Expecting error")

        let delegate = Delegate()
        delegate.onFailure = { [weak self] _ in
            self?.failureExpectation?.fulfill()
        }

        let urlSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

        let dataTask = urlSession.dataTask(with: request)
        dataTask.resume()

        await fulfillment(of: [failureExpectation!], timeout: 2)
    }

    func testURLSessionSuccessIsPropagated() async throws {
        successExpectation = expectation(description: "Expecting success response")

        let delegate = Delegate()
        delegate.onSuccess = { [weak self] _ in
            self?.successExpectation?.fulfill()
        }

        let urlSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

        let dataTask = urlSession.dataTask(with: .init(url: .init(string: "http://example.com")!))
        dataTask.resume()

        await fulfillment(of: [successExpectation!], timeout: 2)
    }

    func testDataTaskIsSwizzled() async throws {
        let urlSession = URLSession(configuration: .default)

        let dataTask = urlSession.dataTask(with: request)

        guard let delegate = urlSession.delegate as? NetWatchSessionDelegate else {
            XCTFail("Expected NetWatch delegate")
            return
        }

        XCTAssert(delegate.queue.keys.contains(dataTask.taskIdentifier))
        XCTAssertEqual(dataTask.currentRequest, request)
    }
}

extension URLSessionTests {
    func testSuccessIsLogged() async throws {
        successExpectation = expectation(description: "Expecting success log")
        let request = URLRequest(url: .init(string: "http://example.com")!)

        URLSession.netWatchLogger?.log = { [weak self] record in
            if record.initialURL == request.url?.absoluteString,
               record.status == "SUCCESS" {
                self?.successExpectation?.fulfill()
            }
        }

        let urlSession = URLSession(configuration: .default)

        let dataTask = urlSession.dataTask(with: request)
        dataTask.resume()

        await fulfillment(of: [successExpectation!], timeout: 2)
    }

    func testErrorIsLogged() async throws {
        failureExpectation = expectation(description: "Expecting error to be logged")

        URLSession.netWatchLogger?.log = { [weak self] record in
            if record.initialURL == self?.request.url?.absoluteString,
               record.status == "FAILURE" {
                self?.failureExpectation?.fulfill()
            }
        }

        let urlSession = URLSession(configuration: .default)
        let dataTask = urlSession.dataTask(with: request)
        dataTask.resume()

        await fulfillment(of: [failureExpectation!], timeout: 2)
    }
}

extension URLSessionTests {
    class Delegate: NSObject, URLSessionDataDelegate {
        var onSuccess: ((URLSessionDataTask) -> Void)?
        var onFailure: ((URLSessionTask) -> Void)?

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            onSuccess?(dataTask)
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
            if error != nil {
                onFailure?(task)
            }
        }

        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
