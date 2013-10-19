//
//  CYWordHacker.m
//  LetterFun
//
//  Created by Lancy on 18/10/13.
//  Copyright (c) 2013 GraceLancy. All rights reserved.
//

#import "CYWordHacker.h"

@interface CYWordHacker()
@property (strong, nonatomic) NSArray *allWords;
@end

@implementation CYWordHacker

- (id)init
{
    self = [super init];
    if (self) {
        [self prepareDictionary];
    }
    return self;
}

- (void)prepareDictionary
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"words"
                                                     ofType:@"txt"];
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
    NSArray *allLinedStrings = [content componentsSeparatedByCharactersInSet:
     [NSCharacterSet newlineCharacterSet]];
    self.allWords = allLinedStrings;
}

- (NSArray *)getAllValidWordWithAlphabets:(NSArray *)alphabets
{
    NSMutableArray *validWords = [NSMutableArray array];
    for (NSString *word in self.allWords) {
        if ([self isValidWord:word withAlphabets:alphabets]) {
            [validWords addObject:word];
        }
    }
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"length"
                                                  ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    [validWords sortUsingDescriptors:sortDescriptors];
    return validWords;
}

- (BOOL)isValidWord:(NSString *)word withAlphabets:(NSArray *)alphabets
{
    NSInteger supplyAlpha[26] = {0};
    NSInteger needAlpha[26] = {0};
    for (NSString *alphabet in alphabets) {
        const char *ch = [alphabet UTF8String];
        supplyAlpha[ch[0] - 'a']++;
    }
    const char *cWord = [word UTF8String];
    for (int i = 0; i < word.length; i++) {
        NSInteger index = cWord[i] - 'a';
        if (supplyAlpha[index] == 0) {
            return NO;
        } else {
            needAlpha[index]++;
            if (needAlpha[index] > supplyAlpha[index]) {
                return NO;
            }
        }
    }
    return YES;
}

@end
