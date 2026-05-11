//
//  ORRotationDemoViewController.m
//  screen_rotation
//
//  Created by Codex on 2026/4/29.
//

#import <UIKit/UIKit.h>
#import "ORScreenRotation.h"

@interface ORPortraitDemoViewController : ORRotationAwareViewController
@end

@interface ORFlexibleDemoViewController : ORRotationAwareViewController
- (instancetype)initWithPreferredOrientation:(UIInterfaceOrientation)preferredOrientation NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface ORRotationDemoViewController : ORRotationAwareViewController
@end

@implementation ORPortraitDemoViewController {
    UILabel *_label;
    UIButton *_closeButton;
}

- (ORScreenOrientationPolicyDescriptor *)or_orientationPolicyDescriptor {
    return [ORScreenOrientationPolicyDescriptor portraitPolicy];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"OR Portrait";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    _label = [[UILabel alloc] init];
    _label.translatesAutoresizingMaskIntoConstraints = NO;
    _label.text = @"这个 ObjC 页面锁定竖屏";
    _label.textAlignment = NSTextAlignmentCenter;
    _label.numberOfLines = 0;
    _label.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];

    _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_closeButton setTitle:@"关闭" forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(closePage) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:_label];
    [self.view addSubview:_closeButton];

    [NSLayoutConstraint activateConstraints:@[
        [_label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_label.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:24],
        [_label.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-24],
        [_closeButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_closeButton.topAnchor constraintEqualToAnchor:_label.bottomAnchor constant:24]
    ]];
}

- (void)closePage {
    [self.navigationController popViewControllerAnimated:YES];
}

@end

@implementation ORFlexibleDemoViewController {
    UILabel *_label;
    UIButton *_closeButton;
    UIInterfaceOrientation _preferredOrientation;
}

- (instancetype)initWithPreferredOrientation:(UIInterfaceOrientation)preferredOrientation {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _preferredOrientation = preferredOrientation;
    }
    return self;
}

- (ORScreenOrientationPolicyDescriptor *)or_orientationPolicyDescriptor {
    UIInterfaceOrientation preferredOrientation = _preferredOrientation;
    if (preferredOrientation != UIInterfaceOrientationPortrait &&
        preferredOrientation != UIInterfaceOrientationLandscapeLeft &&
        preferredOrientation != UIInterfaceOrientationLandscapeRight) {
        preferredOrientation = UIInterfaceOrientationPortrait;
    }

    return [ORScreenOrientationPolicyDescriptor customPolicyWithMask:UIInterfaceOrientationMaskAllButUpsideDown
                                              preferredOrientation:preferredOrientation];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"OR Flexible";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    _label = [[UILabel alloc] init];
    _label.translatesAutoresizingMaskIntoConstraints = NO;
    _label.text = @"这个 ObjC 页面支持竖屏和横屏";
    _label.textAlignment = NSTextAlignmentCenter;
    _label.numberOfLines = 0;
    _label.font = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];

    _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_closeButton setTitle:@"关闭" forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(closePage) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:_label];
    [self.view addSubview:_closeButton];

    [NSLayoutConstraint activateConstraints:@[
        [_label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_label.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:24],
        [_label.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-24],
        [_closeButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_closeButton.topAnchor constraintEqualToAnchor:_label.bottomAnchor constant:24]
    ]];
}

- (void)closePage {
    [self.navigationController popViewControllerAnimated:YES];
}

@end

@implementation ORRotationDemoViewController {
    UILabel *_titleLabel;
    UIButton *_presentPortraitButton;
    UIButton *_pushPortraitButton;
    UIButton *_pushFlexibleButton;
}

- (ORScreenOrientationPolicyDescriptor *)or_orientationPolicyDescriptor {
    return [ORScreenOrientationPolicyDescriptor landscapePolicy];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"OR Demo";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.text = @"纯 Objective-C 转屏演示";
    _titleLabel.numberOfLines = 0;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];

    _presentPortraitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _presentPortraitButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_presentPortraitButton setTitle:@"Present 竖屏页" forState:UIControlStateNormal];
    [_presentPortraitButton addTarget:self action:@selector(presentPortraitPage) forControlEvents:UIControlEventTouchUpInside];

    _pushPortraitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _pushPortraitButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_pushPortraitButton setTitle:@"Push 竖屏页" forState:UIControlStateNormal];
    [_pushPortraitButton addTarget:self action:@selector(pushPortraitPage) forControlEvents:UIControlEventTouchUpInside];

    _pushFlexibleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _pushFlexibleButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_pushFlexibleButton setTitle:@"Push 跟随当前方向页" forState:UIControlStateNormal];
    [_pushFlexibleButton addTarget:self action:@selector(pushFlexiblePage) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:_titleLabel];
    [self.view addSubview:_presentPortraitButton];
    [self.view addSubview:_pushPortraitButton];
    [self.view addSubview:_pushFlexibleButton];

    [NSLayoutConstraint activateConstraints:@[
        [_titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_titleLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:24],
        [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-24],
        [_presentPortraitButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_presentPortraitButton.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:28],
        [_pushPortraitButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_pushPortraitButton.topAnchor constraintEqualToAnchor:_presentPortraitButton.bottomAnchor constant:16],
        [_pushFlexibleButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_pushFlexibleButton.topAnchor constraintEqualToAnchor:_pushPortraitButton.bottomAnchor constant:16]
    ]];
}

- (void)presentPortraitPage {
    ORPortraitDemoViewController *controller = [[ORPortraitDemoViewController alloc] init];
    ORRotationAwareNavigationController *navigationController =
        [[ORRotationAwareNavigationController alloc] initWithRootViewController:controller];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)pushPortraitPage {
    [self.navigationController pushViewController:[ORPortraitDemoViewController new] animated:YES];
}

- (void)pushFlexiblePage {
    UIInterfaceOrientation orientation = ORScreenOrientationManager.sharedManager.currentInterfaceOrientation;
    ORFlexibleDemoViewController *controller =
        [[ORFlexibleDemoViewController alloc] initWithPreferredOrientation:orientation];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
