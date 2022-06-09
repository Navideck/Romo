//
//  RMBroadcaster.m
//  Romo
//

#import "RMBroadcaster.h"
#import <Romo/UIDevice+UDID.h>
#import "RMPeer.h"
#import "RMAddress.h"

#pragma mark - Broadcaster

@interface RMBroadcaster () {
    BOOL _published;
    __strong NSNetService *_service;
    __strong NSNetService *_webRTCservice;
}

- (id)initWithPort:(NSString *)port;

@end

@implementation RMBroadcaster

#pragma mark - Creation --

+ (RMBroadcaster *)broadcasterWithPort:(NSString *)port;
{
    return [[RMBroadcaster alloc] initWithPort:port];
}

#pragma mark - Initalization -- 

- (id)initWithPort:(NSString *)port
{
    if (self = [super init])
    {
        _published = NO;
        
        NSString *name = [UIDevice currentDevice].UDID;
        
        _service = [[NSNetService alloc] initWithDomain:ROMO_DOMAIN type:ROMO_TYPE name:name port:htons([port intValue])];
        _webRTCservice = [[NSNetService alloc] initWithDomain:ROMO_DOMAIN type:ROMO_RTC_TYPE name:name port:htons([port intValue])];
        
        [_service setDelegate:self];
        [_webRTCservice setDelegate:self];
    }
    
    return self;
}

- (void)dealloc
{
    _service = nil;
    _webRTCservice = nil;
}

#pragma mark - Methods --

- (void)startWithIdentity:(RMPeer *)identity
{
    [self updateIdentity:identity];
    [self broadcastAvailability];
}

- (void)updateIdentity:(RMPeer *)identity
{
    NSData *data = [NSNetService dataFromTXTRecordDictionary:[identity serializeToDictionary]];
    NSData *webRTCData = [NSNetService dataFromTXTRecordDictionary:[identity serializeToDictionary]];
    
    [_service setTXTRecordData:data];
    [_webRTCservice setTXTRecordData:webRTCData];
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    [_delegate broadcastSucceeded];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    [_delegate broadcastFailed];
}

- (void)broadcastAvailability
{
    if (!_published)
    {
        [_service publish];
        [_webRTCservice publish];
        _published = YES;
    }
}

- (void)shutdownBroadcast
{
    if (_published)
    {
        [_service stop];
        [_webRTCservice stop];
        _published = NO;
    }
}

@end
