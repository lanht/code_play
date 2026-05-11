//
//  ORRotationAwareControllers.m
//  screen_rotation
//
//  Created by Codex on 2026/4/29.
//

#import "ORRotationAwareControllers.h"

@implementation ORRotationAwareViewController

- (ORScreenOrientationPolicyDescriptor *)or_orientationPolicyDescriptor {
    return [ORScreenOrientationPolicyDescriptor portraitPolicy];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.or_orientationPolicyDescriptor.mask;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return self.or_orientationPolicyDescriptor.preferredOrientation;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[ORScreenOrientationManager sharedManager] refreshFromViewController:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[ORScreenOrientationManager sharedManager] refreshFromViewController:self];
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent
                     animated:(BOOL)flag
                   completion:(void (^ _Nullable)(void))completion {
    [[ORScreenOrientationManager sharedManager] prepareForPresentationOfViewController:viewControllerToPresent
                                                                     fromViewController:self];
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

@end

@implementation ORRotationAwareNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    UIViewController *sourceViewController = self.visibleViewController ?: self;
    [[ORScreenOrientationManager sharedManager] prepareForPresentationOfViewController:viewController
                                                                     fromViewController:sourceViewController];
    [super pushViewController:viewController animated:animated];
}

- (BOOL)shouldAutorotate {
    return self.visibleViewController ? self.visibleViewController.shouldAutorotate : YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([self.visibleViewController conformsToProtocol:@protocol(ORScreenOrientationConfigurable)]) {
        return [(id<ORScreenOrientationConfigurable>)self.visibleViewController or_orientationPolicyDescriptor].mask;
    }
    return [[ORScreenOrientationManager sharedManager] currentMask];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if ([self.visibleViewController conformsToProtocol:@protocol(ORScreenOrientationConfigurable)]) {
        return [(id<ORScreenOrientationConfigurable>)self.visibleViewController or_orientationPolicyDescriptor].preferredOrientation;
    }
    return UIInterfaceOrientationPortrait;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[ORScreenOrientationManager sharedManager] refreshFromViewController:self];
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    [[ORScreenOrientationManager sharedManager] refreshFromViewController:viewController];
}

- (UIViewController *)or_orientationTargetViewController {
    return self.visibleViewController;
}

@end

@implementation ORRotationAwareTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
}

- (BOOL)shouldAutorotate {
    return self.selectedViewController ? self.selectedViewController.shouldAutorotate : YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([self.selectedViewController conformsToProtocol:@protocol(ORScreenOrientationConfigurable)]) {
        return [(id<ORScreenOrientationConfigurable>)self.selectedViewController or_orientationPolicyDescriptor].mask;
    }
    return [[ORScreenOrientationManager sharedManager] currentMask];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if ([self.selectedViewController conformsToProtocol:@protocol(ORScreenOrientationConfigurable)]) {
        return [(id<ORScreenOrientationConfigurable>)self.selectedViewController or_orientationPolicyDescriptor].preferredOrientation;
    }
    return UIInterfaceOrientationPortrait;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[ORScreenOrientationManager sharedManager] refreshFromViewController:self];
}

- (UIViewController *)or_orientationTargetViewController {
    return self.selectedViewController;
}

- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController {
    [[ORScreenOrientationManager sharedManager] refreshFromViewController:viewController];
}

@end
