import Foundation

public typealias ConfigurationBlock = (To<Result<UIViewController>>) -> Void

public struct Navigation {
    @discardableResult public static func present(_ configuration: ConfigurationBlock) -> Navigation.Type {
        configuration(To<Result<UIViewController>>(.present))
        
        return self
    }
    
    @discardableResult public static func push(_ configuration: ConfigurationBlock) -> Navigation.Type {
        configuration(To<Result<UIViewController>>(.push))
        
        return self
    }
}
