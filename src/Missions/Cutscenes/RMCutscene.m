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
@property (nonatomic, strong) AVPlayerViewController *playerViewController API_AVAILABLE(ios(8.0));
@property (nonatomic, strong) MPMoviePlayerController *player;

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
    if (@available(iOS 8.0, *)) {
        self.playerViewController = [AVPlayerViewController new];

        self.playerViewController.player = player;
        self.playerViewController.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.playerViewController.showsPlaybackControls = false;
        [self.playerViewController.player addObserver:self forKeyPath:@"rate" options:0 context:nil];
    } else {
        self.player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:cutscenePath]];
        [self.player prepareToPlay];
        self.player.controlStyle = MPMovieControlStyleNone;
        self.player.scalingMode = MPMovieScalingModeAspectFill;
        self.player.shouldAutoplay = NO;
    }
    
    self.view.frame = view.bounds;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.accessibilityLabel = @"Cutscene";
    self.view.isAccessibilityElement = YES;
    [view addSubview:self.view];

    // trick to prevent iOS from showing the volume alert bezel
    self.volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0, 0, -1000, -1000)];
    self.volumeView.clipsToBounds = YES;
    [view addSubview:self.volumeView];

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
    view.userInteractionEnabled = NO;
    
#endif  // DEBUG
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    if (@available(iOS 8.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerViewController.player.currentItem];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateDidChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    }

    self.boostedVolume = NO;
    
    self.cutsceneNumber = cutscene;
    self.completion = completion;
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [self startPlayingCutscene];
    }
}

- (UIView *)view
{
    if (@available(iOS 8.0, *)) {
        return self.playerViewController.view;
    } else {
        return self.player.view;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods

- (void)playbackDidFinish:(NSNotification *)notification
{
    if (@available(iOS 8.0, *)) {
        AVPlayerItem  *currentItem = notification.object;

        if (CMTimeGetSeconds(currentItem.duration) > 0 && ABS(CMTimeGetSeconds(currentItem.currentTime) - CMTimeGetSeconds(currentItem.duration)) < 0.06) {
            [self cleanupAfterPlaybackFinished];
        }
    } else {
        MPMoviePlayerController *player = notification.object;
        if (player.playableDuration > 0.0 && ABS(player.currentPlaybackTime - player.playableDuration) < 0.06) {
            [self cleanupAfterPlaybackFinished];
        }
    }
}

- (void)startPlayingCutscene
{
    if (!self.playbackTimer) {
        self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(playbackTimeDidChange:) userInfo:nil repeats:YES];
    }
    if (@available(iOS 8.0, *)) {
        [self.playerViewController.player play];
    } else {
        [self.player play];
    }
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
    
    if (@available(iOS 8.0, *)) {
        if (self.playerViewController) {
            [self.view removeFromSuperview];
            self.playerViewController = nil;
        }
    } else {
        if (self.player) {
            [self.view removeFromSuperview];
            self.player = nil;
        }
    }
    
    if (self.completion) {
        __strong RMCutscene *strongSelf = self;
        self.completion(YES);
        self.completion = nil;
        strongSelf = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (@available(iOS 8.0, *)) {
        [self.playerViewController.player removeObserver:self forKeyPath:@"rate"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"rate"]) {
        if (@available(iOS 8.0, *)) {
            float time = CMTimeGetSeconds(self.playerViewController.player.currentItem.currentTime) - CMTimeGetSeconds(self.playerViewController.player.currentItem.duration);
            
            if ((self.playerViewController.player.rate == 0) && ABS(time) > 0.05) {
                [self.playerViewController.player play];
            }
        }
    }
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    MPMoviePlayerController *player = notification.object;

    if ((player.playbackState == MPMoviePlaybackStateInterrupted ||
         player.playbackState == MPMoviePlaybackStatePaused ||
         player.playbackState == MPMoviePlaybackStateStopped) &&
        ABS(player.currentPlaybackTime - player.playableDuration) > 0.05) {
        [player play];
    }
}

- (void)playbackTimeDidChange:(NSTimer *)playbackTimer
{
    float time;

    if (@available(iOS 8.0, *)) {
        time = CMTimeGetSeconds(self.playerViewController.player.currentTime);
    } else {
        time = self.player.currentPlaybackTime;
    }

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
    if (@available(iOS 8.0, *)) {
        CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(self.playerViewController.player.currentItem.duration) - 0.02, self.playerViewController.player.currentTime.timescale);
        [self.playerViewController.player seekToTime:time];
    } else {
        self.player.currentPlaybackTime = self.player.playableDuration - 0.02;
    }
    [self cleanupAfterPlaybackFinished];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self startPlayingCutscene];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    if (@available(iOS 8.0, *)) {
        [self.playerViewController.player pause];
    } else {
        [self.player stop];
    }
}

- (void)boostVolume
{
#if !defined(DEBUG)
    [MPMusicPlayerController applicationMusicPlayer].volume = 1.0;
#endif
    self.boostedVolume = YES;
}

@end
