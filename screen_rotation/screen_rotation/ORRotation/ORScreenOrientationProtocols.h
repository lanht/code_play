//
//  ORScreenOrientationProtocols.h
//  screen_rotation
//
//  Created by Codex on 2026/4/29.
//

#import "ORScreenOrientationPolicy.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ORScreenOrientationConfigurable <NSObject>
- (ORScreenOrientationPolicyDescriptor *)or_orientationPolicyDescriptor;
@end

@protocol ORScreenOrientationChildProviding <NSObject>
- (nullable UIViewController *)or_orientationTargetViewController;
@end

NS_ASSUME_NONNULL_END
