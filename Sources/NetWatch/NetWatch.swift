import Foundation

@objcMembers
final public class NetWatch: NSObject {
    @objc(configure)
    public static func configure() {
        URLSession.swizzleDataTask(logger: .shared)
    }
}
