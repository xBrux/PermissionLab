import Foundation

struct PermissionAgent {
    
    public let url: NSURL
    
    public init(url:NSURL) {
        self.url = url
    }
    
    // 根据资源 id，查出资源的属性
    public func showResource(token: String, id: Int) -> [String:String] {
        return [:]
    }
}
