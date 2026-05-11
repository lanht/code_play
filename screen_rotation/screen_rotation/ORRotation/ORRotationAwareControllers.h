//
//  ORRotationAwareControllers.h
//  screen_rotation
//
//  Created by Codex on 2026/4/29.
//

#import "ORScreenOrientationManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface ORRotationAwareViewController : UIViewController <ORScreenOrientationConfigurable>
@end

@interface ORRotationAwareNavigationController : UINavigationController <UINavigationControllerDelegate, ORScreenOrientationChildProviding>
@end

@interface ORRotationAwareTabBarController : UITabBarController <UITabBarControllerDelegate, ORScreenOrientationChildProviding>
@end

NS_ASSUME_NONNULL_END
