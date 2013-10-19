//
//  CYResultsViewController.m
//  LetterFun
//
//  Created by Lancy on 19/10/13.
//  Copyright (c) 2013 GraceLancy. All rights reserved.
//

#import "CYResultsViewController.h"

@interface CYResultsViewController ()

@property (strong, nonatomic) NSMutableDictionary *selectedRow;

@end

@implementation CYResultsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.selectedRow = [NSMutableDictionary dictionary];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [cell.textLabel setText:self.results[indexPath.row]];
    if ([self.selectedRow[indexPath] isEqualToNumber:@(YES)]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        self.selectedRow[indexPath] = @(YES);
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        self.selectedRow[indexPath] = @(NO);
    }
}

@end
