//
//  ORScreenOrientationPolicy.h
//  screen_rotation
//
//  Created by Codex on 2026/4/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ORScreenOrientationPolicy) {
    ORScreenOrientationPolicyPortrait = 0,
    ORScreenOrientationPolicyLandscape = 1,
    ORScreenOrientationPolicyAllButUpsideDown = 2,
    ORScreenOrientationPolicyCustom = 3,
};

@interface ORScreenOrientationPolicyDescriptor : NSObject

@property (nonatomic, assign, readonly) ORScreenOrientationPolicy kind;
@property (nonatomic, assign, readonly) UIInterfaceOrientationMask mask;
@property (nonatomic, assign, readonly) UIInterfaceOrientation preferredOrientation;

+ (instancetype)portraitPolicy;
+ (instancetype)landscapePolicy;
+ (instancetype)allButUpsideDownPolicy;
+ (instancetype)customPolicyWithMask:(UIInterfaceOrientationMask)mask
                 preferredOrientation:(UIInterfaceOrientation)preferredOrientation;

@end

NS_ASSUME_NONNULL_END
