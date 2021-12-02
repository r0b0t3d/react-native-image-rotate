#import "ImageRotateModule.h"

#import <UIKit/UIKit.h>

#import <React/RCTConvert.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import "RCTImageUtils.h"

#import "RCTImageStoreManager.h"
#import "RCTImageLoader.h"

@implementation ImageRotateModule

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

static CGFloat DegreesToRadians(CGFloat degrees) {
  return degrees * M_PI / 180.0;
};

/**
 * Rotates an image and adds the result to the image store.
 *
 * @param imageURL A URL, a string identifying an asset etc.
 * @param angle Rotation angle in degrees
 */
RCT_EXPORT_METHOD(rotateImage:(NSString *)imageUri
                  angle:(nonnull NSNumber *)angle
                  successCallback:(RCTResponseSenderBlock)successCallback
                  errorCallback:(RCTResponseErrorBlock)errorCallback)
{
  NSString *parsedImageUri = [imageUri stringByReplacingOccurrencesOfString:@"file://" withString:@""];
  NSURL *fileURL = [NSURL fileURLWithPath:parsedImageUri];
  UIImage *image = [[UIImage new] initWithData:[NSData dataWithContentsOfURL:fileURL]];
  
  
  // calculate the size of the rotated view's containing box for our drawing space
  UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
  CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians([angle doubleValue]));
  rotatedViewBox.transform = t;
  CGSize rotatedSize = rotatedViewBox.frame.size;
  
  // Create the bitmap context
  UIGraphicsBeginImageContext(rotatedSize);
  CGContextRef bitmap = UIGraphicsGetCurrentContext();
  
  // Move the origin to the middle of the image so we will rotate and scale around the center.
  CGContextTranslateCTM(bitmap, rotatedSize.width / 2, rotatedSize.height / 2);
  
  // Rotate the image context
  CGContextRotateCTM(bitmap, DegreesToRadians([angle doubleValue]));
  
  // Now, draw the rotated/scaled image into the context
  CGContextScaleCTM(bitmap, 1.0, -1.0);
  CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), [image CGImage]);
  
  UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  NSData *imageToEncode = UIImageJPEGRepresentation(rotatedImage, 0.8);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *uuid = [[NSUUID new] UUIDString];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", uuid]];
    [imageToEncode writeToFile:dataPath atomically:YES];
    successCallback(@[dataPath]);
  });
}

@end
