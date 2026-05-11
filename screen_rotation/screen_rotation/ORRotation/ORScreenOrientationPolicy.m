//
//  ORScreenOrientationPolicy.m
//  screen_rotation
//
//  Created by Codex on 2026/4/29.
//

#import "ORScreenOrientationPolicy.h"

@interface ORScreenOrientationPolicyDescriptor ()

@property (nonatomic, assign, readwrite) ORScreenOrientationPolicy kind;
@property (nonatomic, assign, readwrite) UIInterfaceOrientationMask mask;
@property (nonatomic, assign, readwrite) UIInterfaceOrientation preferredOrientation;

- (instancetype)initWithKind:(ORScreenOrientationPolicy)kind
                        mask:(UIInterfaceOrientationMask)mask
       preferredOrientation:(UIInterfaceOrientation)preferredOrientation;

@end

@implementation ORScreenOrientationPolicyDescriptor

- (instancetype)initWithKind:(ORScreenOrientationPolicy)kind
                        mask:(UIInterfaceOrientationMask)mask
       preferredOrientation:(UIInterfaceOrientation)preferredOrientation {
    self = [super init];
    if (self) {
        _kind = kind;
        _mask = mask;
        _preferredOrientation = preferredOrientation;
    }
    return self;
}

+ (instancetype)portraitPolicy {
    return [[self alloc] initWithKind:ORScreenOrientationPolicyPortrait
                                 mask:UIInterfaceOrientationMaskPortrait
                preferredOrientation:UIInterfaceOrientationPortrait];
}

+ (instancetype)landscapePolicy {
    return [[self alloc] initWithKind:ORScreenOrientationPolicyLandscape
                                 mask:UIInterfaceOrientationMaskLandscape
                preferredOrientation:UIInterfaceOrientationLandscapeRight];
}

+ (instancetype)allButUpsideDownPolicy {
    return [[self alloc] initWithKind:ORScreenOrientationPolicyAllButUpsideDown
                                 mask:UIInterfaceOrientationMaskAllButUpsideDown
                preferredOrientation:UIInterfaceOrientationPortrait];
}

+ (instancetype)customPolicyWithMask:(UIInterfaceOrientationMask)mask
                 preferredOrientation:(UIInterfaceOrientation)preferredOrientation {
    return [[self alloc] initWithKind:ORScreenOrientationPolicyCustom
                                 mask:mask
                preferredOrientation:preferredOrientation];
}

@end
