//
//  ViewController.m
//  unMute Challenege
//
//  Created by Zaid Daghestani on 12/26/16.
//  Copyright © 2016 ark. All rights reserved.
//

#import "ViewController.h"
#import "MKNetworkKit.h"
#import "NSString+BaseString.h"
#import "Tweet.h"
#import <SafariServices/SafariServices.h>

#import "HashCell.h"

#define FLICKER_KEY @"aec31218c66a4969080fa661bf51ea24"
#define FLICKER_SECRET @"25bd87e41b0b5177"
#define TWITTER_US @"23424977"
#define TWITTER_WORLD @"1"
#define TWITTER_TOKEN @"JiM1l9clABVhhUO2Zsh51QhR1"
#define TWITTER_SECRET @"T1LNPwgTThMLoGdTcsi6lZbnWedLQZd8ZW6RngkEmGGIPUHIlf"

@interface ViewController () {
    MKNetworkHost *host;
    NSTimer *timer;
    NSDateFormatter *timeFormatter;
    NSDateFormatter *dayFormatter;
    NSDateFormatter *dateFormatter;
    NSString *twitterKey;
    NSMutableDictionary *trends;
    NSString *currentTweets;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    host = [[MKNetworkHost alloc] initWithHostName:@""];
    //flicker photos first, we need images to look good asap
    [self getFlickerPhoto];
    
    // set up clock
    [self setupDates];
    timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    
    // get trending tweets
    trends = NSMutableDictionary.new;
    currentTweets = TWITTER_US;
    [self getTweets];
    if ([self isForceTouchAvailable]) {
        self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }
}

-(void)getTweets{
    MKNetworkRequest *req = [host requestWithURLString:@"https://api.twitter.com/oauth2/token"];
    NSString *basic = [NSString stringWithFormat:@"Basic %@", [[NSString stringWithFormat:@"%@:%@", TWITTER_TOKEN, TWITTER_SECRET] base64]];
    [req addHeaders:@{@"Authorization":basic}];
    [req setParameterEncoding:MKNKParameterEncodingURL];
    [req addParameters:@{@"grant_type":@"client_credentials"}];
    req.httpMethod = @"POST";
    [req addCompletionHandler:^(MKNetworkRequest *completedRequest) {
        twitterKey = [NSString stringWithFormat:@"Bearer %@", completedRequest.responseAsJSON[@"access_token"]];
        [self getTrendingTweets:TWITTER_US];
        [self getTrendingTweets:TWITTER_WORLD];
    }];
    [host startRequest:req];
}

-(void)getTrendingTweets:(NSString *)place {
    MKNetworkRequest *req = [host requestWithURLString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/trends/place.json?id=%@", place]];
    [req addHeaders:@{@"Authorization":twitterKey}];
    [req addCompletionHandler:^(MKNetworkRequest *completedRequest) {
        NSMutableArray *tweets = NSMutableArray.new;
        id response = completedRequest.responseAsJSON[0];
        for (NSDictionary *d in response[@"trends"]) {
            [tweets addObject:[Tweet fromDict:d]];
        }
        trends[place] = tweets;
        if ([currentTweets isEqualToString:place]) {
            NSLog(@"Tableview reload");
            [self.tableView reloadData];
        } else {
            NSLog(@"Tableview no reload");
        }
    }];
    [host startRequest:req];
}

-(void)getFlickerPhoto {
    MKNetworkRequest *req = [host requestWithURLString:[NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.interestingness.getList&api_key=%@&format=json&per_page=10", FLICKER_KEY]];
    [req addCompletionHandler:^(MKNetworkRequest *completedRequest) {
        NSDictionary *responseDict = [self flickerResponseDictionary:completedRequest.responseAsString];
        NSArray *photos = responseDict[@"photos"][@"photo"];
        [self getPhotoData:photos[0]];
    }];
    [host startRequest:req];
    
}

- (UIViewController *)previewingContext:(id )previewingContext viewControllerForLocation:(CGPoint)location{
    // check if we're not already displaying a preview controller (WebViewController is my preview controller)
    if ([self.presentedViewController isKindOfClass:[SFSafariViewController class]]) {
        return nil;
    }
    
    CGPoint cellPostion = [self.tableView convertPoint:location fromView:self.view];
    NSIndexPath *path = [self.tableView indexPathForRowAtPoint:cellPostion];
    
    if (path) {
        UITableViewCell *tableCell = [self.tableView cellForRowAtIndexPath:path];
        
        // get your UIStoryboard
        
        // set the view controller by initializing it form the storyboard
        Tweet *t = trends[currentTweets][path.row];
        SFSafariViewController *previewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:t.url]];
        
        // if you want to transport date use your custom "detailItem" function like this:
        [previewingContext setSourceRect:[self.view convertRect:tableCell.frame fromView:self.tableView]];
        return previewController;
    }
    return nil;
}

- (void)previewingContext:(id )previewingContext commitViewController: (UIViewController *)viewControllerToCommit {
    
    // if you want to present the selected view controller as it self us this:
    // [self presentViewController:viewControllerToCommit animated:YES completion:nil];
    
    // to render it with a navigation controller (more common) you should use this:
    [self presentViewController:viewControllerToCommit animated:YES completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self isForceTouchAvailable]) {
        if (!self.previewingContext) {
            self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
        }
    } else {
        if (self.previewingContext) {
            [self unregisterForPreviewingWithContext:self.previewingContext];
            self.previewingContext = nil;
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Tweet *t = trends[currentTweets][indexPath.row];
    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:t.url]];
    [self presentViewController:safari animated:YES completion:nil];
}

-(void)getPhotoData:(NSDictionary *)photo {
    [self getOwnerData:photo[@"owner"]];
    MKNetworkRequest *req =[host requestWithURLString:[NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.photos.getSizes&api_key=%@&format=json&photo_id=%@", FLICKER_KEY, photo[@"id"]]];
    [req addCompletionHandler:^(MKNetworkRequest *completedRequest) {
        NSDictionary *photoSizes = [self flickerResponseDictionary:completedRequest.responseAsString];
        NSString *largeUrl = nil;
        NSNumber *largeSize = [NSNumber numberWithInt:0];
        NSString *mediumUrl = nil;
        NSString *originalUrl = nil;
        for (NSDictionary *size in photoSizes[@"sizes"][@"size"]) {
            if ([size[@"label"] isEqualToString:@"Large"]) {
                largeUrl = size[@"source"];
                largeSize = size[@"height"];
            } else if ([size[@"label"] isEqualToString:@"Medium"]) {
                mediumUrl = size[@"source"];
            } else if ([size[@"label"] isEqualToString:@"Original"]) {
                if ([size[@"height"] intValue] > [largeSize intValue]) {
                    originalUrl = size[@"source"];
                }
            }
        }
        if (originalUrl) {
            [self downloadPhoto:originalUrl];
        } else if (largeUrl) {
            [self downloadPhoto:largeUrl];
        } else if (mediumUrl) {
            [self downloadPhoto:mediumUrl];
        }
    }];
    [host startRequest:req];
}

-(void)getOwnerData:(NSString *)owner {
    
    MKNetworkRequest *req =[host requestWithURLString:[NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.people.getInfo&api_key=%@&format=json&user_id=%@", FLICKER_KEY, owner]];
    [req addCompletionHandler:^(MKNetworkRequest *completedRequest) {
        NSDictionary *person = [self flickerResponseDictionary:completedRequest.responseAsString];
        self.lblImageCredits.text = [NSString stringWithFormat:@"Photo courtesy of %@", person[@"person"][@"username"][@"_content"]];
    }];
    [host startRequest:req];
}

-(void)downloadPhoto:(NSString *)url {
    MKNetworkRequest *req = [host requestWithURLString:url];
    [req addCompletionHandler:^(MKNetworkRequest *completedRequest) {
        UIImage *image = completedRequest.responseAsImage;
        self.bgImage.image = image;
    }];
    [host startRequest:req];
}

-(NSDictionary *)flickerResponseDictionary:(NSString *)responseString {
    NSString *cleanResponse = [responseString substringWithRange:NSMakeRange(14, [responseString length] - 15)];
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:[cleanResponse dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    return responseDict;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [trends[currentTweets] count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HashCell *cell = [tableView dequeueReusableCellWithIdentifier:@"hashtag"];
    cell.hashLabel.text = [trends[currentTweets][indexPath.row] name];
    return cell;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)changeSegment:(UISegmentedControl *)sender {
    if ([sender selectedSegmentIndex] == 0) {
        currentTweets = TWITTER_US;
    } else {
        currentTweets = TWITTER_WORLD;
    }
    [self.tableView reloadData];
}

- (void)setupDates {
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    timeFormatter = [NSDateFormatter new];
    timeFormatter.locale = usLocale;
    timeFormatter.dateStyle = NSDateFormatterNoStyle;
    timeFormatter.timeStyle = NSDateFormatterShortStyle;
    dateFormatter = [NSDateFormatter new];
    dateFormatter.locale = usLocale;
    dateFormatter.dateStyle = NSDateFormatterLongStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dayFormatter = [NSDateFormatter new];
    dayFormatter.locale = usLocale;
    [dayFormatter setDateFormat:@"EEEE"];
    [self updateTime];
}

-(void)updateTime {
    NSDate *date = [NSDate date];
    self.lblDay.text = [dayFormatter stringFromDate:date];
    self.lblDate.text = [dateFormatter stringFromDate:date];
    self.lblTime.text = [timeFormatter stringFromDate:date];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)isForceTouchAvailable {
    BOOL isForceTouchAvailable = NO;
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        isForceTouchAvailable = self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
    }
    return isForceTouchAvailable;
}


@end
