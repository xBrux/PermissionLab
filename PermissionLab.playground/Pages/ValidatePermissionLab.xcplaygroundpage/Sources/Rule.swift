import Foundation

// 授权规则的定义
public struct Rule {
    public var conditions: [Condition]
    
    public init(conditions: [Condition]) {
        self.conditions = conditions
    }
}
