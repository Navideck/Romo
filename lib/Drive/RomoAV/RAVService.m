//
//  AVService.m
//  RomoLibrary
//
//

#import "RAVService.h"
#import "RAVSubscriber.h"
#import "RMDataPacket.h"
#import <Romo/UIDevice+Romo.h>

#define SERVICE_NAME        @"AVService"
#define SERVICE_PORT        @"21345"
#define SERVICE_PROTOCOL    PROTOCOL_UDP

@interface RAVService ()

@property (nonatomic, strong) RMDataSocket *socket;
@property (nonatomic, strong) RMAddress *peerAddress;
@property (nonatomic, strong) RAVHWVideoOutput *hwVideoOutput;
#ifndef ROMO_CONTROL
@property (nonatomic, strong) RAVVideoOutput *videoOutput;
#endif

- (void)prepareNetworking;
- (void)prepareVideo;

- (void)sendDeviceInfo;

@end

@implementation RAVService

@synthesize socket=_socket, peerAddress=_peerAddress;

+ (RAVService *)service
{
    return [[RAVService alloc] init];
}

- (id)init
{
    self = [super initWithName:SERVICE_NAME port:SERVICE_PORT protocol:SERVICE_PROTOCOL];
    if (self) {
        [self prepareNetworking];
        [self prepareVideo];
    }
    return self;
}

- (void)dealloc
{
    [self stop];
    if (@available(iOS 8.0, *)) {
        [self.hwVideoOutput stop];
    }
#ifndef ROMO_CONTROL
    else {
        [self.videoOutput stop];
    }
#endif
}

- (void)prepareNetworking
{
    _socket = [[RMDataSocket alloc] initDatagramListenerWithPort:SERVICE_PORT];
    _socket.delegate = self;
}

- (void)prepareVideo
{
    if (@available(iOS 8.0, *)) {
        self.hwVideoOutput = [[RAVHWVideoOutput alloc] init];
    }
#ifndef ROMO_CONTROL
    else {
        self.videoOutput = [[RAVVideoOutput alloc] init];
    }
#endif
}

#pragma mark - Service --

- (RMSubscriber *)subscribe
{
    return [RAVSubscriber subscriberWithService:self];
}

- (void)start
{

}

- (void)stop
{
    if (_socket) {
        RMDataSocket *socket = _socket;
        _socket = nil;
        [socket shutdown];
    }
}

- (void)dataSocket:(RMDataSocket *)socket receivedDataPacket:(RMDataPacket *)dataPacket
{
    switch (dataPacket.type) {
        case DATA_TYPE_OTHER: {
            _peerAddress = [RMAddress addressWithHost:dataPacket.source.host port:SERVICE_PORT];
            [self sendDeviceInfo];
            break;
        }

        case DATA_TYPE_VIDEO: {
            if (@available(iOS 8.0, *)) {
                [self.hwVideoOutput playVideoFrame:[dataPacket extractData] length:dataPacket.dataSize];
            }
#ifndef ROMO_CONTROL
            else {
                [self.videoOutput playVideoFrame:[dataPacket extractData] length:dataPacket.dataSize];
            }
#endif
            break;
        }
        default:
            break;
    }
}

- (void)dataSocketClosed:(RMDataSocket *)dataSocket
{
    [self stop];   
}

- (void)dataSocketConnectionFailed:(RMDataSocket *)dataSocket
{
    [self stop];
}

- (UIView *)peerView
{
    if (@available(iOS 8.0, *)) {
        return self.hwVideoOutput.peerView;
    }
#ifndef ROMO_CONTROL
    else {
        return self.videoOutput.peerView;
    }
#endif
}

- (void)sendDeviceInfo
{
    NSString *deviceType = [[UIDevice currentDevice] modelIdentifier];
    
    // Send the device name, then "##"
    // this is very hacky but needed for legacy support
    // v2.0.1 of the app doesn't check for app version compatability, so we see if the device appended a "##".
    //     if not, we know it must have been 2.0.1.
    NSString *deviceInfo = [NSString stringWithFormat:@"%@##",deviceType];
    
    char deviceCString[deviceInfo.length + 1];
    [deviceInfo getCString:deviceCString maxLength:deviceInfo.length + 1 encoding:NSUTF8StringEncoding];
    RMDataPacket *deviceInfoPacket = [[RMDataPacket alloc] initWithType:DATA_TYPE_OTHER data:deviceCString dataSize:(uint32_t)deviceInfo.length + 1 destination:_peerAddress];
    [_socket sendDataPacket:deviceInfoPacket];
}
@end
