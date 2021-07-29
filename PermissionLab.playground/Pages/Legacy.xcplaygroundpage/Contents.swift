import Foundation

struct Mealplan {
    var id: String = ""
    var name: String = ""
    var clientId: Int = 1
    var projectId: Int = 2
    var city: String = ""
    var remark: String = ""
    var mealType: String = ""
    var businessType: String = ""
    var note: String = ""
    var orderPriceLimit: Int = 1
    var showPrice: Bool = true
    var allowMultipleOrder: Bool = true
    var timeZone: String = ""
    var allowPreorder: Bool = true
}

struct Metadata {
    var operatorId: Int
}

//// 后端接口
//protocol Actions {
//    // 需要根据返回值进行判断，比如返回的部门信息
//    func showMealplan(matadata:Matadata, mealplanId:Int) -> Mealplan?
//
//
//    // 城市是没办法传的，因为返回结果前调用方并不知道 mealplan 属于哪个城市
////    func showMealplan(matadata:Matadata, mealplanId:Int, city: String)
//
//
//
//
//    // 需要根据 operator 是否有 client &
//    func createMealplan(matadata:Matadata, clientId:Int, name:String, remark:String, mealType:String, city:String) -> String
//
//
//    /*
//    PremissionCenter.checkPremission(
//        resourceToken: "mealplan",
//        actionToken: "listMealplan",
//        properties:
//            [
//                "clientId":clientId
//            ]
//    )
//    */
//    func listMealplan(matadata:Matadata, clientId:Int, mealType:String)
//
//    /*
//    PremissionCenter.checkPremission(
//        resourceToken: "mealplan",
//        actionToken: "listMealplan",
//        properties:
//            [
//                "clientId":clientId,
//                "meicanStaffId": meicanStaffId
//            ]
//    )
//    */
//    func listMealplan2(matadata:Matadata, clientId:Int, meicanStaffId:Int, mealType:String)
//
//
//
//
//
//}

// BE APIs
struct Actions {
    
    func showMealplan(metadata:Metadata, mealplanId:Int) -> Mealplan? {
        // 查出 mealplan 信息，此处省略 1000 行代码
        var mealplan:Mealplan = Mealplan()
        
        
        // 将 mealplan 信息发给权限中心，让权限中心判断是否通过
        let (passed, excludedKeys) = PermissionCenter.checkPermission(
            resourceToken: "mealplan",
            actionToken: "showMealplan",
            metadata: metadata,
            properties: [
                "mealplanId": mealplan.id,
                "clientsId": mealplan.clientId,
                "projectId": mealplan.projectId
            ]
        )
        
        if passed == true {
            // 返回 mealplan 信息
            
            if excludedKeys.count > 0 {
                // 编辑一下 mealplan，该隐藏的隐藏，此处省略 100 行代码
                // example:
                excludedKeys.forEach { excludedKey in
                    mealplan.name = "****"
                }
            }
            
            return mealplan
            
        } else {
            return nil
        }
    }
    
    
    func createMealplan(metadata:Metadata, clientId:Int, name:String, remark:String, mealType:String, city:String) -> String {
        // 发一些东西给权限中心，让权限中心判断是否通过
        let (passed, _) = PermissionCenter.checkPermission(
            resourceToken: "mealplan",
            actionToken: "createMealplan",
            metadata: metadata,
            properties:
                [
                    "clientId":clientId,
                    "city":city
                ]
        )
        
        if passed == true {
            // 一通操作，创建 mealplan，此处省略 1000 行代码
            return "成功"
        } else {
            return "无权限"
        }
    }
}



class PermissionCenter {
    static func checkPermission(resourceToken:String, actionToken:String, metadata:Metadata, properties:[String:Any]) -> (passed: Bool, excludedKeys: [String]) {
        // 权限中心做一大堆权限判断
        
        // 查询授权规则
        let rules = showPermissionRule(resourceToken: resourceToken, actionToken: actionToken, operator: metadata.operatorId)
        
        func getResourceIdFromProperties(token: String) -> Int? {
            guard let id = properties[token + "Id"] as? Int else {
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
            
                // 做了一大堆成立条件的解析工作
                let resourceToken = "client"
                guard let resourceId = getResourceIdFromProperties(token: resourceToken) else {
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
    
    static func permissionAgentURL(resourceToken:String) -> NSURL {
        // 查表，查出资源的代理 URL
        return NSURL()
    }
    
    static func showPermissionRule(resourceToken:String, actionToken:String, operator:Int) -> [Rule] {
        
        // 查出了规则,并返回
        let condition1 = Condition(lhs: "operator", rhs: "mealplan.{client}.ams", op: .In)
        let condition2 = Condition(lhs: "operator", rhs: "mealplan.{project}.ams", op: .In)
        let condition3 = Condition(lhs: "mealplan.isTest", rhs: "false", op: .Equal)
        
        let rule1 = Rule(conditions: [condition1, condition2, condition3])

        return [rule1]
    }
}

// 授权规则的定义
struct Rule {
    var conditions: [Condition]
}

struct Condition {
    enum Operator {
        case Equal, In
    }
    
    var lhs: String
    var rhs: String
    var op: Operator
}


class PermissionAgent {
    
    let url: NSURL
    
    init(url:NSURL) {
        self.url = url
    }
    
    // 根据资源 id，查出资源的属性
    func showResource(token: String, id: Int) -> [String:String] {
        return [:]
    }
}

// 1.1 - 创建 mealplan，未配置任何 rules
// 3.5 - 权限中心增加 rule：判断 mealplan 的城市，线上 API 崩了
// 35 行传的东西和 rules 有关，那么 ⚠️ 问题是：IT 部门增加了 1 条 rule，所有相关接口都需要改
// 业务每个接口都传的参数 list（是资源的全部属性）, 那么一旦新增了属性，所有相关的接口都需要改


// 最终方案：业务传参时，属性列表中的是 optional 的，根据所传的属性判断是否 allow.(那么 deny 是否需要检验？)





//查看用餐计划设置：
//   基本信息
//    / 用餐计划名；
//    / 用餐计划备注；
//    / 所属餐次；
//    / 业务类型；
//    / 查看用餐计划记事板；
//    用餐计划点餐设置
//    / 餐饮标准；
//    / 是否隐藏价格；
//    / 允许多次下单；
//    / 时区；
//    / 允许预定点餐；
//    / 点餐时段（分成另一个实体？）；
//   用餐计划支付设置；
//   用餐计划统计设置：
//    / 就餐类型 ；
//    / 营运区域；
//    / ……
//    用餐计划高级设置：
//    / 需要管理员确认订单；





Actions().showMealplan(metadata: Metadata(operatorId: 1), mealplanId: 1)

//


// todo：需要再模拟一个上下级的场景


let test1: UInt8 = 1
let test2 = "1"
let test3 = Int(test2)

let c:Character = "a"
