//
//  RotationAwareControllers.swift
//  screen_rotation
//
//  Created by Codex on 2026/4/9.
//

import UIKit

class RotationAwareViewController: UIViewController, ScreenOrientationConfigurable {
    var orientationPolicy: ScreenOrientationPolicy {
        .portrait
    }

    override var shouldAutorotate: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        orientationPolicy.mask
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        orientationPolicy.preferredOrientation
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScreenOrientationManager.shared.refresh(from: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ScreenOrientationManager.shared.refresh(from: self)
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        ScreenOrientationManager.shared.prepareForPresentation(of: viewControllerToPresent, from: self)
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}

final class RotationAwareNavigationController: UINavigationController, UINavigationControllerDelegate, ScreenOrientationChildProviding {
    var orientationTargetViewController: UIViewController? {
        visibleViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        ScreenOrientationManager.shared.prepareForPresentation(of: viewController, from: visibleViewController ?? self)
        super.pushViewController(viewController, animated: animated)
    }

    override var shouldAutorotate: Bool {
        visibleViewController?.shouldAutorotate ?? true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let configurable = visibleViewController as? ScreenOrientationConfigurable {
            return configurable.orientationPolicy.mask
        }
        return ScreenOrientationManager.shared.currentMask
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if let configurable = visibleViewController as? ScreenOrientationConfigurable {
            return configurable.orientationPolicy.preferredOrientation
        }
        return .portrait
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ScreenOrientationManager.shared.refresh(from: self)
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        ScreenOrientationManager.shared.refresh(from: viewController)
    }
}

final class RotationAwareTabBarController: UITabBarController, ScreenOrientationChildProviding {
    var orientationTargetViewController: UIViewController? {
        selectedViewController
    }

    override var shouldAutorotate: Bool {
        selectedViewController?.shouldAutorotate ?? true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let configurable = selectedViewController as? ScreenOrientationConfigurable {
            return configurable.orientationPolicy.mask
        }
        return ScreenOrientationManager.shared.currentMask
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ScreenOrientationManager.shared.refresh(from: self)
    }
}
