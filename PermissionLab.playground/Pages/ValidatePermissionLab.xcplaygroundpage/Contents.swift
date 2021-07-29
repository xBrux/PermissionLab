import Foundation

// 模拟数据库操作
// 收起来的快捷键：option + command + left/right
struct DB {
    static func queryRules(actionToken: String, operatorId: Int) -> [Rule] {
//        let condition1 = Condition(lhs: "operator.[subordinate]",
//                                   rhs: "mealplan.{client}.ams",
//                                   op: .In)
//
//        let condition2 = Condition(lhs: "mealplan.isTest",
//                                   rhs: "false",
//                                   op: .Equal)
//
//        let rule1 = Rule(conditions: [condition1, condition2])
//
//        return [rule1]
        
        // 测试 1
        let condition1 = Condition(lhs: "operator",
                                   rhs: "mealplan.amList",
                                   op: .In)
        
        let condition2 = Condition(lhs: "mealplan.isTest",
                                   rhs: "false",
                                   op: .Equal)
        
        let condition3 = Condition(lhs: "operator.[subordinate]",
                                   rhs: "mealplan.amList",
                                   op: .AnyIn)


        let rule1 = Rule(conditions: [condition1, condition2])
        let rule2 = Rule(conditions: [condition3])

        return [rule1, rule2]
    }
}

// 实验是：查看 mealplan 详情，权限：操作者.下级 属于 mealplan.{client}.美餐负责人（可能的设置：操作者.下级.下级 属于 mealplan.{client}.美餐负责人）

struct ResourceAgent {
    static func ShowResource(resourceToken: String, id: String) -> [String: Any]? {
        switch resourceToken {
        case "client":
            return [
                "amList": ["1", "2"]
            ]
        default:
            return nil
        }
    }
}

// 权限中心收到请求
let input = (metadata: Metadata(operatorId: 1),
             resourceToken: "mealplan",
             actionToken: "show",
             properties: ["isTest": "false", "amList": ["1", "20"]]
             )

// --------------------------------------------------------------------------

// 根据 actionToken 和 operator 查询授权规则
let rules = DB.queryRules(actionToken: input.actionToken, operatorId: input.metadata.operatorId)

// --------------------------------------------------------------------------

// 工具 function：从 rhs 中解出 resourceToken
func getResourceTokenAndPropertyNameFromRhs(_ rhs: String) -> (resourceToken: String, propertyName: String)? {
    
    var resourceToken: String
    var propertyName: String
    
    let components = rhs.components(separatedBy: ".")
    if components.count < 2 {
        return nil
    }
    
    switch components.count {
    case 2:
        resourceToken = components[0]
        propertyName = components[1]
    case 3:
        var c = components[1]
        let pattern = "\\{\\w+\\}"
        let n = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let matches = n!.matches(in: c, options: .reportProgress, range: NSRange(location: 0, length: c.count))
        if matches.count == 1 {
            c.removeFirst()//
            c.removeLast()
            resourceToken = c
            propertyName = components[2]
        } else {
            return nil
        }
    default:
        return nil
    }
    
    return (resourceToken, propertyName)
}

// 工具 function：从 rhs/lhs 中解出操作人的下级级别，nil 表示不含操作人，0 表示只含操作人，1 表示操作人的下级，2 表示操作人的下级的下级……
func getSubordinateLevelFrom(_ s: String) -> UInt? {
    let components = s.components(separatedBy: ".")
    if components.count < 1 {
        return nil
    }
    
    var level = -1
    for (index, element) in components.enumerated() {
        if index == 0 && element != "operator" {
            return nil
        } else {
            level = 0
        }
        
        if index == 1 && element != "[subordinate]" {
            return nil
        }
        
        if index >= 1 && element == "[subordinate]" {
            level += 1
        }
    }
    
    return level < 0 ? nil : UInt(level)
}

// 工具 function：从 Json 字符串解析出字典
func convertJsonStringToDictionary(text: String) -> [String:Any]? {
    if let data = text.data(using: String.Encoding.utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.init(rawValue: 0)]) as? [String:Any]
        } catch let error as NSError {
             print(error)
        }
    }
    return nil
}


// 一条条规则判断是否成立（仅考虑 allow 规则，deny 先不考虑）
var rulesAllowed = false
rules.forEach { rule in
    // rule 之间是 or 的关系，有一条 allow 就 allow
    if rulesAllowed {
        return
    }
    
    var allowed = true
    // 逐条判断 rule 里的 condition
    rule.conditions.forEach { condition in
        // condition 之间时 and 关系，有一条 not allow 则 not allow
        // 得列列 lhs 和 rhs 都有哪些类型，否则不好解析，可能会漏
    
        // 用 lhs 解析出一个 value
        // 用 rhs 解析出一个 value 或者一个 collection
        var lhsValue: String?
        var rhsValue: String?
        var lhsCollection: [String]?
        var rhsCollection: [String]?
        
        // 看看左边能不能解析出 operator 或者对应的下级列表
        var skipLeftResolve = false // TODO：这个机制不优雅，去掉
        switch getSubordinateLevelFrom(condition.lhs) {
        case 0:
            lhsValue = "\(input.metadata.operatorId)"
            skipLeftResolve = true
        case nil:
            break
        case let level:
            // TODO: 查出下级
            lhsCollection = ["2"]
            skipLeftResolve = true
        }
        
        // 看看右边能不能解析出 operator 或者对应的下级列表
        var skipRightResolve = false // TODO：这个机制不优雅，去掉
        switch getSubordinateLevelFrom(condition.rhs) {
        case 0:
            rhsValue = "\(input.metadata.operatorId)"
            skipRightResolve = true
        case nil:
            break
        case let level:
            // TODO: 查出下级
            rhsCollection = ["2"]
            skipRightResolve = true
        }
        
        enum ResolveValueCollectionResult {
            case Done
            case NoResourceTokenAndPropertyName
        }
        
        // 看看能不能解析出属性
        func resolve(value: inout String?, collection: inout [String]?, from ahs: String) -> ResolveValueCollectionResult {
            guard let resourceTokenAndPropertyName = getResourceTokenAndPropertyNameFromRhs(ahs) else {
                return .NoResourceTokenAndPropertyName
            }
    
            switch resourceTokenAndPropertyName {
            // 本资源的属性，直接在 input 中解析出值就行
            case (input.resourceToken, let propertyName):
                if propertyName.hasSuffix("List") {
                    collection = input.properties[propertyName] as? [String]
                } else {
                    value = input.properties[propertyName] as? String
                }
            // 其他资源的属性，需要找资源代理
            case (let resourceToken, let propertyName):
                
                if let otherResourceJson = input.properties[resourceToken] as? String {
                    // 直接传了 object
                    // 不支持 resource.{other}.{another}.property
                    // 只支持 resource.{other}.property
                    // TODO: 补测试
                    if let object = convertJsonStringToDictionary(text: otherResourceJson) {
                        if propertyName.hasSuffix("List") {
                            collection = object[propertyName] as? [String]
                        } else {
                            value = object[propertyName] as? String
                        }
                    }
                } else if let resourceId = input.properties["\(resourceToken)Id"] as? String {
                    // 只传了 id，需找资源代理
                    if let object = ResourceAgent.ShowResource(resourceToken: resourceToken, id: resourceId) {
                        if propertyName.hasSuffix("List") {
                            collection = object[propertyName] as? [String]
                        } else {
                            value = object[propertyName] as? String
                        }
                    }
                }
            }
            
            return .Done
        }
        
        // 如果没有解析出 operator 和下级，看看左边能不能解析出属性
        if !skipLeftResolve {
            switch resolve(value: &lhsValue, collection: &lhsCollection, from: condition.lhs) {
            case .NoResourceTokenAndPropertyName:
                lhsValue = condition.lhs
            case .Done:
                break
            }
        }
        
        // 如果没有解析出 operator 和下级，看看右边能不能解析出属性
        if !skipRightResolve {
            switch resolve(value: &rhsValue, collection: &rhsCollection, from: condition.rhs) {
            case .NoResourceTokenAndPropertyName:
                rhsValue = condition.rhs
            case .Done:
                break
            }
        }
        
        // 根据 operator，对左右 value 进行计算，判断规则是否成立
        switch condition.op {
        case .Equal:
            if let lhsValue = lhsValue, let rhsValue = rhsValue {
                lhsValue
                rhsValue
                allowed = allowed && lhsValue == rhsValue
            } else {
                allowed = allowed && false
            }
        case .In:
            if let lhsValue = lhsValue, let rhsCollection = rhsCollection {
                lhsValue
                rhsCollection
                allowed = allowed && rhsCollection.contains(lhsValue)
            } else {
                allowed = allowed && false
            }
        case .AnyIn:
            if let lhsCollection = lhsCollection, let rhsCollection = rhsCollection {
                allowed = allowed && lhsCollection.reduce(false) { result, element in
                    return result || rhsCollection.contains(element)
                }
            } else {
                allowed = allowed && false
            }
        }
    }
    rulesAllowed = rulesAllowed || allowed
    print(allowed)
}
rulesAllowed

// 关键算法 demo: 从 rhs 中解出 resourceToken
let RegularDemo = { () -> String in
    let rhs = "mealplan.{client}.ams"
    let components = rhs.components(separatedBy: ".")
    var c = components[1]
    let pattern = "\\{\\w+\\}"
    let n = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    let matches = n!.matches(in: c, options: .reportProgress, range: NSRange(location: 0, length: c.count))
    if matches.count == 1 {
        c.removeFirst()//
        c.removeLast()
        let resourceToken = c
        return resourceToken
    } else {
        return "传错了"
    }
}()

let RegularDemo2 = { () -> Int? in
    let s = "operator.[subordinate]"
    let components = s.components(separatedBy: ".")
    if components.count < 1 {
        return nil
    }
    
    var level = -1
    for (index, element) in components.enumerated() {
        if index == 0 && element != "operator" {
            return nil
        } else if element == "operator" {
            level = 0
        }
        
        if index == 1 && element != "[subordinate]" {
            return nil
        }
        
        if index >= 1 && element == "[subordinate]" {
            level += 1
        }
    }
    
    return level == -1 ? nil : level
}()

// --------------------------------------------------------------------------




// 2 权限中心校验
// 2.1 权限中心收到请求
// 2.2 根据 operator 查对应的权限
// 2.3 权限中心根据 userId 查 user 的下级 -> [下级的 list]
// 2.4 找资源代理：根据 clientId 查 {client}.美餐负责人 -> [美餐负责人 list]
// 2.5 对比 [下级的 list] 和 [美餐负责人 list]
// 2.6 如果属于则：返回条件成立
// 2.7 如果不属于则：返回条件不成立
