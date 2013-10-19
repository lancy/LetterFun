//
//  CYLetterManager.h
//  LetterFun
//
//  Created by Lancy on 18/10/13.
//  Copyright (c) 2013 GraceLancy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CYLetterManager : NSObject

- (id)initWithImage:(UIImage *)image;
- (void)trainingWihtAlphabets:(NSArray *)array;
- (NSArray *)ocrAlphabets;

@end
