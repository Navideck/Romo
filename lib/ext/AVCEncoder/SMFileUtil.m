//
//  FileUtil.m
//  VFXDataRecorder
//
//  Created by Steve McFarlin (AlignOfSight@stevemcfarlin.com) on 3/29/10.
//  Copyright 2010 Steve McFarlin All rights reserved.
//

#import "SMFileUtil.h"


@implementation SMFileUtil


+ (void) redirectConsoleLogToDocumentFolder {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory
                         stringByAppendingPathComponent:@"console.log"];
    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}

+ (NSString*) applicationDocumentsDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

+ (NSString*) getResourceDirectory:(NSString*) dir {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *upath = [ [paths objectAtIndex:0] stringByAppendingPathComponent:dir];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:upath]) {
		NSError *error = nil;
		[fileManager createDirectoryAtPath:upath withIntermediateDirectories:NO attributes:nil error:&error];
		if (error) {
			return nil;
		}
    }
	
    return upath;
}

+ (NSError*) createDirectory:(NSString*) path {
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    if ([fileManager fileExistsAtPath:path]) {
        return nil;
    }
    
    [fileManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
	
	if (error) {
        return error;
	}
    
    return nil;
}

+ (NSArray*) listDirectory:(NSString*) src {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *upDir = [SMFileUtil getResourceDirectory:src];
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:upDir];
	NSMutableArray *files = [[NSMutableArray alloc] init];
	NSString *file;
	
	while ((file = [dirEnum nextObject]) != nil) {
		file = [NSString stringWithFormat:@"%@/%@", upDir, file];
        
		[files addObject:file];
	}	
	return files;
}

+ (void) copyFileFrom: (NSString*) src toDest:(NSString*) dest{

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;

    if ([fileManager fileExistsAtPath:dest]) {
        return;
    }

    BOOL success = [fileManager copyItemAtPath:src toPath:dest error:&error];

    if(!success) {
        //NSLog(@"loadAssetsToDocumentsDirectory error: %@", [error localizedFailureReason]);
    }
}

+ (NSError*) deleteFile:(NSString*) file {
	NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *err;
	if ( ! [fileManager fileExistsAtPath:file]) {
		return nil;
	}
	
	BOOL success = [fileManager removeItemAtPath:file error:&err];
	if(!success) {
		return err;
	}
    return nil;
}

+ (void) cleanDirectory:(NSString*) dir {
	[self deleteFiles:[SMFileUtil listDirectory:dir]];
}

+ (void) deleteFiles: (NSArray*) files {
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *err;
	
	for (NSString *file in files) {
        
		if ( ! [fileManager fileExistsAtPath:file]) {
			continue;
		}

		BOOL success = [fileManager removeItemAtPath:file error:&err];
		if(!success) {
            
		}
	}
}

@end
