//
//  ORScreenOrientationManager.h
//  screen_rotation
//
//  Created by Codex on 2026/4/29.
//

#import "ORScreenOrientationProtocols.h"

NS_ASSUME_NONNULL_BEGIN

@interface ORScreenOrientationManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign, readonly) UIInterfaceOrientationMask currentMask;
@property (nonatomic, assign, readonly) UIInterfaceOrientation currentInterfaceOrientation;

- (void)attachWindowScene:(UIWindowScene *)windowScene;
- (void)refreshFromViewController:(nullable UIViewController *)viewController;
- (void)prepareForPresentationOfViewController:(UIViewController *)viewController
                             fromViewController:(nullable UIViewController *)sourceViewController;

@end

NS_ASSUME_NONNULL_END
