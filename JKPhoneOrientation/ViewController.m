//
//  ViewController.m
//  JKPhoneOrientation
//
//  Created by Jeremy Kreutzbender on 6/25/14.
//  Copyright (c) 2014 Jeremy Kreutzbender. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>

#define kfilteringFactor 0.1

typedef NS_ENUM(NSInteger, TCTrueTradePhoneOrientation) {
    PhoneOrientationPortrait,
    PhoneOrientationLandscapeLeft,
    PhoneOrientationLandscapeRight,
    PhoneOrientationPortraitUpsideDown
};

@interface ViewController () {
    NSDictionary *_orientationDictionary;
    CMMotionManager *_motionManager;
    NSOperationQueue *_motionQueue;
    double _accelerationX;
    double _accelerationY;
    double _phoneAngle;
    NSInteger _phoneOrientation;
    
    CGRect _currentOrientationOriginalRect;
    CGRect _currentAngleOriginalRect;
}

@property (weak, nonatomic) IBOutlet UILabel *orientationLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentOrientation;
@property (weak, nonatomic) IBOutlet UILabel *angleLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentAngle;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _phoneOrientation = PhoneOrientationPortrait;
    
    _orientationDictionary = @{@(PhoneOrientationPortrait) : @"Portrait",
                               @(PhoneOrientationLandscapeLeft) : @"LandscapeLeft",
                               @(PhoneOrientationLandscapeRight) : @"LandscapeRight",
                               @(PhoneOrientationPortraitUpsideDown) : @"PortraitUpsideDown"};
    
    _currentOrientationOriginalRect = _currentOrientation.frame;
    _currentAngleOriginalRect = _currentAngle.frame;
    
    _phoneOrientation = PhoneOrientationPortrait;
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.accelerometerUpdateInterval = 0.01f;
    _motionQueue = [[NSOperationQueue alloc] init];
    [_motionManager startAccelerometerUpdatesToQueue:_motionQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *tcUnused) {
        self->_accelerationX = (accelerometerData.acceleration.x * kfilteringFactor + self->_accelerationX * (1.0 - kfilteringFactor));
        self->_accelerationY = (accelerometerData.acceleration.y * kfilteringFactor + self->_accelerationY * (1.0 - kfilteringFactor));
        self->_phoneAngle = (atan2(self->_accelerationY, self->_accelerationX)) * 180/M_PI;
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_currentAngle.text = [NSString stringWithFormat:@"%f", self->_phoneAngle];
        });
        [self rotateForAngle:_phoneAngle];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark MotionManager Helper methods

- (BOOL) isOrientationLandscapeRight:(double)angle {
    return (angle >= -45 && angle <= 45.0);
}

- (BOOL) isOrientationLandscapeLeft:(double)angle {
    return ((angle <= -135.1 && angle >= -180.0) || (angle >= 135.1 && angle <= 180.0));
}

- (BOOL) isOrientationPortrait:(double)angle {
    return (angle <= -45.1 && angle >= -135.0);
}

- (BOOL) isOrientationPortraitUpsideDown:(double)angle {
    return (angle <= 135.0 && angle >= 45.1);
}

- (void)rotateForAngle:(double)angle {
    __block UILabel *tempOrientationLabel = _orientationLabel;
    __block UILabel *tempCurrentOrientation = _currentOrientation;
    __block UILabel *tempAngleLabel = _angleLabel;
    __block UILabel *tempCurrentAngle = _currentAngle;
    
    __block CGRect orientationLabelOriginalRect;
    __block CGRect angleLabelOriginalRect;
    
    if ([self isOrientationPortrait:angle]) {
        
        /* Since this method is being triggered every 0.01 seconds, we want to check to see if the phone is in a consistent orientation
         * There is no reason to perform the work on the elements if no rotation is occuring */
        if (_phoneOrientation != PhoneOrientationPortrait) {
            
            // Set the orientation to avoid re-entrance into the block the next time this method is triggered
            _phoneOrientation = PhoneOrientationPortrait;
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.2 animations:^{
                    
                    // Rotate the description labels; they stay in place
                    tempOrientationLabel.transform = CGAffineTransformMakeRotation((CGFloat)(0 * M_PI/180.0));
                    tempAngleLabel.transform = CGAffineTransformMakeRotation((CGFloat)(0 * M_PI/180.0));
                    
                    /* The currentOrientation and currentAngle's rects are saved in portrait mode
                     * so we will rotate them back to portrait and then move the frame back to its original location */
                    tempCurrentOrientation.transform = CGAffineTransformMakeRotation((CGFloat)(0 * M_PI/180.0));
                    tempCurrentOrientation.frame = self->_currentOrientationOriginalRect;
                    
                    tempCurrentAngle.transform = CGAffineTransformMakeRotation((CGFloat)(0 * M_PI/180.0));
                    tempCurrentAngle.frame = self->_currentAngleOriginalRect;
                } completion:^(BOOL tcUnused) {
                    tempCurrentOrientation.text = self->_orientationDictionary[@(self->_phoneOrientation)];
                }];
            });
        }
    }
    else if ([self isOrientationLandscapeRight:angle]) {
        if (_phoneOrientation != PhoneOrientationLandscapeRight) {
            _phoneOrientation = PhoneOrientationLandscapeRight;
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // Save the rect's of the description labels while they are still in portrait mode
                orientationLabelOriginalRect = tempOrientationLabel.frame;
                angleLabelOriginalRect = tempAngleLabel.frame;
                [UIView animateWithDuration:0.2 animations:^{
                    tempOrientationLabel.transform = CGAffineTransformMakeRotation((CGFloat)(-90 * M_PI/180.0));
                    tempAngleLabel.transform = CGAffineTransformMakeRotation((CGFloat)(-90 * M_PI/180.0));
                    
                    /* When currentOrientation and currentAngle are rotated to landscape mode we must move them first and
                     * align them with the location of the description labels using the saved portrait rects
                     * Then we are able to rotate and have correct alignment */
                    tempCurrentOrientation.frame = CGRectMake(orientationLabelOriginalRect.origin.x + orientationLabelOriginalRect.size.height + 10,
                                                              orientationLabelOriginalRect.origin.y,
                                                              tempCurrentOrientation.frame.size.width,
                                                              tempCurrentOrientation.frame.size.height);
                    tempCurrentOrientation.transform = CGAffineTransformMakeRotation((CGFloat)(-90 * M_PI/180.0));
                    
                    
                    
                    tempCurrentAngle.frame = CGRectMake(angleLabelOriginalRect.origin.x + angleLabelOriginalRect.size.height + 10,
                                                        angleLabelOriginalRect.origin.y,
                                                        tempCurrentAngle.frame.size.width,
                                                        tempCurrentAngle.frame.size.height);
                    tempCurrentAngle.transform = CGAffineTransformMakeRotation((CGFloat)(-90 * M_PI/180.0));
                } completion:^(BOOL tcUnused) {
                    tempCurrentOrientation.text = self->_orientationDictionary[@(self->_phoneOrientation)];
                }];
            });
        }
    }
    else if ([self isOrientationPortraitUpsideDown:angle]) {
        if (_phoneOrientation != PhoneOrientationPortraitUpsideDown) {
            _phoneOrientation = PhoneOrientationPortraitUpsideDown;
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.2 animations:^{
                    tempOrientationLabel.transform = CGAffineTransformMakeRotation((CGFloat)(180 * M_PI/180.0));
                    tempAngleLabel.transform = CGAffineTransformMakeRotation((CGFloat)(180 * M_PI/180.0));
                    
                    tempCurrentOrientation.transform = CGAffineTransformMakeRotation((CGFloat)(180 * M_PI/180.0));
                    tempCurrentOrientation.frame = self->_currentOrientationOriginalRect;
                    
                    tempCurrentAngle.transform = CGAffineTransformMakeRotation((CGFloat)(180 * M_PI/180.0));
                    tempCurrentAngle.frame = self->_currentAngleOriginalRect;
                } completion:^(BOOL tcUnused) {
                    tempCurrentOrientation.text = self->_orientationDictionary[@(self->_phoneOrientation)];
                }];
            });
        }
    }
    else if ([self isOrientationLandscapeLeft:angle]) {
        if (_phoneOrientation != PhoneOrientationLandscapeLeft) {
            _phoneOrientation = PhoneOrientationLandscapeLeft;
            dispatch_async(dispatch_get_main_queue(), ^{
                orientationLabelOriginalRect = tempOrientationLabel.frame;
                angleLabelOriginalRect = tempAngleLabel.frame;
                [UIView animateWithDuration:0.2 animations:^{
                    tempOrientationLabel.transform = CGAffineTransformMakeRotation((CGFloat)(90 * M_PI/180.0));
                    tempAngleLabel.transform = CGAffineTransformMakeRotation((CGFloat)(90 * M_PI/180.0));
                    
                    tempCurrentOrientation.frame = CGRectMake(orientationLabelOriginalRect.origin.x - orientationLabelOriginalRect.size.height - 10,
                                                              orientationLabelOriginalRect.origin.y,
                                                              tempCurrentOrientation.frame.size.width,
                                                              tempCurrentOrientation.frame.size.height);
                    tempCurrentOrientation.transform = CGAffineTransformMakeRotation((CGFloat)(90 * M_PI/180.0));
                    
                    
                    tempCurrentAngle.frame = CGRectMake(angleLabelOriginalRect.origin.x - angleLabelOriginalRect.size.height - 10,
                                                        angleLabelOriginalRect.origin.y,
                                                        tempCurrentAngle.frame.size.width,
                                                        tempCurrentAngle.frame.size.height);
                    tempCurrentAngle.transform = CGAffineTransformMakeRotation((CGFloat)(90 * M_PI/180.0));
                } completion:^(BOOL tcUnused) {
                    tempCurrentOrientation.text = self->_orientationDictionary[@(self->_phoneOrientation)];
                }];
            });
        }
    }
}

@end
