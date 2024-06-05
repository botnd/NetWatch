import Foundation
import os

extension URLSession {
    static let swizzleDataTask: Void = {
        let origSel = #selector(URLSession.init(configuration:delegate:delegateQueue:))
        let swizSel = #selector(URLSession.netWatch_init(configuration:delegate:delegateQueue:))

        let origMethod = class_getClassMethod(URLSession.self, origSel)
        let swizMethod = class_getClassMethod(URLSession.self, swizSel)

        guard let origMethod, let swizMethod else {
            os_log(.error, "NetWatch: Error swizzling URLSession.init(configuration:delegate:delegateQueue:)")
            return
        }
        method_exchangeImplementations(origMethod, swizMethod)

        let origDataTaskSel = #selector(URLSession.dataTask(with:) as (URLSession) -> (URLRequest) -> URLSessionDataTask)
        let swizDataTaskSel = #selector(URLSession.netWatch_dataTask(with:))

        let origDataTaskMethod = class_getInstanceMethod(URLSession.self, origDataTaskSel)
        let swizDataTaskMethod = class_getInstanceMethod(URLSession.self, swizDataTaskSel)

        guard let origDataTaskMethod, let swizDataTaskMethod else {
            os_log(.error, "NetWatch: Error swizzling URLSession.dataTask(with:)")
            return
        }
        method_exchangeImplementations(origDataTaskMethod, swizDataTaskMethod)
    }()

    static var netWatchLogger: NetWatchLogger?

    static func swizzleDataTask(logger: NetWatchLogger) {
        netWatchLogger = logger

        self.swizzleDataTask
    }

    @objc class func netWatch_init(
        configuration: URLSessionConfiguration,
        delegate: URLSessionDelegate?,
        delegateQueue: OperationQueue?
    ) -> URLSession {
        let delegate = NetWatchSessionDelegate(originalDelegate: delegate, logger: netWatchLogger)
        return self.netWatch_init(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
    }

    @objc func netWatch_dataTask(with urlRequest: URLRequest) -> URLSessionDataTask {
        let task = self.netWatch_dataTask(with: urlRequest)

        if let netWatchDelegate = self.delegate as? NetWatchSessionDelegate {
            netWatchDelegate.urlSession(self, didCreateTask: task)
        }

        return task
    }
}

internal final class NetWatchSessionDelegate: NSObject, URLSessionDataDelegate, URLSessionTaskDelegate {
    let originalDelegate: URLSessionDelegate?
    let dataDelegate: URLSessionDataDelegate?

    private let logger: NetWatchLogger
    internal var queue: [Int: Date] = [:]

    init(originalDelegate: URLSessionDelegate?, logger: NetWatchLogger?) {
        self.originalDelegate = originalDelegate
        self.dataDelegate = originalDelegate as? URLSessionDataDelegate

        self.logger = logger ?? .shared
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        originalDelegate?.urlSession?(session, didReceive: challenge, completionHandler: completionHandler)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        dataDelegate?.urlSession?(session, task: task, didReceive: challenge, completionHandler: completionHandler)
    }

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        self.queue[task.taskIdentifier] = Date()

        if #available(iOS 16.0, *) {
            dataDelegate?.urlSession?(session, didCreateTask: task)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        dataDelegate?.urlSession?(session, task: task, didCompleteWithError: error)

        guard error != nil else {
            return
        }

        if let originalUrl = task.originalRequest?.url?.absoluteString,
           let finalUrl = task.currentRequest?.url?.absoluteString,
           let createdDate = self.queue[task.taskIdentifier] {
            try? self.logger.log(.init(
                initialURL: originalUrl,
                duration: Int(Date().timeIntervalSince(createdDate) * 1000),
                finalURL: finalUrl,
                status: "FAILURE"
            ))
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let originalUrl = dataTask.originalRequest?.url?.absoluteString,
           let finalUrl = dataTask.currentRequest?.url?.absoluteString,
           let createdDate = self.queue[dataTask.taskIdentifier] {
            try? self.logger.log(.init(
                initialURL: originalUrl,
                duration: Int(Date().timeIntervalSince(createdDate) * 1000),
                finalURL: finalUrl,
                status: "SUCCESS"
            ))
        }

        dataDelegate?.urlSession?(session, dataTask: dataTask, didReceive: data)
    }

}
