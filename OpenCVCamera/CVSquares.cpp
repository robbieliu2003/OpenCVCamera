//
//  CVSquares.cpp
//  OpenCVClient
//
//  Original code from sample distributed with openCV source.
//  Modifications (c) new foundry Limited. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#include "CVSquares.h"

using namespace std;
using namespace cv;

static int inset_x = 10, inset_y = 10;
static double maxA4Scale = 2, minA4Scale = 0.5;
static int thresh = 50, N = 11;
static float tolerance = 0.01;
static int accuracy = 0;

    //adding declarations at top of file to allow public function (was main{}) at top
static void findSquares(  const Mat& image,   vector<vector<Point> >& squares );
static void drawSquares( Mat& image, vector<vector<Point> >& squares );
static void find_largest_square(const vector<vector<Point> >& squares, vector<Point>& biggest_square);
static void drawSquare( Mat& image, vector<Point>& square );

    //this public function performs the role of
    //main{} in the original file 
vector<Point> CVSquares::detectedSquareInImage (cv::Mat image, float tol, int threshold, int levels, int acc)
{
    vector<vector<Point> > squares;
    vector<Point> biggest_square;
    
    if( image.empty() )
        {
        cout << "CVSquares.m: Couldn't load " << endl;
        }

    tolerance = tol;
    thresh = threshold;
    N = levels;
    accuracy = acc;
    findSquares(image, squares);
    find_largest_square(squares, biggest_square);
//    drawSquares(image, squares);
    drawSquare(image, biggest_square);
    
    return biggest_square;
}

static double angle( Point pt1, Point pt2, Point pt0 )
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

static double a4Scale( Point pt1, Point pt2, Point pt0 )
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return sqrt(dx1*dx1 + dy1*dy1)/sqrt(dx2*dx2 + dy2*dy2);
}

static bool approxInRect(vector<Point> approx, Rect rect)
{
    return (rect.contains(approx[0]) &&
    rect.contains(approx[1]) &&
    rect.contains(approx[2]) &&
    rect.contains(approx[3]));
}

    // returns sequence of squares detected on the image.
    // the sequence is stored in the specified memory storage
    //static void findSquares( const Mat& image, vector<vector<Point> >& squares )

static void findSquares(  const Mat& image,   vector<vector<Point> >& squares )

{
    squares.clear();
    
    double scanArea = image.cols * image.rows / 10.0;
    Rect imageRect(0+inset_x,0+inset_y,image.cols-2*inset_x,image.rows-2*inset_y);
    Mat pyr, timg, gray0(image.size(), CV_8U), gray;
    
        // down-scale and upscale the image to filter out the noise
    pyrDown(image, pyr, Size(image.cols/2, image.rows/2));
    pyrUp(pyr, timg, image.size());
    vector<vector<Point> > contours;
    
        // find squares in every color plane of the image
    int planes = 1;
    int canny = 0;
    if (accuracy) {
        planes = 4;
        canny = 1;
    }
    for( int c = 0; c < planes; c++ )
        {
        int ch[] = {c, 0};
        mixChannels(&timg, 1, &gray0, 1, ch, 1);
        
            // try several threshold levels
        for( int l = 0; l < N; l++ )
            {
                // hack: use Canny instead of zero threshold level.
                // Canny helps to catch squares with gradient shading
            if( l == 0 && canny == 1 )
                {
                    // apply Canny. Take the upper threshold from slider
                    // and set the lower to 0 (which forces edges merging)
                Canny(gray0, gray, 0, thresh, 5);
                    // dilate canny output to remove potent5ial
                    // holes between edge segments
                dilate(gray, gray, Mat(), Point(-1,-1));
                }
            else
                {
                    // apply threshold if l!=0:
                    //     tgray(x,y) = gray(x,y) < (l+1)*255/N ? 255 : 0
                gray = gray0 >= (l+1)*255/N;
                }
            
                // find contours and store them all as a list
            findContours(gray, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
            
            vector<Point> approx;
            
                // test each contour
            for( size_t i = 0; i < contours.size(); i++ )
                {
                    // approximate contour with accuracy proportional
                    // to the contour perimeter
                approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
                
                    // square contours should have 4 vertices after approximation
                    // relatively large area (to filter out noisy contours)
                    // and be convex.
                    // Note: absolute value of an area is used because
                    // area may be positive or negative - in accordance with the
                    // contour orientation
                if( approx.size() == 4 &&
                   fabs(contourArea(Mat(approx))) > scanArea &&
                   isContourConvex(Mat(approx)) )
                    {
                    double maxCosine = 0;
                    bool isa4scale = true;
                    
                    for( int j = 2; j < 5; j++ )
                    {
                            // find the maximum cosine of the angle between joint edges
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                        double a4scale = a4Scale(approx[j%4], approx[j-2], approx[j-1]);
                        isa4scale = (a4scale > minA4Scale && a4scale < maxA4Scale);
                        if (!isa4scale) {
                            break;
                        }
                    }
                    
                        // if cosines of all angles are small
                        // (all angles are ~90 degree) then write quandrange
                        // vertices to resultant sequence

                    if( maxCosine < tolerance && isa4scale &&
                       approxInRect(approx, imageRect))
                        squares.push_back(approx);
                    }
                }
            }
        }
}

static void find_largest_square(const vector<vector<Point> >& squares, vector<Point>& biggest_square)
{
    if (!squares.size())
    {
        // no squares detected
        return;
    }
    
    int max_width = 0;
    int max_height = 0;
    int max_square_idx = 0;
    const int n_points = 4;
    
    for (size_t i = 0; i < squares.size(); i++)
    {
        // Convert a set of 4 unordered Points into a meaningful cv::Rect structure.
        Rect rectangle = boundingRect(Mat(squares[i]));
        
        //        cout << "find_largest_square: #" << i << " rectangle x:" << rectangle.x << " y:" << rectangle.y << " " << rectangle.width << "x" << rectangle.height << endl;
        
        // Store the index position of the biggest square found
        if ((rectangle.width >= max_width) && (rectangle.height >= max_height))
        {
            max_width = rectangle.width;
            max_height = rectangle.height;
            max_square_idx = i;
        }
    }
    
    biggest_square = squares[max_square_idx];
}


    // the function draws all the squares in the image
    //static void drawSquares( Mat& image, const vector<vector<Point> >& squares )
static void drawSquares( Mat& image, vector<vector<Point> >& squares )
{
    if (squares.size() == 0) {
        return;
    }
    
    for( size_t i = 0; i < squares.size(); i++ )
        {
        const Point* p = &squares[i][0];
        int n = (int)squares[i].size();
        polylines(image, &p, &n, 1, true, Scalar(0,255,0), 3, CV_AA);
        }
    
        //imshow(wndname, image);
}

static void drawSquare( Mat& image, vector<Point>& square )
{
    if (square.size() == 0) {
        return;
    }
    
    const Point* p = &square[0];
    int n = (int)square.size();
    polylines(image, &p, &n, 1, true, Scalar(0,255,0), 8, CV_AA);
    
    //imshow(wndname, image);
}


