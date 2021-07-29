import Foundation

// Rule 中的成立条件
public struct Condition {
    public enum Operator {
        case Equal, In, AnyIn
    }
    
    public var lhs: String
    public var rhs: String
    public var op: Operator
    
    public init(lhs: String, rhs: String, op: Operator) {
        self.lhs = lhs
        self.rhs = rhs
        self.op = op
    }
}
