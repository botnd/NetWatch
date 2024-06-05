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

extension NetWatchLogger {
    static var logsDir: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0]
    }

    static var defaultLogsFilename: String {
        "new_watch_logs.plist"
    }
}

struct NetWatchLogRecord: Codable {
    let initialURL: String
    let duration: Int
    let finalURL: String
    let status: String
}
