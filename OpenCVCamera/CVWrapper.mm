//
//  CVWrapper.mm
//  CVOpenTemplate
//
//  Created by Washe on 02/01/2013.
//  Copyright (c) 2013 Washe / Foundry. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "CVWrapper.h"
#import "CVSquares.h"
#import "CVTransform.h"
#import "UIImage+OpenCV.h"
#import "CVRotate.h"

    //remove 'magic numbers' from original C++ source so we can manipulate them from obj-C
#define TOLERANCE 0.3
#define THRESHOLD 50
#define LEVELS 9
#define ACCURACY 0

@implementation CVWrapper

+ (NSMutableArray*) detectedSquaresInImage:(UIImage*) image
{
        //if we call this method with no parameters,
        //we use the defaults from the original c++ project
    return [[self class] detectedSquaresInImage:image
                                      tolerance:TOLERANCE
                                      threshold:THRESHOLD
                                         levels:LEVELS
                                       accuracy:ACCURACY];
    
}


+ (NSMutableArray*) detectedSquaresInImage:(UIImage*) image
                          tolerance:(CGFloat)  tolerance
                          threshold:(NSInteger)threshold
                             levels:(NSInteger)levels
                           accuracy:(NSInteger)accuracy

{
        //NSLog (@"detectedSquaresInImage");
    NSMutableArray *squarePts = [NSMutableArray array];
    cv::Mat matImage = [image CVMat];
    
    
    std::vector<cv::Point> square = CVSquares::detectedSquareInImage (matImage, tolerance, threshold, levels, accuracy);
    
    for (int i = 0; i < square.size(); i++) {
        [squarePts addObject:[NSValue valueWithCGPoint:CGPointMake(square.at(i).x,square.at(i).y)]];
    }
       
    
//    result = [UIImage imageWithCVMat:matImage];
        //NSLog (@"detectedSquaresInImage result");
    
    return squarePts;
    
}

+ (UIImage*) perspectiveTransformInImage:(UIImage*) image from:(NSArray*)squarePts
{
    UIImage* result = nil;
    cv::Mat matImage = [image CVMat];
    
    NSMutableArray *sortedPts = [self sortPoints:squarePts];
    cv::Point lt,rt,lb,rb;
    lt.x = [[sortedPts objectAtIndex:0] CGPointValue].x, lt.y = [[sortedPts objectAtIndex:0] CGPointValue].y;
    rt.x = [[sortedPts objectAtIndex:1] CGPointValue].x, rt.y = [[sortedPts objectAtIndex:1] CGPointValue].y;
    lb.x = [[sortedPts objectAtIndex:2] CGPointValue].x, lb.y = [[sortedPts objectAtIndex:2] CGPointValue].y;
    rb.x = [[sortedPts objectAtIndex:3] CGPointValue].x, rb.y = [[sortedPts objectAtIndex:3] CGPointValue].y;
    matImage = CVTransform::perspectiveTransformInImage (matImage, lt, rt, lb, rb);
    
    
    result = [UIImage imageWithCVMat:matImage orientation:image.imageOrientation];
    
    return result;
}

+ (UIImage*) correctRotationInImage:(UIImage*) image
{
    UIImage* result = nil;
    cv::Mat matImage = [image CVMat];
    
    matImage = CVRotate::correctRotationInImage(matImage);
    
    
    result = [UIImage imageWithCVMat:matImage orientation:image.imageOrientation];
    
    return result;
}

+ (UIImage*) binarizeImage:(UIImage*) image
{
    UIImage* result = nil;
    cv::Mat matImage = [image CVMat3];
    
//    matImage = CVTransform::binarizeImage(matImage);
    
    cv::Vec3b feed = matImage.at<cv::Vec3b>(50, 50);
    CVTransform::replaceColor(matImage, matImage, feed, cv::Vec3b(255,255,255));
    cvtColor(matImage, matImage, CV_RGB2RGBA);
    
    
    result = [UIImage imageWithCVMat:matImage orientation:image.imageOrientation];
    
    return result;
}

+ (NSMutableArray*) sortPoints:(NSArray*)squarePts
{
    NSMutableArray *pts = [NSMutableArray array];
    int left0 = 0, right0 = 0, top0 = 0, bottom0 = 0;
    for (int i = 1; i < squarePts.count; i++) {
        if ([[squarePts objectAtIndex:0] CGPointValue].x < [[squarePts objectAtIndex:i] CGPointValue].x) {
            right0++;
        } else {
            left0++;
        }
        if ([[squarePts objectAtIndex:0] CGPointValue].y < [[squarePts objectAtIndex:i] CGPointValue].y) {
            bottom0++;
        } else {
            top0++;
        }
    }
    int left1 = 0, right1 = 0, top1 = 0, bottom1 = 0;
    for (int i = 0; i < squarePts.count; i++) {
        if (i == 1) {
            continue;
        }
        if ([[squarePts objectAtIndex:1] CGPointValue].x < [[squarePts objectAtIndex:i] CGPointValue].x) {
            right1++;
        } else {
            left1++;
        }
        if ([[squarePts objectAtIndex:1] CGPointValue].y < [[squarePts objectAtIndex:i] CGPointValue].y) {
            bottom1++;
        } else {
            top1++;
        }
    }
    if ((left0 > left1 && right0 < right1) && bottom1 > 1) {
        [pts addObject:[squarePts objectAtIndex:1]];
        [pts addObject:[squarePts objectAtIndex:0]];
        [pts addObject:[squarePts objectAtIndex:2]];
        [pts addObject:[squarePts objectAtIndex:3]];
    } else {
        [pts addObject:[squarePts objectAtIndex:0]];
        [pts addObject:[squarePts objectAtIndex:3]];
        [pts addObject:[squarePts objectAtIndex:1]];
        [pts addObject:[squarePts objectAtIndex:2]];
    }
    return pts;
}

@end
