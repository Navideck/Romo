//
//  UIImage+Save.m
//  Romo
//

#import "UIImage+Save.h"
#import "RMAlertView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

static RMAlertView *photosNotAllowed;

@implementation UIImage (Save)

+ (void)writeToSavedPhotoAlbumWithImage:(UIImage *)image
                       completionTarget:(id)completionTarget
                     completionSelector:(SEL)completionSelector
                            contextInfo:(void *)contextInfo {
    
    if (@available(iOS 8, *)) {
        DDLogVerbose(@"%ld", (long)[PHPhotoLibrary authorizationStatus]);

        PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
        // There are 4 possible auth statuses. These are the two that prevent access to the library
        if (authStatus == PHAuthorizationStatusDenied || authStatus == PHAuthorizationStatusRestricted) {
            [UIImage presentPhotosPermissionError];
        } else if (authStatus == PHAuthorizationStatusNotDetermined) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
                if (status == PHAuthorizationStatusAuthorized) {
                    [UIImage writeToSavedPhotoAlbumWithImage:image completionTarget:completionTarget completionSelector:completionSelector contextInfo:contextInfo];
                } else {
                    [UIImage presentPhotosPermissionError];
                }
            }];
        } else {
            UIImageWriteToSavedPhotosAlbum(image, completionTarget, completionSelector, contextInfo);
        }
    } else {
        DDLogVerbose(@"%ld", (long)[ALAssetsLibrary authorizationStatus]);

        ALAuthorizationStatus authStatus = [ALAssetsLibrary authorizationStatus];
        // There are 4 possible auth statuses. These are the two that prevent access to the library
        if (authStatus == ALAuthorizationStatusDenied || authStatus == ALAuthorizationStatusRestricted) {
            [UIImage presentPhotosPermissionError];
        } else if (authStatus == ALAuthorizationStatusNotDetermined) {
            ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
            // Trigger photo library permission
            [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                [UIImage writeToSavedPhotoAlbumWithImage:image completionTarget:completionTarget completionSelector:completionSelector contextInfo:contextInfo];
            } failureBlock:^(NSError *error) {
                [UIImage presentPhotosPermissionError];
            }];
        } else {
            UIImageWriteToSavedPhotosAlbum(image, completionTarget, completionSelector, contextInfo);
        }
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
