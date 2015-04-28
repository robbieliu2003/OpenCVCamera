//
//  CVTransform.cpp
//  OpenCVSquares
//
//  Created by 刘伟 on 15/4/13.
//  Copyright (c) 2015年 foundry. All rights reserved.
//

#include "CVTransform.h"

using namespace std;
using namespace cv;

Mat CVTransform::perspectiveTransformInImage (Mat image, Point tl, Point tr, Point bl, Point br)
{
    float left, top, right, bottom;
    left = (tl.x < bl.x) ? tl.x : bl.x;
    right = (tr.x > br.x) ? tr.x : br.x;
    top = (tl.y < tr.y) ? tl.y : tr.y;
    bottom = (bl.y > br.y) ? bl.y : br.y;
    
    Point2f srcTri[] = {Point2f(tl.x,tl.y),
        Point2f(tr.x,tr.y),
        Point2f(bl.x,bl.y),
        Point2f(br.x,br.y)};
    Point2f dstTri[] = {Point2f(0,0),
        Point2f(right-left,0),
        Point2f(0,bottom-top),
        Point2f(right-left,bottom-top)};
    
    Mat dst;
    Mat warp_mat;
    warp_mat = getPerspectiveTransform(srcTri, dstTri);
    Size imageSize = Size(right-left, bottom-top);//Size(image.cols, image.rows);
    warpPerspective(image, dst, warp_mat, imageSize);
    
    return dst;
}

Mat CVTransform::binarizeImage (Mat source)
{
    Mat results;
//    cvtColor(source, results, COLOR_RGB2GRAY);

    
//    Mat mask=(Mat_<char>(3,3)<<0,-1,0,
//              -1,5,-1,
//              0,-1,0);
    Mat mask=(Mat_<char>(3,3)<<-1,-1,-1,
              -1,9,-1,
              -1,-1,-1);
    
    filter2D (source,results,source.depth (),mask);
    
//    int blockDim=MIN(source.size().height/4, source.size().width/4);
//    if(blockDim % 2 != 1) blockDim++;   //block has to be odd
//    
//    adaptiveThreshold(results, results, 255, ADAPTIVE_THRESH_MEAN_C,
//                              THRESH_BINARY,9, 10);
    
    return results;
}

#define MAX3(a,b,c)  (a>b?(a>c?a:c):(b>c?b:c))
#define MIN3(a,b,c)  (a<b?(a<c?a:c):(b<c?b:c))
CvScalar RGB2HSV(CvScalar rgb)
{
    CvScalar hsv;
    hsv.val[3] = 0;
    double max = MAX3(rgb.val[0],rgb.val[1],rgb.val[2]);
    double min = MIN3(rgb.val[0],rgb.val[1],rgb.val[2]);
    if (max == min) {
        hsv.val[0] = 0;
        hsv.val[1] = 0;
        hsv.val[2] = max;
    } else {
        if (rgb.val[1] >= rgb.val[2]) {
            hsv.val[0] = ((255-rgb.val[0]+rgb.val[1]+rgb.val[2]) / 255 * 60)/2;
            hsv.val[1] = 255*(1-min/max);
            hsv.val[2] = max;
        } else {
            hsv.val[0] = (360 - (255-rgb.val[0]+rgb.val[1]+rgb.val[2]) / 255 * 60)/2;
            hsv.val[1] = 255*(1-min/max);
            hsv.val[2] = max;
        }
    }
    return hsv;
}

void CVTransform::replaceColor(cv::Mat& img, cv::Mat& result, cv::Vec3b srcColor, cv::Vec3b dstColor)
{
    IplImage image = IplImage(img);
    CvSize cvSize = cvGetSize(&image);
    
    CvScalar dst;
    dst.val[0] = dstColor[0]; dst.val[1] = dstColor[1];
    dst.val[2] = dstColor[2]; dst.val[3] = 0;
    
    IplImage *hsvImage = cvCreateImage(cvSize, image.depth,image.nChannels);
    cvCvtColor(&image, hsvImage, CV_RGB2HSV);
    
    IplImage *dest = cvCreateImage(cvSize, image.depth, image.nChannels);
    
    IplImage *cvInRange = cvCreateImage(cvSize, image.depth, 1);
    cvCvtColor(&image, cvInRange, CV_RGB2GRAY);
    cvAdaptiveThreshold(cvInRange, cvInRange, 255, ADAPTIVE_THRESH_MEAN_C,
                        THRESH_BINARY,9, 10);
    
    cvSet(hsvImage, RGB2HSV(dst), cvInRange);
    cvCvtColor(hsvImage, dest, CV_HSV2RGB);
    
    result = Mat(dest);
}