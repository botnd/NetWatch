import XCTest
import Foundation
@testable import NetWatch

final class NetWatchLoggerTests: XCTestCase {
    private var logger: NetWatchLogger = .shared

    func testLogCreatesFile() throws {
        try? FileManager.default.removeItem(at: NetWatchLogger.logsFileUrl)

        let record = NetWatchLogRecord(
            initialURL: UUID().uuidString,
            duration: 200,
            finalURL: UUID().uuidString,
            status: "TEST"
        )
        try logger.log(record)

        if #available(iOS 16.0, *) {
            XCTAssert(FileManager.default.fileExists(atPath: NetWatchLogger.logsFileUrl.path()))
        } else {
            XCTAssert(FileManager.default.fileExists(atPath: NetWatchLogger.logsFileUrl.path))
        }

        let logs = try PropertyListDecoder().decode([NetWatchLogRecord].self,
                                                    from: Data(contentsOf: NetWatchLogger.logsFileUrl))

        XCTAssertEqual(logs.first, record)
    }

    func testLogAppendsToFile() throws {
        try? FileManager.default.removeItem(at: NetWatchLogger.logsFileUrl)

        let count = (50...100).randomElement()!
        var dummies = [NetWatchLogRecord]()
        for i in 0..<count {
            dummies.append(.init(
                initialURL: UUID().uuidString,
                duration: i * 100,
                finalURL: UUID().uuidString,
                status: UUID().uuidString
            ))
        }
        try PropertyListEncoder().encode(dummies).write(to: NetWatchLogger.logsFileUrl)

        let record = NetWatchLogRecord(
            initialURL: UUID().uuidString,
            duration: 800,
            finalURL: UUID().uuidString,
            status: "SUCCESS"
        )
        try logger.log(record)

        let records = try PropertyListDecoder().decode([NetWatchLogRecord].self,
                                                       from: Data(contentsOf: NetWatchLogger.logsFileUrl))

        XCTAssertEqual(records.count, count + 1)

        XCTAssertEqual(records.last, record)
    }
}

extension NetWatchLogRecord: Equatable {
    public static func == (lhs: NetWatchLogRecord, rhs: NetWatchLogRecord) -> Bool {
        lhs.initialURL == rhs.initialURL &&
        lhs.finalURL == rhs.finalURL &&
        lhs.duration == rhs.duration &&
        lhs.status == rhs.status
    }
}
