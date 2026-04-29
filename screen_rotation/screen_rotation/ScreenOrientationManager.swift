//
//  ScreenOrientationManager.swift
//  screen_rotation
//
//  Created by Codex on 2026/4/9.
//

import UIKit

enum ScreenOrientationPolicy: Equatable {
    case portrait
    case landscape
    case allButUpsideDown
    case custom(mask: UIInterfaceOrientationMask, preferred: UIInterfaceOrientation)

    var mask: UIInterfaceOrientationMask {
        switch self {
        case .portrait:
            return .portrait
        case .landscape:
            return .landscape
        case .allButUpsideDown:
            return .allButUpsideDown
        case let .custom(mask, _):
            return mask
        }
    }

    var preferredOrientation: UIInterfaceOrientation {
        switch self {
        case .portrait:
            return .portrait
        case .landscape:
            return .landscapeRight
        case .allButUpsideDown:
            return .portrait
        case let .custom(_, preferred):
            return preferred
        }
    }
}

protocol ScreenOrientationConfigurable where Self: UIViewController {
    var orientationPolicy: ScreenOrientationPolicy { get }
}

protocol ScreenOrientationChildProviding where Self: UIViewController {
    var orientationTargetViewController: UIViewController? { get }
}

final class ScreenOrientationManager {
    static let shared = ScreenOrientationManager()

    private(set) var currentPolicy: ScreenOrientationPolicy = .portrait
    weak var windowScene: UIWindowScene?

    var currentMask: UIInterfaceOrientationMask {
        currentPolicy.mask
    }

    var currentInterfaceOrientation: UIInterfaceOrientation {
        if let orientation = windowScene?.interfaceOrientation, orientation != .unknown {
            return orientation
        }

        let sceneWindows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)

        if let orientation = sceneWindows.first(where: \.isKeyWindow)?.windowScene?.interfaceOrientation,
           orientation != .unknown {
            return orientation
        }

        return currentPolicy.preferredOrientation
    }

    private init() {}

    func attach(windowScene: UIWindowScene) {
        self.windowScene = windowScene
    }

    func refresh(from viewController: UIViewController? = nil) {
        let sourceViewController = viewController ?? topViewController()
        let nextPolicy = resolvePolicy(from: sourceViewController)
        apply(policy: nextPolicy, sourceViewController: sourceViewController)
    }

    func prepareForPresentation(of viewController: UIViewController, from sourceViewController: UIViewController?) {
        let nextPolicy = resolvePolicy(from: viewController)
        apply(policy: nextPolicy, sourceViewController: sourceViewController)
    }

    private func apply(policy nextPolicy: ScreenOrientationPolicy, sourceViewController: UIViewController?) {
        guard nextPolicy != currentPolicy else {
            notifySupportedOrientationChanged(for: sourceViewController)
            return
        }

        currentPolicy = nextPolicy
        notifySupportedOrientationChanged(for: sourceViewController)
        applyRotationIfNeeded()
    }

    private func resolvePolicy(from viewController: UIViewController?) -> ScreenOrientationPolicy {
        guard let viewController else { return .portrait }

        if let presentedViewController = viewController.presentedViewController {
            return resolvePolicy(from: presentedViewController)
        }

        if let childProvider = viewController as? ScreenOrientationChildProviding {
            return resolvePolicy(from: childProvider.orientationTargetViewController)
        }

        if let navigationController = viewController as? UINavigationController {
            return resolvePolicy(from: navigationController.visibleViewController)
        }

        if let tabBarController = viewController as? UITabBarController {
            return resolvePolicy(from: tabBarController.selectedViewController)
        }

        if let configurable = viewController as? ScreenOrientationConfigurable {
            return configurable.orientationPolicy
        }

        return .portrait
    }

    private func topViewController() -> UIViewController? {
        let sceneWindows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        let candidateWindow = windowScene?.windows.first(where: \.isKeyWindow) ?? sceneWindows.first(where: \.isKeyWindow)
        return candidateWindow?.rootViewController
    }

    private func applyRotationIfNeeded() {
        if #available(iOS 16.0, *) {
            UIViewController.attemptRotationToDeviceOrientation()
            let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: currentPolicy.mask)
            windowScene?.requestGeometryUpdate(preferences) { error in
                assertionFailure("Failed to update interface orientation: \(error.localizedDescription)")
            }
            return
        }

        UIDevice.current.setValue(currentPolicy.preferredOrientation.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }

    private func notifySupportedOrientationChanged(for viewController: UIViewController?) {
        guard let viewController else { return }

        if #available(iOS 16.0, *) {
            viewController.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}
