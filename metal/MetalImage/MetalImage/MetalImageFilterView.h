//
//  MetalImageFilterView.h
//  MetalImage
//
//  Created by 陈耀武 on 2020/8/19.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum kMetalImageFilterViewFillModeType {
    kMetalImageFilterViewFillModeStretch,
    kMetalImageFilterViewFillModePreserveAspectRatio,
    kMetalImageFilterViewFillModePreserveAspectRatioAndFill
}kMetalImageFilterViewFillModeType;

@interface MetalImageFilterView : UIView
@property (nonatomic, assign) kMetalImageFilterViewFillModeType fillMode;
@end

NS_ASSUME_NONNULL_END
