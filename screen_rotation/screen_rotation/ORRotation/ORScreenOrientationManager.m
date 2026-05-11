//
//  ORScreenOrientationManager.m
//  screen_rotation
//
//  Created by Codex on 2026/4/29.
//

#import "ORScreenOrientationManager.h"

@interface ORScreenOrientationManager ()

@property (nonatomic, strong) ORScreenOrientationPolicyDescriptor *currentPolicy;
@property (nonatomic, weak) UIWindowScene *windowScene;

@end

@implementation ORScreenOrientationManager

+ (instancetype)sharedManager {
    static ORScreenOrientationManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] initPrivate];
    });
    return sharedManager;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _currentPolicy = [ORScreenOrientationPolicyDescriptor portraitPolicy];
    }
    return self;
}

- (instancetype)init {
    NSAssert(NO, @"Use +sharedManager");
    return [self initPrivate];
}

- (UIInterfaceOrientationMask)currentMask {
    return self.currentPolicy.mask;
}

- (UIInterfaceOrientation)currentInterfaceOrientation {
    if (self.windowScene && self.windowScene.interfaceOrientation != UIInterfaceOrientationUnknown) {
        return self.windowScene.interfaceOrientation;
    }

    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }

        UIWindowScene *windowScene = (UIWindowScene *)scene;
        if (windowScene.interfaceOrientation != UIInterfaceOrientationUnknown) {
            return windowScene.interfaceOrientation;
        }
    }

    return self.currentPolicy.preferredOrientation;
}

- (void)attachWindowScene:(UIWindowScene *)windowScene {
    self.windowScene = windowScene;
}

- (void)refreshFromViewController:(UIViewController *)viewController {
    UIViewController *sourceViewController = viewController ?: [self topViewController];
    ORScreenOrientationPolicyDescriptor *nextPolicy = [self resolvedPolicyFromViewController:sourceViewController];
    [self applyPolicy:nextPolicy sourceViewController:sourceViewController];
}

- (void)prepareForPresentationOfViewController:(UIViewController *)viewController
                             fromViewController:(UIViewController *)sourceViewController {
    ORScreenOrientationPolicyDescriptor *nextPolicy = [self resolvedPolicyFromViewController:viewController];
    [self applyPolicy:nextPolicy sourceViewController:sourceViewController];
}

- (void)applyPolicy:(ORScreenOrientationPolicyDescriptor *)nextPolicy
 sourceViewController:(UIViewController *)sourceViewController {
    if (nextPolicy.kind == self.currentPolicy.kind &&
        nextPolicy.mask == self.currentPolicy.mask &&
        nextPolicy.preferredOrientation == self.currentPolicy.preferredOrientation) {
        [self notifySupportedOrientationChangedForViewController:sourceViewController];
        return;
    }

    self.currentPolicy = nextPolicy;
    [self notifySupportedOrientationChangedForViewController:sourceViewController];
    [self applyRotationIfNeeded];
}

- (ORScreenOrientationPolicyDescriptor *)resolvedPolicyFromViewController:(UIViewController *)viewController {
    if (!viewController) {
        return [ORScreenOrientationPolicyDescriptor portraitPolicy];
    }

    if (viewController.presentedViewController) {
        return [self resolvedPolicyFromViewController:viewController.presentedViewController];
    }

    if ([viewController conformsToProtocol:@protocol(ORScreenOrientationChildProviding)]) {
        UIViewController *target = [(id<ORScreenOrientationChildProviding>)viewController or_orientationTargetViewController];
        return [self resolvedPolicyFromViewController:target];
    }

    if ([viewController isKindOfClass:UINavigationController.class]) {
        UINavigationController *navigationController = (UINavigationController *)viewController;
        return [self resolvedPolicyFromViewController:navigationController.visibleViewController];
    }

    if ([viewController isKindOfClass:UITabBarController.class]) {
        UITabBarController *tabBarController = (UITabBarController *)viewController;
        return [self resolvedPolicyFromViewController:tabBarController.selectedViewController];
    }

    if ([viewController conformsToProtocol:@protocol(ORScreenOrientationConfigurable)]) {
        return [(id<ORScreenOrientationConfigurable>)viewController or_orientationPolicyDescriptor];
    }

    return [ORScreenOrientationPolicyDescriptor portraitPolicy];
}

- (UIViewController *)topViewController {
    UIWindowScene *candidateScene = self.windowScene;
    if (!candidateScene) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:UIWindowScene.class]) {
                candidateScene = (UIWindowScene *)scene;
                break;
            }
        }
    }

    UIWindow *candidateWindow = nil;
    for (UIWindow *window in candidateScene.windows) {
        if (window.isKeyWindow) {
            candidateWindow = window;
            break;
        }
    }

    if (!candidateWindow) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) {
                continue;
            }
            for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                if (window.isKeyWindow) {
                    candidateWindow = window;
                    break;
                }
            }
            if (candidateWindow) {
                break;
            }
        }
    }

    return candidateWindow.rootViewController;
}

- (void)applyRotationIfNeeded {
    if (@available(iOS 16.0, *)) {
        [UIViewController attemptRotationToDeviceOrientation];
        UIWindowSceneGeometryPreferencesIOS *preferences =
            [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:self.currentPolicy.mask];
        [self.windowScene requestGeometryUpdateWithPreferences:preferences
                                                  errorHandler:^(NSError *error) {
            NSLog(@"Failed to update interface orientation: %@", error.localizedDescription);
        }];
        return;
    }

    [UIDevice.currentDevice setValue:@(self.currentPolicy.preferredOrientation) forKey:@"orientation"];
    [UIViewController attemptRotationToDeviceOrientation];
}

- (void)notifySupportedOrientationChangedForViewController:(UIViewController *)viewController {
    if (!viewController) {
        return;
    }

    if (@available(iOS 16.0, *)) {
        [viewController setNeedsUpdateOfSupportedInterfaceOrientations];
    } else {
        [UIViewController attemptRotationToDeviceOrientation];
    }
}

@end
