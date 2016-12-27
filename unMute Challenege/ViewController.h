//
//  ViewController.h
//  unMute Challenege
//
//  Created by Zaid Daghestani on 12/26/16.
//  Copyright © 2016 ark. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIViewControllerPreviewingDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *bgImage;
@property (nonatomic, strong) IBOutlet UILabel *lblImageCredits, *lblTime, *lblDate, *lblDay;
@property (nonatomic, strong) IBOutlet UISegmentedControl *newsSegment;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) id<UIViewControllerPreviewing> previewingContext;

-(IBAction)changeSegment:(id)sender;

@end

