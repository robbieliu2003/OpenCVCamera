//
//  ViewController.h
//  OpenCVCamera
//
//  Created by 刘伟 on 15/4/15.
//  Copyright (c) 2015年 刘伟. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>

#ifdef __cplusplus
using namespace cv;
#endif

@interface ViewController : UIViewController<CvVideoCameraDelegate>
{
    UIImageView *cameraView;
    UIScrollView *scrollView;
    UIButton *cameraButton;
    UIActivityIndicatorView *activity;
    
    CvVideoCamera* videoCamera;
}

- (IBAction)actionCamera:(id)sender;

@property (nonatomic, retain) NSMutableArray *imageArray;

@end

