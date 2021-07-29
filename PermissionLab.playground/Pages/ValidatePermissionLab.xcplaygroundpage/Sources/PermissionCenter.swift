import Foundation

public extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


public struct PermissionCenter {
    
    let getPermissionRule: () -> [Rule]?
    
    public init(getPermissionRule: @escaping () -> [Rule]?) {
        self.getPermissionRule = getPermissionRule
    }
    
    public func checkPermission(resourceToken:String, actionToken:String, metadata:Metadata, properties:[String:Any]) -> (passed: Bool, excludedKeys: [String]) {
        
        
        // 根据 actionToken 和 operator 查询授权规则
        let rules = showPermissionRule(resourceToken: resourceToken, actionToken: actionToken, operator: metadata.operatorId)
        
        func getResourceIdFromProperties(resourceToken: String) -> Int? {
            guard let id = properties[resourceToken + "Id"] as? Int else {
                // 必传字段没传
                return nil
            }
            
            // 开始解析，从 rn 里拆出各种成分
            return id
        }
        
        
        var deny = false
        
        // 一条条规则判断是否成立
        rules.forEach { rule in
            
            // 挑出含父级的成立条件, 并一条条判断是否成立
            rule.conditions.filter { _ in true }.forEach { condition in
                
                let conditionComponents = condition.rhs.components(separatedBy: ".")
//                let a = conditionComponents[safe: 1]![0]
            
                // 做了一大堆成立条件的解析工作
                let resourceToken = "client"
                guard let resourceId = getResourceIdFromProperties(resourceToken: resourceToken) else {
                    // 条件不成立
                    deny = true
                    return
                }
                
                // 查资源代理
                let permissionAgentURL = permissionAgentURL(resourceToken: resourceToken)
                
                // 管资源代理要资源属性
                let permissionAgent = PermissionAgent(url: permissionAgentURL)
                let resource = permissionAgent.showResource(token: resourceToken, id: resourceId)
                
                // 判断成立条件是否成立
                
            }
        }
        
        // 获取有父级资源的规则
        
        
        return (passed: !deny, excludedKeys: [])
    }
    
    func permissionAgentURL(resourceToken:String) -> NSURL {
        // 查表，查出资源的代理 URL
        return NSURL()
    }
    
    func showPermissionRule(resourceToken:String, actionToken:String, operator:Int) -> [Rule] {
    
        
//        // 查出了规则,并返回
//        let condition1 = Condition(lhs: "operator", rhs: "mealplan.{client}.ams", op: .In)
//        let condition2 = Condition(lhs: "operator", rhs: "mealplan.{project}.ams", op: .In)
//        let condition3 = Condition(lhs: "mealplan.isTest", rhs: "false", op: .Equal)
//
//        let rule1 = Rule(conditions: [condition1, condition2, condition3])
        
        // 模拟查询，查出了规则，返回
        return getPermissionRule() ?? [Rule(conditions: [])]
    }
}



