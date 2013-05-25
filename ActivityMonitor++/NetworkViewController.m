//
//  NetworkViewController.m
//  ActivityMonitor++
//
//  Created by st on 23/05/2013.
//  Copyright (c) 2013 st. All rights reserved.
//

#import "GLLineGraph.h"
#import "AppDelegate.h"
#import "AMLog.h"
#import "AMUtils.h"
#import "NetworkInfoController.h"
#import "NetworkViewController.h"

enum {
    SECTION_NETWORK_INFORMATION=0
};

@interface NetworkViewController() <NetworkInfoControllerDelegate>
@property (strong, nonatomic) GLLineGraph   *networkGraph;
@property (strong, nonatomic) GLKView       *networkGLView;

- (void)updateBandwidthLabels:(NetworkBandwidth*)bandwidth;

@property (weak, nonatomic) IBOutlet UILabel *networkTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *externalIPLabel;
@property (weak, nonatomic) IBOutlet UILabel *internalIPLabel;
@property (weak, nonatomic) IBOutlet UILabel *netmaskLabel;
@property (weak, nonatomic) IBOutlet UILabel *broadcastAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;

@property (weak, nonatomic) IBOutlet UILabel *totalWiFiDownloadsLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalWiFiUploadsLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalWWANDownloadsLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalWWANUploadsLabel;
@end

@implementation NetworkViewController
@synthesize networkGraph;
@synthesize networkGLView;

#pragma mark - override

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background-1496.png"]]];

    AppDelegate *app = [AppDelegate sharedDelegate];
    [self.networkTypeLabel setText:app.iDevice.networkInfo.readableInterface];
    [self.externalIPLabel setText:app.iDevice.networkInfo.externalIPAddress];
    [self.internalIPLabel setText:app.iDevice.networkInfo.internalIPAddress];
    [self.netmaskLabel setText:app.iDevice.networkInfo.netmask];
    [self.broadcastAddressLabel setText:app.iDevice.networkInfo.broadcastAddress];
    [self.macAddressLabel setText:app.iDevice.networkInfo.macAddress];
    
    self.networkGLView = [[GLKView alloc] initWithFrame:CGRectMake(0.0f, 30.0f, 703.0f, 200.0f)];
    self.networkGLView.opaque = NO;
    self.networkGLView.backgroundColor = [UIColor clearColor];
    self.networkGraph = [[GLLineGraph alloc] initWithGLKView:self.networkGLView dataLineCount:2 fromValue:0.0f toValue:100.0f legends:[NSArray arrayWithObject:@"WiFi"]];
    self.networkGraph.preferredFramesPerSecond = kNetworkUpdateFrequency;

    [app.networkInfoCtrl setNetworkBandwidthHistorySize:[self.networkGraph requiredElementToFillGraph]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    AppDelegate *app = [AppDelegate sharedDelegate];
    
    // Make sure the labels are not empty.
    NetworkBandwidth *bandwidth = [app.networkInfoCtrl.networkBandwidthHistory lastObject];
    if (bandwidth)
    {
        [self updateBandwidthLabels:bandwidth];
    }

    NSMutableArray *bandwidthArray = [[NSMutableArray alloc] initWithCapacity:app.networkInfoCtrl.networkBandwidthHistory.count];
    NSArray *bandwidthHistory = [NSArray arrayWithArray:app.networkInfoCtrl.networkBandwidthHistory];
    
    for (NSUInteger i = 0; i < bandwidthHistory.count; ++i)
    {
        NetworkBandwidth *bandwidth = [bandwidthHistory objectAtIndex:i];
        NSNumber *upValue = [NSNumber numberWithFloat:bandwidth.sent];
        NSNumber *downValue = [NSNumber numberWithFloat:bandwidth.received];
        [bandwidthArray addObject:[NSArray arrayWithObjects:upValue, downValue, nil]];
    }
    [self.networkGraph resetDataArray:bandwidthArray];
    
    app.networkInfoCtrl.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    AppDelegate *app = [AppDelegate sharedDelegate];
    app.networkInfoCtrl.delegate = nil;
}

#pragma mark - private

- (void)updateBandwidthLabels:(NetworkBandwidth*)bandwidth
{
    [self.totalWiFiDownloadsLabel setText:[NSString stringWithFormat:@"%0.1f MB", KB_TO_MB(bandwidth.totalWiFiReceived)]];
    [self.totalWiFiUploadsLabel setText:[NSString stringWithFormat:@"%0.1f MB", KB_TO_MB(bandwidth.totalWiFiSent)]];
    [self.totalWWANDownloadsLabel setText:[NSString stringWithFormat:@"%0.1f MB", KB_TO_MB(bandwidth.totalWWANReceived)]];
    [self.totalWWANUploadsLabel setText:[NSString stringWithFormat:@"%0.1f MB", KB_TO_MB(bandwidth.totalWWANSent)]];
}

#pragma mark - Table view data source

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == SECTION_NETWORK_INFORMATION)
    {
        UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LineGraphBackground-464.png"]];
        CGRect frame = backgroundView.frame;
        frame.origin.y = 20;
        backgroundView.frame = frame;
        
        UIView *view;
        view = [[UIView alloc] initWithFrame:self.networkGLView.frame];
        [view addSubview:backgroundView];
        [view sendSubviewToBack:backgroundView];
        [view addSubview:self.networkGLView];
        return view;
    }
    else
    {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == SECTION_NETWORK_INFORMATION)
    {
        return 280.0f;
    }
    else
    {
        return 0.0f;
    }
}

#pragma mark - NetworkInfoController delegate

- (void)networkBandwidthUpdated:(NetworkBandwidth*)bandwidth
{
    [self updateBandwidthLabels:bandwidth];
    
    NSNumber *upValue = [NSNumber numberWithFloat:bandwidth.sent];
    NSNumber *downValue = [NSNumber numberWithFloat:bandwidth.received];
    [self.networkGraph addDataValue:[NSArray arrayWithObjects:upValue, downValue, nil]];
}

@end