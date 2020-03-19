//
//  RMCutscene.m
//  Romo
//

#import "RMCutscene.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVKit/AVKit.h>

@interface RMCutscene ()

@property (nonatomic) int cutsceneNumber;
@property (nonatomic, strong) AVPlayerViewController *playerViewController;

@property (nonatomic, strong) NSTimer *playbackTimer;
@property (nonatomic, copy) void (^completion)(BOOL completion);

@property (nonatomic, strong) MPVolumeView *volumeView;
@property (nonatomic) BOOL boostedVolume;

@end

@implementation RMCutscene

- (void)playCutscene:(int)cutscene inView:(UIView *)view completion:(void (^)(BOOL))completion
{
    NSString *cutscenePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"Cutscene-%d",cutscene] ofType:@"m4v"];

    AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:cutscenePath]];
    self.playerViewController = [AVPlayerViewController new];
    self.playerViewController.player = player;
    self.playerViewController.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerViewController.showsPlaybackControls = false;
    self.playerViewController.view.frame = view.bounds;
    self.playerViewController.view.backgroundColor = [UIColor clearColor];
    self.playerViewController.view.accessibilityLabel = @"Cutscene";
    self.playerViewController.view.isAccessibilityElement = YES;

    [self.playerViewController.player.currentItem addObserver:self forKeyPath:@"status" options:0 context:nil];

    // trick to prevent iOS from showing the volume alert bezel
    self.volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0, 0, -1000, -1000)];
    self.volumeView.clipsToBounds = YES;
    [view addSubview:self.volumeView];
    [view addSubview:self.playerViewController.view];
    
#ifdef DEBUG
    UITapGestureRecognizer *threeFingerTripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleThreeFingerTripleTap:)];
#ifdef SIMULATOR
    threeFingerTripleTap.numberOfTouchesRequired = 1;
#else
    threeFingerTripleTap.numberOfTouchesRequired = 3;
#endif // SIMULATOR
    threeFingerTripleTap.numberOfTapsRequired = 3;
    [view addGestureRecognizer:threeFingerTripleTap];
    view.userInteractionEnabled = YES;
    self.playerViewController.view.userInteractionEnabled = NO;
    
#endif  // DEBUG
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerViewController.player.currentItem];

    self.boostedVolume = NO;
    
    self.cutsceneNumber = cutscene;
    self.completion = completion;
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [self startPlayingCutscene];
    }
}

- (UIView *)view
{
    return self.playerViewController.view;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods

- (void)playbackDidFinish:(NSNotification *)notification
{
    AVPlayerItem  *currentItem = notification.object;

    if (CMTimeGetSeconds(currentItem.duration) > 0 && ABS(CMTimeGetSeconds(currentItem.currentTime) - CMTimeGetSeconds(currentItem.duration)) < 0.06) {
        [self cleanupAfterPlaybackFinished];
    }
}

- (void)startPlayingCutscene
{
    if (!self.playbackTimer) {
        self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(playbackTimeDidChange:) userInfo:nil repeats:YES];
    }
    [self.playerViewController.player play];
}

- (void)cleanupAfterPlaybackFinished
{
    if (self.playbackTimer) {
        [self.playbackTimer invalidate];
        self.playbackTimer = nil;
    }
    
    if (self.volumeView) {
        [self.volumeView removeFromSuperview];
        self.volumeView = nil;
    }
    
    if (self.playerViewController) {
        [self.playerViewController.view removeFromSuperview];
        self.playerViewController = nil;
    }
    
    if (self.completion) {
        __strong RMCutscene *strongSelf = self;
        self.completion(YES);
        self.completion = nil;
        strongSelf = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.playerViewController.player.currentItem removeObserver:self forKeyPath:@"status"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"rate"]) {
        float time = CMTimeGetSeconds(self.playerViewController.player.currentItem.currentTime) - CMTimeGetSeconds(self.playerViewController.player.currentItem.duration);

        if ((self.playerViewController.player.rate == 0) && ABS(time) > 0.05) {
            [self.playerViewController.player play];
        }
    }
}

- (void)playbackTimeDidChange:(NSTimer *)playbackTimer
{
    float time = CMTimeGetSeconds(self.playerViewController.player.currentTime);

    if (!self.boostedVolume && time > 0.1) {
        [self boostVolume];
    }
    
    if (self.cutsceneNumber == 1) {
        if (time < 3.48) {
            [self.robot.LEDs turnOff];
        } else if (time < 3.53) {
            [self.robot.LEDs setSolidWithBrightness:0.8];
        } else if (time < 3.58) {
            [self.robot.LEDs turnOff];
        } else if (time < 3.63) {
            [self.robot.LEDs setSolidWithBrightness:1.0];
        } else if (time < 11.30) {
            [self.robot.LEDs turnOff];
        } else if (time < 11.35) {
            [self.robot.LEDs setSolidWithBrightness:0.6];
        } else if (time < 11.40) {
            [self.robot.LEDs setSolidWithBrightness:0.8];
        } else if (time < 11.45) {
            [self.robot.LEDs setSolidWithBrightness:1.0];
        } else if (time < 11.60) {
            [self.robot.LEDs setSolidWithBrightness:0.7];
        } else if (time < 11.78) {
            [self.robot.LEDs setSolidWithBrightness:0.5];
        } else if (time < 11.92) {
            [self.robot.LEDs setSolidWithBrightness:0.8];
        } else if (time < 12.05) {
            [self.robot.LEDs setSolidWithBrightness:0.1];
        } else if (time < 12.14) {
            [self.robot.LEDs setSolidWithBrightness:0.04];
        } else if (time < 27.5) {
            [self.robot.LEDs turnOff];
        } else {
            [self.robot.LEDs setSolidWithBrightness:1.0];
        }
        
        if ((23.4 < time && time < 23.48) ||
            (24.64 < time && time < 24.72) ||
            (26.2 < time && time < 26.28)) {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        }
    }
}

- (void)handleThreeFingerTripleTap:(UITapGestureRecognizer *)tap
{
    CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(self.playerViewController.player.currentItem.duration) - 0.02, self.playerViewController.player.currentTime.timescale);
    [self.playerViewController.player seekToTime:time];
    [self cleanupAfterPlaybackFinished];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self startPlayingCutscene];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self.playerViewController.player pause];
}

- (void)boostVolume
{
#if !defined(DEBUG)
    [MPMusicPlayerController applicationMusicPlayer].volume = 1.0;
#endif
    self.boostedVolume = YES;
}

@end
