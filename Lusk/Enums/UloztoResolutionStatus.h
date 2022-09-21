//
//  UloztoResolutionStatus.h
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

typedef NS_ENUM(NSUInteger, UloztoResolutionStatus) {
    STARTING,
    TOR_STARTING,
    TOR_OK,
    TOR_ERROR,
    LOADING,
    CRACKING,
    LIMIT_EXCEEDED,
    BLOCKED,
    FORM_ERROR_CONTENT,
    DOWNLOADING,
    ERROR,
    OK,
};
