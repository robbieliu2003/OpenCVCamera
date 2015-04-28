//
//  CVTransform.h
//  OpenCVSquares
//
//  Created by 刘伟 on 15/4/13.
//  Copyright (c) 2015年 foundry. All rights reserved.
//

#ifndef __OpenCVSquares__CVTransform__
#define __OpenCVSquares__CVTransform__

#include <stdio.h>

class CVTransform
{
public:
    static cv::Mat perspectiveTransformInImage (cv::Mat image, cv::Point tl, cv::Point tr, cv::Point bl, cv::Point br);
    
    static cv::Mat binarizeImage (cv::Mat image);
    
    static void replaceColor(cv::Mat& img, cv::Mat& result, cv::Vec3b srcColor, cv::Vec3b dstColor);
};

#endif /* defined(__OpenCVSquares__CVTransform__) */
