import UIKit
import Quick
import Nimble

@testable import CoreNavigation

class PresentSpec: QuickSpec {
    override func spec() {
        describe("Navigation") {
            context("when presenting without animation", {
                let viewController = UIViewController()
                
                var completionInvokes = 0
                
                Navigation.present({ $0
                    .to(viewController)
                    .animated(false)
                    .completion {
                        completionInvokes.invoke()
                    }
                })
                
                it("is presented", closure: {
                    expect(completionInvokes.isInvokedOnce).to(beTrue())
                })
            })
            
            context("when presenting animated", {
                let viewController = UIViewController()
                
                var completionInvokes = 0
                
                Navigation.present({ $0
                    .to(viewController)
                    .animated(true)
                    .completion {
                        completionInvokes.invoke()
                    }
                })
                
                it("is presented", closure: {
                    expect(completionInvokes.isInvokedOnce).to(beTrue())
                })
            })
        }
    }
}
