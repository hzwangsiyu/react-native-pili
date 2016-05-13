//
//  RCTPlayer.m
//  RCTPili
//
//  Created by buhe on 16/5/12.
//  Copyright © 2016年 pili. All rights reserved.
//

#import "RCTPlayer.h"
#import "RCTBridgeModule.h"
#import "RCTEventDispatcher.h"

@implementation RCTPlayer{
    RCTEventDispatcher *_eventDispatcher;
    PLPlayer *_plplayer;
}

static NSString *status[] = {
    @"PLPlayerStatusUnknow",
    @"PLPlayerStatusPreparing",
    @"PLPlayerStatusReady",
    @"PLPlayerStatusCaching",
    @"PLPlayerStatusPlaying",
    @"PLPlayerStatusPaused",
    @"PLPlayerStatusStopped",
    @"PLPlayerStatusError"
};


- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
    if ((self = [super init])) {
        _eventDispatcher = eventDispatcher;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
         self.reconnectCount = 0;
    }
    
    return self;
};

- (void) setSource:(NSDictionary *)source
{
    NSString *uri = source[@"uri"];
    bool backgroundPlay = source[@"backgroundPlay"] == nil ? false : source[@"backgroundPlay"];
    
    PLPlayerOption *option = [PLPlayerOption defaultOption];
    
    // 更改需要修改的 option 属性键所对应的值
    [option setOptionValue:@15 forKey:PLPlayerOptionKeyTimeoutIntervalForMediaPackets];

    _plplayer = [PLPlayer playerWithURL:[[NSURL alloc] initWithString:uri] option:option];

    _plplayer.delegate = self;
    _plplayer.delegateQueue = dispatch_get_main_queue();
    _plplayer.backgroundPlayEnable = backgroundPlay;
    if(backgroundPlay){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startPlayer) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    [self setupUI];
    
    [self startPlayer];
    
}

- (void)setupUI {
    if (_plplayer.status != PLPlayerStatusError) {
        // add player view
        UIView *playerView = _plplayer.playerView;
        [self addSubview:playerView];
         [playerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
        NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0];
        
        NSArray *constraints = [NSArray arrayWithObjects:centerX, centerY,width,height, nil];
        [self addConstraints: constraints];
    }
    
}

- (void)startPlayer {

    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [_plplayer play];
}

#pragma mark - <PLPlayerDelegate>

- (void)player:(nonnull PLPlayer *)player statusDidChange:(PLPlayerStatus)state {
    //TODO - send event
    NSLog(@"%@", status[state]);
}

- (void)player:(nonnull PLPlayer *)player stoppedWithError:(nullable NSError *)error {
    [self tryReconnect:error];
}

- (void)tryReconnect:(nullable NSError *)error {
    if (self.reconnectCount < 3) {
        _reconnectCount ++;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:[NSString stringWithFormat:@"错误 %@，播放器将在%.1f秒后进行第 %d 次重连", error.localizedDescription,0.5 * pow(2, self.reconnectCount - 1), _reconnectCount] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * pow(2, self.reconnectCount) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_plplayer play];
        });
    }else {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        NSLog(@"%@", error);
    }
}

@end
