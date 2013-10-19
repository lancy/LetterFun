//
//  CYViewController.m
//  LetterFun
//
//  Created by Lancy on 18/10/13.
//  Copyright (c) 2013 GraceLancy. All rights reserved.
//

#import "CYViewController.h"
#import "CYLetterManager.h"
#import "CYWordHacker.h"

@interface CYViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *resultsButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) CYWordHacker *hacker;
@property (strong, nonatomic) NSArray *results;
@end

@implementation CYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self training];
    self.hacker = [[CYWordHacker alloc] init];
    if (!self.results || self.results.count == 0) {
        [self.resultsButton setEnabled:NO];
    }
}
- (IBAction)didTapResultButton:(id)sender {
    [self performSegueWithIdentifier:@"showResults" sender:self];
}

- (IBAction)didTapPickImageButton:(id)sender {
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *originImage = info[UIImagePickerControllerOriginalImage];
    [self.imageView setImage:originImage];
    [self.statusLabel setText:@"processing..."];
    [self dismissViewControllerAnimated:YES completion:^{
        [self processImage:originImage];
    }];
}

- (void)processImage:(UIImage *)image
{
    CYLetterManager *manager = [[CYLetterManager alloc] initWithImage:image];
    NSArray *alphabets = [manager ocrAlphabets];
    NSArray *words = [self.hacker getAllValidWordWithAlphabets:alphabets];
    
    self.statusLabel.text = [NSString stringWithFormat:@"OCR: %@", [alphabets componentsJoinedByString:@""]];
    
    self.results = words;
    [self.resultsButton setEnabled:YES];
    [self performSegueWithIdentifier:@"showResults" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showResults"]) {
        [segue.destinationViewController setResults:self.results];
    }
}

#pragma mark - training

- (void)training
{
    NSArray *string = @[@"tejntgzhhgpsmzpthaoudgbph",
                        @"fblvbpvuobbngthusbxbevsdg",
                        @"gzylanysrsofqwrbidsypdpln",
                        @"aotkimsyenzuwyvscinkoxebd"];
    for (NSInteger i = 0; i < 4; i++) {
        NSString *name = [NSString stringWithFormat:@"sample%ld", (long)i];
        [self trainingFromString:string[i] imageName:name];
    }
}

- (void)trainingFromString:(NSString *)string imageName:(NSString *)imageName
{
    UIImage *sampleImage = [UIImage imageNamed:imageName];
    CYLetterManager *manager = [[CYLetterManager alloc] initWithImage:sampleImage];
    NSArray *trainingArray = [self trainingArrayFromString:string];
    [manager trainingWihtAlphabets:[self trainingArrayFromString:string]];
    NSArray *ocrResult = [manager ocrAlphabets];
    for (NSInteger i = 0; i < 25; i++) {
        if (![ocrResult[i] isEqualToString:trainingArray[i]]) {
            NSLog(@"Error, result = %@, origin = %@", ocrResult[i], trainingArray[i]);
        }
    }
}

- (NSArray *)trainingArrayFromString:(NSString *)string
{
    NSMutableArray *trainingArray = [NSMutableArray array];
    for (NSInteger i = 0; i < string.length; i++) {
        NSString *alphabet = [string substringWithRange:NSMakeRange(i, 1)];
        [trainingArray addObject:alphabet];
    }
    return trainingArray;
}


@end
