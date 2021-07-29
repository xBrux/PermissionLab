import Foundation

public struct PermissionCenterUser {
    public var id: Int
    public var name: String
    public var role: String
    public var leaders: [PermissionCenterUser]
    
    public init(id: Int, name: String, role: String, leaders: [PermissionCenterUser]) {
        self.id = id
        self.name = name
        self.role = role
        self.leaders = leaders
    }
}

