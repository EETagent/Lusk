//
//  UloztoResolutionStatus.h
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

typedef NS_ENUM(NSUInteger, UloztoResolutionStatus) {
    STARTING,
    LOADING,
    CRACKING,
    LIMIT_EXCEEDED,
    BLOCKED,
    FORM_ERROR_CONTENT,
    DOWNLOADING,
    ERROR,
    OK,
};
