//
//  FileUtil.h
//  VFXDataRecorder
//
//  Created by Steve McFarlin (AlignOfSight@stevemcfarlin.com) on 3/29/10.
//  Copyright 2010 Steve McFarlin All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @abstract
     File system utilities. 
*/
@interface SMFileUtil : NSObject {

}

+ (void) redirectConsoleLogToDocumentFolder;

/*!
 @abstract
    Return the path of the Documents directory
*/
+ (NSString*) applicationDocumentsDirectory;

/*!
 @abstract
    Get the path of a resource directory.
    
 @discussino
    This method will create the directory if it does not exist
    
*/
+ (NSString*) getResourceDirectory:(NSString*) dir;

/*!
 @abstract
    Create a directory.
    
 @param dir
*/
+ (NSError*) createDirectory:(NSString*) dir;

/**
	Copy a file from the source path to the destination path
	
	@param src The source path
	@param dest The destination path
*/
+ (void) copyFileFrom: (NSString*) src toDest:(NSString*)dest;

/**
	Delete a set of files. 
    
    This function silently fails if a an error occurs,
    or a file does not exist
	
	@param files An array of files
*/
+ (void) deleteFiles: (NSArray*) files;

/**
    Delete a file
    
    @param file
*/
+ (NSError*) deleteFile:(NSString*) file;

/**
	Clean all files in a directory
	
	@param dir The name of the directory
*/
+ (void) cleanDirectory:(NSString*) dir;

@end
