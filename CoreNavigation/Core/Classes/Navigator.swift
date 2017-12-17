import UIKit
#if ROUTING
import CoreRoute
#endif

class Navigator<FromViewController: UIViewController, ToViewController: UIViewController, EmbeddingViewController: UIViewController> {
    typealias NavigationResponse = Response<FromViewController, ToViewController, EmbeddingViewController>
    
    private let configuration: Configuration.Base<FromViewController, ToViewController, EmbeddingViewController>
    
    init(configuration: Configuration.Base<FromViewController, ToViewController, EmbeddingViewController>) {
        self.configuration = configuration
    }
    
    @discardableResult func execute(_ completion: ((NavigationResponse?) -> Void)?) -> NavigationResponse? {
        guard let response: Response<FromViewController, ToViewController, EmbeddingViewController> = {
            switch configuration.action {
            case .present:
                return self.present(completion)
            case .push:
                return self.push(completion)
            case .response:
                return self.response()
            }
        }() else { return nil }
        
        configuration.result.successBlocks.forEach { (block) in
            block(response)
        }
        
        return nil
    }
    
    private func present(_ completion: ((NavigationResponse?) -> Void)?) -> NavigationResponse? {
        guard let fromViewController = fromViewController as? FromViewController else { return nil }
        
        @discardableResult func response(with toViewController: ToViewController, completion: ((NavigationResponse?) -> Void)?) -> NavigationResponse? {
            let response = NavigationResponse(fromViewController: fromViewController, toViewController: toViewController, embeddingViewController: nil)
            
            let destinationViewController = embeddingViewController(with: response) ?? toViewController
            
            let animated = configuration.transition.animated ?? true
            let transitioningDelegate = configuration.transition.viewControllerTransitioningDelegate
            
            fromViewController.transitioningDelegate = transitioningDelegate
            
            cache(viewController: toViewController)
            bindEvents(to: toViewController)
            
            fromViewController.present(destinationViewController, animated: animated, completion: { [weak self] in
                guard let `self` = self else { return }
                
                self.configuration.transition.completionBlocks.forEach({ (transitionCompletionBlock) in
                    transitionCompletionBlock()
                })
            })
            
            return response
        }
        
        guard let toViewController = getToViewController({ (toViewController) in
            if let toViewController = toViewController {
                response(with: toViewController, completion: completion)
            }
        }) else { return nil }
        
        return response(with: toViewController, completion: nil)
    }
    
    private func push(_ completion: ((NavigationResponse?) -> Void)?) -> NavigationResponse? {
        
        guard
            let fromViewController = fromViewController as? FromViewController,
            let navigationController = fromViewController.navigationController ?? (fromViewController as? UINavigationController)
            else {
                return nil
        }
        
        @discardableResult func response(with toViewController: ToViewController, completion: ((NavigationResponse?) -> Void)?) -> NavigationResponse? {
            let response = NavigationResponse(fromViewController: fromViewController, toViewController: toViewController, embeddingViewController: nil)
            
            let destinationViewController = embeddingViewController(with: response) ?? toViewController
            
            let animated = configuration.transition.animated ?? true
            
            cache(viewController: toViewController)
            bindEvents(to: toViewController)
            
            navigationController.pushViewController(destinationViewController, animated: animated) { [weak self] in
                guard let `self` = self else { return }
                
                self.configuration.transition.completionBlocks.forEach({ (completion) in
                    completion()
                })
            }
            
            return response
        }
        
        guard let toViewController = getToViewController({ (toViewController) in
            if let toViewController = toViewController {
                response(with: toViewController, completion: completion)
            }
        }) else { return nil }
        
        return response(with: toViewController, completion: nil)
    }
    
    private func response() -> Response<FromViewController, ToViewController, EmbeddingViewController>? {
        return nil
    }
    
    private var fromViewController: UIViewController? {
        return
            (configuration.origin.fromViewController as? FromViewController) ??
            UIViewController.currentViewController
    }
    private func getToViewController(_ toViewControllerBlock: @escaping (ToViewController?) -> Void) -> ToViewController? {
        var cachedViewController: ToViewController? {
            guard let (_, identifier) = configuration.life.value else { return nil }
            
            let toViewController = Cache.shared.viewController(for: identifier) as? ToViewController
            toViewControllerBlock(toViewController)
            
            return toViewController
        }
        
        guard let target = configuration.destination.target else { return nil }
        
        
        let toViewController: ToViewController? = {
            guard let target = target as? ToViewController else { return nil }
            
            return target
        }()
        
        #if ROUTING
        func _route(to route: AbstractRoute, in router: Router) -> ToViewController? {
            let request = Request<String, Any?>(route: route.routePath)
            
            var _toViewController: ToViewController?
            
            router.request(request)
                .onSuccess({ (response) in
                    if let destination = response.destination as? ToViewController {
                        _toViewController = destination
                    } else if let destination = response.destination as? ToViewController.Type {
                        _toViewController = destination.init(nibName: nil, bundle: nil)
                    }
                    
                    toViewControllerBlock(_toViewController)
                })
                .execute()
            
            return _toViewController
        }
        #endif
        
        guard let viewController = cachedViewController ?? toViewController else {
            #if ROUTING
            if let (route, router) = target as? (AbstractRoute, Router) {
                if let _toViewController = _route(to: route, in: router) {
                    return _toViewController
                }
            }
            #endif
            
            return nil
        }
        
        return viewController
    }
    private func embeddingViewController(with response: NavigationResponse) -> EmbeddingViewController? {
        guard let type = configuration.embedding.embeddableViewControllerType else { return nil }
        
        let _response = unsafeDowncast(response, to: Response<UIViewController, UIViewController, UIViewController>.self)
        
        let embeddingViewController: EmbeddingViewController? = (type.init(with: _response) as? EmbeddingViewController)
        
        response.embeddingViewController = embeddingViewController
        
        return embeddingViewController
    }
    
    // helpers
    
    private func bindEvents(to viewController: UIViewController) {
        // append events
        let viewControllerEvents = ViewControllerEvents()
        let event = configuration.event
        
        event.viewControllerEventBlocks.forEach { (eventBlock) in
            eventBlock(event, viewController)
        }
        event.bind(viewControllerEvents)
        viewController.events = viewControllerEvents
    }
    
    private func cache(viewController: UIViewController) {
        if
            let (lifetime, identifier) = configuration.life.value
        {
            Cache.shared.add(identifier: identifier, viewController: viewController, lifetime: lifetime)
        }
    }
}
