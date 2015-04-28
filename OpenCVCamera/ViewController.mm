//
//  ViewController.m
//  OpenCVCamera
//
//  Created by 刘伟 on 15/4/15.
//  Copyright (c) 2015年 刘伟. All rights reserved.
//

#import "ViewController.h"
#import "CVSquares.h"
#import "CVWrapper.h"
#import "UIImage+OpenCV.h"

static int thresh = 100, N = 3;
static float tolerance = 0.1;
static int accuracy = 0;

#define SCANN_TIMES 30
#define SCREEN_FRAME [[UIScreen mainScreen] bounds]
@interface ViewController ()
{
    int scanTimes;
    BOOL needProcess;
    BOOL forceProcess;
    UIDeviceOrientation deviceOrientation;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    scanTimes = 0;
    needProcess = YES;
    forceProcess = NO;
    
    self.imageArray = [NSMutableArray array];
    
    cameraView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_FRAME.size.width, SCREEN_FRAME.size.height - 100)];
    [self.view addSubview:cameraView];
    
    activity = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_FRAME.size.width, SCREEN_FRAME.size.height - 100)];
    activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [self.view addSubview:activity];
    activity.hidden = YES;
    
    cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cameraButton.frame = CGRectMake((SCREEN_FRAME.size.width - 50)/2, SCREEN_FRAME.size.height - 155, 50, 50);
    cameraButton.layer.borderColor = [UIColor whiteColor].CGColor;
    cameraButton.layer.borderWidth = 2;
    cameraButton.layer.cornerRadius = cameraButton.frame.size.width/2;
    UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(4, 4, cameraButton.frame.size.width - 8, cameraButton.frame.size.height - 8)];
    backView.layer.cornerRadius = backView.frame.size.width/2;
    backView.backgroundColor = [UIColor whiteColor];
    backView.userInteractionEnabled = NO;
    [cameraButton addSubview:backView];
    [cameraButton addTarget:self action:@selector(actionCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraButton];
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, SCREEN_FRAME.size.height - 100, SCREEN_FRAME.size.width, 100)];
    scrollView.backgroundColor = [UIColor colorWithRed:0xee/255.0 green:0xee/255.0 blue:0xee/255.0 alpha:1];
    [self.view addSubview:scrollView];
    
    videoCamera = [[CvVideoCamera alloc] initWithParentView:cameraView];
    videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    videoCamera.defaultFPS = 30;
    videoCamera.grayscaleMode = NO;
    videoCamera.delegate = self;
    [videoCamera start];
    
    CMMotionManager *motionManager = [[CMMotionManager alloc] init];
    if (motionManager.accelerometerAvailable) {
        motionManager.accelerometerUpdateInterval = 0.1;
        
        [motionManager startDeviceMotionUpdates];
        
        [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *latestAcc, NSError *error)
         {
             float xx = -motionManager.deviceMotion.gravity.x;
             float yy = motionManager.deviceMotion.gravity.y;
             float angle = atan2(yy, xx);
             if (angle > -2.25 && angle <= -0.75) {
                 deviceOrientation = UIDeviceOrientationPortrait;
             } else if (angle > -0.75 && angle <= 0.75) {
                 deviceOrientation = UIDeviceOrientationLandscapeRight;
             } else if (angle > 0.75 && angle <= 2.25) {
                 deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
             } else {
                 deviceOrientation = UIDeviceOrientationLandscapeLeft;
             }
         }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)actionCamera:(id)sender {
    forceProcess = YES;
}

- (void)processScanImage:(cv::Mat &)matImage {
//    AudioServicesPlaySystemSound(1108);
    
    BOOL binarize = YES;
    UIImage *preProcessImage = [self preProcessImage:matImage];
    if (preProcessImage == nil) {
        binarize = NO;
        preProcessImage = [UIImage imageWithCVMat:matImage];
    }
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self animateWithProcessImage:preProcessImage needBinarize:binarize];
    });
    
}

- (void)animateWithProcessImage:(UIImage*)image needBinarize:(BOOL)binarize {
    [activity stopAnimating];
    activity.hidden = YES;
    UIImageView *previewView = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_FRAME.size.width/10, (SCREEN_FRAME.size.height - 100)/10, SCREEN_FRAME.size.width*4/5, (SCREEN_FRAME.size.height - 100)*4/5)];
    previewView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:previewView];
    previewView.alpha = 0;
    previewView.image = image;
    [UIView animateWithDuration:0.5 animations:^{
        previewView.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            //            if (deviceOrientation != UIDeviceOrientationPortrait) {
            //                sleep(1);
            //                previewView.image = [self changeImage:previewView.image withOrientation:deviceOrientation];
            //            }
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                if (binarize) {
                    previewView.image = [CVWrapper binarizeImage:previewView.image];
                }
            } completion:^(BOOL finished) {
                sleep(1);
                [UIView animateWithDuration:0.5 animations:^{
                    previewView.alpha = 0;
                } completion:^(BOOL finished) {
                    previewView.alpha = 1;
                    [previewView removeFromSuperview];
                    [self showScanImageInScrollView:previewView];
                    scanTimes = 0;
                    needProcess = YES;
                }];
            }];
        }];
    }];
}

- (void)showScanImageInScrollView:(UIImageView*)imageView {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewImage:)];
    [imageView addGestureRecognizer:tap];
    imageView.userInteractionEnabled = YES;
    [scrollView addSubview:imageView];
    imageView.frame = CGRectInset(CGRectMake(self.imageArray.count*100, 0, 100, 100),2,2);
    [self.imageArray addObject:imageView.image];
    scrollView.contentSize = CGSizeMake(self.imageArray.count*100, 100);
    [scrollView scrollRectToVisible:imageView.frame animated:YES];
}

- (void)previewImage:(UITapGestureRecognizer *)gecognizer
{
    UIImageView *imageView = (UIImageView*)gecognizer.view;
    if (imageView) {
        videoCamera.delegate = nil;
        
        CGRect imageRect = [self.view convertRect:imageView.frame fromView:imageView.superview];
        UIImageView *previewView = [[UIImageView alloc] initWithFrame:imageRect];
        previewView.image = imageView.image;
        previewView.userInteractionEnabled = YES;
        previewView.multipleTouchEnabled = YES;
        [self.view addSubview:previewView];
        [UIView animateWithDuration:0.5 animations:^{
            previewView.frame = SCREEN_FRAME;
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePreview:)];
            [previewView addGestureRecognizer:tap];
            UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
            [previewView addGestureRecognizer:pinchGestureRecognizer];
            UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
            [previewView addGestureRecognizer:panGestureRecognizer];
        }];
        
    }
}

- (void)closePreview:(UITapGestureRecognizer *)gecognizer
{
    UIImageView *imageView = (UIImageView*)gecognizer.view;
    if (imageView) {
        [UIView animateWithDuration:0.5 animations:^{
            imageView.alpha = 0;
            [imageView removeFromSuperview];
            videoCamera.delegate = self;
        }];
    }
}

- (void)pinchView:(UIPinchGestureRecognizer *)gecognizer
{
    UIImageView *view = (UIImageView*)gecognizer.view;
    if (gecognizer.state == UIGestureRecognizerStateBegan || gecognizer.state == UIGestureRecognizerStateChanged) {
        view.transform = CGAffineTransformScale(view.transform, gecognizer.scale, gecognizer.scale);
        gecognizer.scale = 1;
    }
}

- (void) panView:(UIPanGestureRecognizer *)panGestureRecognizer
{
    UIImageView *view = (UIImageView*)panGestureRecognizer.view;
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [panGestureRecognizer translationInView:view.superview];
        [view setCenter:(CGPoint){view.center.x + translation.x, view.center.y + translation.y}];
        [panGestureRecognizer setTranslation:CGPointZero inView:view.superview];
    }
}

- (UIImage *)preProcessImage:(Mat&)matImage {
    cvtColor(matImage, matImage, CV_BGR2RGB);
    UIImage *image = [UIImage imageWithCVMat:matImage];
    
    UIImage *rotatedImage = [CVWrapper correctRotationInImage:image];
    NSMutableArray *squarePts =
    [CVWrapper detectedSquaresInImage:rotatedImage
                            tolerance:tolerance
                            threshold:thresh
                               levels:N
                             accuracy:accuracy];
    
    if (squarePts.count > 0) {
        UIImage *cuttedImage = [self cutImage:rotatedImage InSquare:squarePts];
        
        image = [CVWrapper perspectiveTransformInImage:cuttedImage from:squarePts];
        return image;
    }
    return nil;
}

- (UIImage*)changeImage:(UIImage*)image withOrientation:(UIDeviceOrientation)orientation {
    if (orientation == UIDeviceOrientationLandscapeLeft) {
        image = [[UIImage alloc] initWithCGImage:image.CGImage scale:1 orientation:UIImageOrientationRight];
    } else if (orientation == UIDeviceOrientationLandscapeRight) {
        image = [[UIImage alloc] initWithCGImage:image.CGImage scale:1 orientation:UIImageOrientationLeft];
    } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        image = [[UIImage alloc] initWithCGImage:image.CGImage scale:1 orientation:UIImageOrientationDown];
    }
    return image;
}

- (UIImage*)cutImage:(UIImage*)image InSquare:(NSMutableArray*)pts {
    if (pts.count == 0) {
        return image;
    }
    
    float left = 0, top = 0, right = 0, bottom = 0;
    for (int i = 0 ; i < pts.count; i++) {
        CGPoint pt = [[pts objectAtIndex:i] CGPointValue];
        if (i == 0) {
            left = right = pt.x;
            top = bottom = pt.y;
        } else {
            if (pt.x < left) {
                left = pt.x;
            }
            if (pt.x > right) {
                right = pt.x;
            }
            if (pt.y < top) {
                top = pt.y;
            }
            if (pt.y > bottom) {
                bottom = pt.y;
            }
        }
    }
    
    CGRect rect = CGRectMake(left, top, right - left, bottom - top);
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, 0);
    
    [image drawAtPoint:CGPointMake(0-rect.origin.x,0-rect.origin.y)];
    
    
    UIImage* im = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    for (int i = 0 ; i < pts.count; i++) {
        CGPoint pt = [[pts objectAtIndex:i] CGPointValue];
        [pts replaceObjectAtIndex:i withObject:[NSValue valueWithCGPoint:CGPointMake(pt.x-left,pt.y-top)]];
    }
    return im;
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image
{
    // Do some OpenCV stuff with the image
    if (!needProcess) {
        return;
    }
    
    std::vector<cv::Point> square = CVSquares::detectedSquareInImage (image, tolerance, thresh, N, accuracy);
    
    if (square.size() > 0) {
        scanTimes++;
    } else {
        scanTimes = 0;
    }
    if (scanTimes > 10 || forceProcess) {
        forceProcess = NO;
        needProcess = NO;
        __block Mat scanImage = image.clone();
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [self processScanImage:scanImage];
        });
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            activity.hidden = NO;
            [activity startAnimating];
        });
    }
}
#endif

@end
