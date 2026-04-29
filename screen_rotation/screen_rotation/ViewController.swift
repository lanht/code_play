//
//  ViewController.swift
//  screen_rotation
//
//  Created by fengwuhen on 2026/4/9.
//

import UIKit

final class ViewController: RotationAwareViewController {

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let modeSegmentedControl = UISegmentedControl(items: ["竖屏", "横屏", "自由旋转"])
    private let applyButton = UIButton(type: .system)
    private let presentButton = UIButton(type: .system)
    private let tipsLabel = UILabel()

    private var selectedPolicy: ScreenOrientationPolicy = .portrait

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Screen Rotation"
        view.backgroundColor = .systemBackground
        configureViews()
        layoutViews()
        applySelectedPolicy()
    }

    override var orientationPolicy: ScreenOrientationPolicy {
        selectedPolicy
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.first(where: { $0.name == "heroGradient" })?.frame = view.bounds
    }

    private func configureViews() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "heroGradient"
        gradientLayer.colors = [
            UIColor.systemTeal.withAlphaComponent(0.18).cgColor,
            UIColor.systemBackground.cgColor,
            UIColor.systemOrange.withAlphaComponent(0.12).cgColor
        ]
        gradientLayer.locations = [0, 0.55, 1]
        view.layer.insertSublayer(gradientLayer, at: 0)

        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.text = "工程级屏幕旋转"
        titleLabel.numberOfLines = 0

        descriptionLabel.font = .systemFont(ofSize: 16, weight: .regular)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = "统一由 ScreenOrientationManager 管控，页面只声明自己的旋转策略，导航和模态场景都会自动跟随。"

        modeSegmentedControl.selectedSegmentIndex = 0
        modeSegmentedControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)

        configurePrimaryButton(applyButton, title: "应用当前策略")
        applyButton.addTarget(self, action: #selector(applyButtonTapped), for: .touchUpInside)

        configureSecondaryButton(presentButton, title: "Push 横屏演示页")
        presentButton.addTarget(self, action: #selector(presentButtonTapped), for: .touchUpInside)

        tipsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        tipsLabel.textColor = .secondaryLabel
        tipsLabel.numberOfLines = 0
        tipsLabel.text = "建议在模拟器里分别试试 push、返回前台和系统旋转，当前顶层页面会重新收敛到自己的策略。"
    }

    private func layoutViews() {
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 24

        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            descriptionLabel,
            modeSegmentedControl,
            applyButton,
            presentButton,
            tipsLabel
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 18

        view.addSubview(cardView)
        cardView.addSubview(stackView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            stackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24)
        ])
    }

    @objc
    private func modeChanged() {
        switch modeSegmentedControl.selectedSegmentIndex {
        case 1:
            selectedPolicy = .landscape
        case 2:
            selectedPolicy = .allButUpsideDown
        default:
            selectedPolicy = .portrait
        }
    }

    @objc
    private func applyButtonTapped() {
        applySelectedPolicy()
    }

    @objc
    private func presentButtonTapped() {
        navigationController?.pushViewController(LandscapeDemoViewController(), animated: true)
    }

    private func applySelectedPolicy() {
        ScreenOrientationManager.shared.refresh(from: self)
    }

    private func configurePrimaryButton(_ button: UIButton, title: String) {
        if #available(iOS 15.0, *) {
            button.configuration = .filled()
            button.configuration?.title = title
        } else {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .systemBlue
            button.layer.cornerRadius = 12
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        }
    }

    private func configureSecondaryButton(_ button: UIButton, title: String) {
        if #available(iOS 15.0, *) {
            button.configuration = .tinted()
            button.configuration?.title = title
        } else {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.systemBlue, for: .normal)
            button.backgroundColor = .systemBlue.withAlphaComponent(0.12)
            button.layer.cornerRadius = 12
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        }
    }
}

final class LandscapeDemoViewController: RotationAwareViewController {

    private let label = UILabel()
    private let dismissButton = UIButton(type: .system)
    private let pushPortraitButton = UIButton(type: .system)
    private let pushFlexibleButton = UIButton(type: .system)

    override var orientationPolicy: ScreenOrientationPolicy {
        .landscape
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Landscape Demo"
        view.backgroundColor = .black

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "这个页面锁定横屏"
        label.textColor = .white
        label.font = .systemFont(ofSize: 30, weight: .bold)

        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 15.0, *) {
            dismissButton.configuration = .filled()
            dismissButton.configuration?.title = "关闭"
        } else {
            dismissButton.setTitle("关闭", for: .normal)
            dismissButton.setTitleColor(.white, for: .normal)
            dismissButton.backgroundColor = .systemBlue
            dismissButton.layer.cornerRadius = 12
            dismissButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
        }
        dismissButton.addTarget(self, action: #selector(closePage), for: .touchUpInside)

        pushPortraitButton.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 15.0, *) {
            pushPortraitButton.configuration = .tinted()
            pushPortraitButton.configuration?.title = "Push 竖屏演示页"
        } else {
            pushPortraitButton.setTitle("Push 竖屏演示页", for: .normal)
            pushPortraitButton.setTitleColor(.white, for: .normal)
            pushPortraitButton.backgroundColor = .systemOrange
            pushPortraitButton.layer.cornerRadius = 12
            pushPortraitButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
        }
        pushPortraitButton.addTarget(self, action: #selector(openPortraitPage), for: .touchUpInside)

        pushFlexibleButton.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 15.0, *) {
            pushFlexibleButton.configuration = .tinted()
            pushFlexibleButton.configuration?.title = "Push 自由旋转页"
        } else {
            pushFlexibleButton.setTitle("Push 自由旋转页", for: .normal)
            pushFlexibleButton.setTitleColor(.white, for: .normal)
            pushFlexibleButton.backgroundColor = .systemGreen
            pushFlexibleButton.layer.cornerRadius = 12
            pushFlexibleButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
        }
        pushFlexibleButton.addTarget(self, action: #selector(openFlexiblePage), for: .touchUpInside)

        view.addSubview(label)
        view.addSubview(dismissButton)
        view.addSubview(pushPortraitButton)
        view.addSubview(pushFlexibleButton)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            dismissButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dismissButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 24),
            pushPortraitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pushPortraitButton.topAnchor.constraint(equalTo: dismissButton.bottomAnchor, constant: 16),
            pushFlexibleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pushFlexibleButton.topAnchor.constraint(equalTo: pushPortraitButton.bottomAnchor, constant: 16)
        ])
    }

    @objc
    private func closePage() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func openPortraitPage() {
        // 需要切回 push 时，把下面这一行恢复即可。
        // navigationController?.pushViewController(PortraitDemoViewController(), animated: true)

        let portraitController = PortraitDemoViewController()
        let navigationController = RotationAwareNavigationController(rootViewController: portraitController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }

    @objc
    private func openFlexiblePage() {
        let preferredOrientation = ScreenOrientationManager.shared.currentInterfaceOrientation
        navigationController?.pushViewController(
            FlexibleDemoViewController(preferredOrientation: preferredOrientation),
            animated: true
        )
    }
}

final class PortraitDemoViewController: RotationAwareViewController {

    private let label = UILabel()
    private let closeButton = UIButton(type: .system)

    override var orientationPolicy: ScreenOrientationPolicy {
        .allButUpsideDown
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Portrait Demo"
        view.backgroundColor = .systemBackground

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "这个页面锁定竖屏"
        label.textColor = .label
        label.font = .systemFont(ofSize: 30, weight: .bold)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 15.0, *) {
            closeButton.configuration = .filled()
            closeButton.configuration?.title = "返回横屏页"
        } else {
            closeButton.setTitle("返回横屏页", for: .normal)
            closeButton.setTitleColor(.white, for: .normal)
            closeButton.backgroundColor = .systemBlue
            closeButton.layer.cornerRadius = 12
            closeButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
        }
        closeButton.addTarget(self, action: #selector(closePage), for: .touchUpInside)

        view.addSubview(label)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 24)
        ])
    }

    @objc
    private func closePage() {
        if presentingViewController != nil {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}

final class FlexibleDemoViewController: RotationAwareViewController {

    private let label = UILabel()
    private let closeButton = UIButton(type: .system)
    private let preferredOrientation: UIInterfaceOrientation

    init(preferredOrientation: UIInterfaceOrientation) {
        self.preferredOrientation = preferredOrientation
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var orientationPolicy: ScreenOrientationPolicy {
        .custom(mask: .allButUpsideDown, preferred: normalizedPreferredOrientation)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Flexible Demo"
        view.backgroundColor = .systemBackground

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "这个页面支持竖屏和横屏"
        label.textColor = .label
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.numberOfLines = 0
        label.textAlignment = .center

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 15.0, *) {
            closeButton.configuration = .filled()
            closeButton.configuration?.title = "返回横屏页"
        } else {
            closeButton.setTitle("返回横屏页", for: .normal)
            closeButton.setTitleColor(.white, for: .normal)
            closeButton.backgroundColor = .systemBlue
            closeButton.layer.cornerRadius = 12
            closeButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
        }
        closeButton.addTarget(self, action: #selector(closePage), for: .touchUpInside)

        view.addSubview(label)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 24)
        ])
    }

    @objc
    private func closePage() {
        navigationController?.popViewController(animated: true)
    }

    private var normalizedPreferredOrientation: UIInterfaceOrientation {
        switch preferredOrientation {
        case .portrait, .landscapeLeft, .landscapeRight:
            return preferredOrientation
        default:
            return .portrait
        }
    }
}
