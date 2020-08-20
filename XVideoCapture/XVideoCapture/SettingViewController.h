//
//  SettingViewController.h
//  XVideoCapture
//
//  Created by 陈耀武 on 2020/8/14.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class XVideoCamera;

@interface SettingViewController : UIViewController

@property (nonatomic, weak) XVideoCamera *vidooCamera;

@end

NS_ASSUME_NONNULL_END
