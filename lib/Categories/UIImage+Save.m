//
//  UIImage+Save.m
//  Romo
//

#import "UIImage+Save.h"
#import "RMAlertView.h"
#import <Photos/Photos.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

static RMAlertView *photosNotAllowed;

@implementation UIImage (Save)

+ (void)writeToSavedPhotoAlbumWithImage:(UIImage *)image
                       completionTarget:(id)completionTarget
                     completionSelector:(SEL)completionSelector
                            contextInfo:(void *)contextInfo {
    
    DDLogVerbose(@"%ld", (long)[PHPhotoLibrary authorizationStatus]);

    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    // There are 4 possible auth statuses. These are the two that prevent access to the library
    if (authStatus == PHAuthorizationStatusDenied || authStatus == PHAuthorizationStatusRestricted) {
        [UIImage presentPhotosPermissionError];
    } else if (authStatus == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
            [UIImage writeToSavedPhotoAlbumWithImage:image completionTarget:completionTarget completionSelector:completionSelector contextInfo:contextInfo];
        }];
    } else {
        UIImageWriteToSavedPhotosAlbum(image, completionTarget, completionSelector, contextInfo);
    }
}

+(void)presentPhotosPermissionError {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (photosNotAllowed == nil) {
            photosNotAllowed = [[RMAlertView alloc] initWithTitle:@"Romo can't save photos!"
                                                          message:@"To allow Romo to save photos to your Camera Roll, go to Settings > Privacy > Photos, and allow Romo access to your photos."
                                                         delegate:nil];
        }

        [photosNotAllowed show];
    });
}

@end
