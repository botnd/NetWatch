import Foundation

struct NetWatchLogger {


    init(
        log: @escaping (NetWatchLogRecord) throws -> Void,
        get: @escaping () throws -> [NetWatchLogRecord]
    ) {
        self.log = log
        self.get = get
    }

    public var log: (NetWatchLogRecord) throws -> Void

    public var get: () throws -> [NetWatchLogRecord]
}



struct NetWatchLogRecord: Codable {
    let initialURL: String
    let duration: Int
    let finalURL: String
    let status: String
}
