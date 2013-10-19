//
//  CYLetterManager.m
//  LetterFun
//
//  Created by Lancy on 18/10/13.
//  Copyright (c) 2013 GraceLancy. All rights reserved.
//

#import "CYLetterManager.h"
@import ImageIO;
@import MobileCoreServices;

@implementation CYLetterManager {
    CGImageRef *_tagImageRefs;
    UIImage *_image;
    CGImageRef *_needProcessImage;
}

const int RED = 0;
const int GREEN = 1;
const int BLUE = 2;
const int ALPHA = 3;

- (id)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        _image = image;
        [self prepareTagImageRefs];
        [self getNeedProcessImages];
    }
    return self;
}

- (void)prepareTagImageRefs
{
    _tagImageRefs = malloc(26 * sizeof(CGImageRef));
    for (NSInteger i = 0; i < 26; i++) {
        char ch = 'a' + i;
        NSString *alpha = [NSString stringWithFormat:@"%c", ch];
        _tagImageRefs[i] = [self createImageWithAlphabet:alpha];
        if (_tagImageRefs[i] == NULL) {
            NSLog(@"Need sample: %c", ch);
        }
    }
}

- (void)dealloc
{
    for (NSInteger i = 0; i < 26; i++) {
        if (_tagImageRefs[i] != NULL) {
            CGImageRelease(_tagImageRefs[i]);
        }
    }
    free(_tagImageRefs);
    for (NSInteger i = 0; i < 25; i++) {
        CGImageRelease(_needProcessImage[i]);
    }
    free(_needProcessImage);
}

- (void)trainingWihtAlphabets:(NSArray *)array
{
    for (NSInteger i = 0; i < 25; i++) {
        if (array[i]) {
            [self writeImage:_needProcessImage[i] withAlphabet:array[i]];
        }
    }
    [self prepareTagImageRefs];
}

- (void)getNeedProcessImages
{
    CGImageRef originImageRef = [_image CGImage];
    CGImageRef alphabetsRegionImageRef = CGImageCreateWithImageInRect(originImageRef, CGRectMake(0, CGImageGetHeight(originImageRef) - 640, 640, 640));
    CGFloat width = 640;
    CGFloat height = 640;
    CGFloat blockWidth = width / 5.0;
    CGFloat blockHeight = height / 5.0;
    
    CGImageRef *imagesRefs = malloc(25 * sizeof(CGImageRef));
    
    // create image blocks
    for (NSInteger i = 0; i < 5; i++) {
        for (NSInteger j = 0; j < 5; j++) {
            CGRect alphabetRect = CGRectMake(j * blockWidth, i * blockHeight, blockWidth, blockHeight);
            CGImageRef alphabetImageRef = CGImageCreateWithImageInRect(alphabetsRegionImageRef, alphabetRect);
            imagesRefs[i * 5 + j] = alphabetImageRef;
        }
    }
    
    // transform to binaryImage
    for (NSInteger i = 0; i < 25; i++) {
        CGImageRef binaryImage = [self createBinaryCGImageFromCGImage:imagesRefs[i]];
        CGImageRelease(imagesRefs[i]);
        imagesRefs[i] = binaryImage;
    }
    
    _needProcessImage = imagesRefs;
    CGImageRelease(alphabetsRegionImageRef);
}

- (NSArray *)ocrAlphabets
{
    NSMutableArray *alphabets = [NSMutableArray arrayWithCapacity:25];
    for (NSInteger i = 0; i < 25; i++) {
        NSString *alphabet = [self ocrCGImage:_needProcessImage[i]];
        if (alphabet) {
            [alphabets addObject:alphabet];
        } else {
            [alphabets addObject:@"unknown"];
        }
    }
    return [alphabets copy];
}


- (NSString *)ocrCGImage:(CGImageRef)imageRef
{
    NSInteger result = -1;
    for (NSInteger i = 0; i < 26; i++) {
        CGImageRef tagImage = _tagImageRefs[i];
        if (tagImage != NULL) {
            CGFloat similarity = [self similarityBetweenCGImage:imageRef andCGImage:tagImage];
            if (similarity > 0.92) {
                result = i;
                break;
            }
        }
    }
    if (result == -1) {
        return nil;
    } else {
        char ch = 'a' + result;
        NSString *alpha = [NSString stringWithFormat:@"%c", ch];
        return alpha;
    }
}

// suppose imageRefA has same size with imageRefB
- (CGFloat)similarityBetweenCGImage:(CGImageRef)imageRefA andCGImage:(CGImageRef)imageRefB
{
    CGFloat similarity = 0;
    NSInteger width = CGImageGetWidth(imageRefA);
    NSInteger height = CGImageGetHeight(imageRefA);
    CGRect imageRect = CGRectMake(0, 0, width, height);
    
    UInt32 *pixelsOfImageA = (UInt32 *)malloc(width * height * sizeof(UInt32));
    UInt32 *pixelsOfImageB = (UInt32 *)malloc(width * height * sizeof(UInt32));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextA = CGBitmapContextCreate(pixelsOfImageA, width, height, 8, width * sizeof(UInt32), colorSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    CGContextRef contextB = CGBitmapContextCreate(pixelsOfImageB, width, height, 8, width * sizeof(UInt32), colorSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(contextA, imageRect, imageRefA);
    CGContextDrawImage(contextB, imageRect, imageRefB);
    
    NSInteger similarPixelCount = 0;
    NSInteger allStrokePixelCount = 0;
    for (NSInteger y = 0; y < height; y++) {
        for (NSInteger x = 0; x < width; x++) {
            UInt8 *rgbaPixelA = (UInt8 *)&pixelsOfImageA[y * width + x];
            UInt8 *rgbaPixelB = (UInt8 *)&pixelsOfImageB[y * width + x];
            if (rgbaPixelA[RED] == 0) {
                allStrokePixelCount++;
                if (rgbaPixelA[RED] == rgbaPixelB[RED]) {
                    similarPixelCount++;
                }
            }
        }
    }
    similarity = (CGFloat)similarPixelCount / (CGFloat)allStrokePixelCount;
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(contextA);
    CGContextRelease(contextB);
    free(pixelsOfImageA);
    free(pixelsOfImageB);
    
    return similarity;
}

- (CGImageRef)createBinaryCGImageFromCGImage:(CGImageRef)imageRef
{
    NSInteger width = CGImageGetWidth(imageRef);
    NSInteger height = CGImageGetHeight(imageRef);
    CGRect imageRect = CGRectMake(0, 0, width, height);
    
    UInt32 *pixels = (UInt32 *)malloc(width * height * sizeof(UInt32));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextA = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(UInt32), colorSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(contextA, imageRect, imageRef);
    
    for (NSInteger y = 0; y < height; y++) {
        for (NSInteger x = 0; x < width; x++) {
            UInt8 *rgbaPixel = (UInt8 *)&pixels[y * width + x];
            NSInteger r = rgbaPixel[RED];
            NSInteger g = rgbaPixel[GREEN];
            NSInteger b = rgbaPixel[BLUE];
            if (r + g + b > 255) {
                rgbaPixel[RED] = 255;
                rgbaPixel[GREEN] = 255;
                rgbaPixel[BLUE] = 255;
            } else {
                rgbaPixel[RED] = 0;
                rgbaPixel[GREEN] = 0;
                rgbaPixel[BLUE] = 0;
            }
        }
    }
    CGImageRef result = CGBitmapContextCreateImage(contextA);
    CGContextRelease(contextA);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    return result;
}

- (NSString *)pathStringWithAlphabet:(NSString *)alphabet
{
    NSString *imageName = [alphabet stringByAppendingString:@".png"];
    NSString *documentsPath = [@"~/Documents" stringByExpandingTildeInPath];
    NSString *path = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@", imageName]];
    return path;
}

- (CGImageRef)createImageWithAlphabet:(NSString *)alphabet
{
    NSString *path = [self pathStringWithAlphabet:alphabet];
    CGImageRef image = [self createImageFromFile:path];
    return image;
}

- (CGImageRef)createImageFromFile:(NSString *)path
{
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGDataProviderRef dataProvider = CGDataProviderCreateWithURL(url);
    CGImageRef image = CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    return image;
}

- (void)writeImage:(CGImageRef)imageRef withAlphabet:(NSString *)alphabet
{
    NSString *path = [self pathStringWithAlphabet:alphabet];
    [self writeImage:imageRef toFile:path];
}

- (void)writeImage:(CGImageRef)imageRef toFile:(NSString *)path
{
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, imageRef, nil);
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
    }
    CFRelease(destination);
}

@end
