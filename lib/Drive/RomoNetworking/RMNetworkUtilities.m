//
//  NetworkUtils.m
//  Romo
//

#import "RMNetworkUtilities.h"
#import <SystemConfiguration/CaptiveNetwork.h>

#pragma mark - Constants --

#define HEADER_SIZE sizeof(uint32_t)
#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
//#define IOS_VPN       @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

#pragma mark -
#pragma mark - Implementation (NetworkUtils) --

@implementation RMNetworkUtilities

#pragma mark - Class Methods --

+ (uint32_t)headerSize
{
    return HEADER_SIZE;
}

+ (void)packInteger:(NSUInteger)integer intoBuffer:(uint8_t *)buffer offset:(uint32_t)offset
{    
    buffer[offset++] = (integer >> 24) & 0xFF;
    buffer[offset++] = (integer >> 16) & 0xFF;
    buffer[offset++] = (integer >> 8)  & 0xFF;
    buffer[offset]   = (integer)       & 0xFF;
}

+ (NSString *)WiFiName
{
    NSArray *ifs = (NSArray *)CFBridgingRelease(CNCopySupportedInterfaces());
    id info = nil;
    
    for (NSString *ifnam in ifs) {
        info = (NSDictionary *)CFBridgingRelease(CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam));
        if (info && [info count]){
            break;
        }
    }
    return [info objectForKey:@"SSID"];
}
+ (NSString *)getIPAddress
{
    NSString * address = [RMNetworkUtilities getVPNIPAddress];
    if (address == nil) {
        address = [RMNetworkUtilities getIPAddress:YES];
    }
    return address;
}

+ (NSString *)getVPNIPAddress
{
    NSString *address;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;

    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                NSLog(@"%@",[NSString stringWithUTF8String:temp_addr->ifa_name]);
                // Check if interface is en0 which is the wifi connection on the iPhone
                if(
                   [[NSString stringWithUTF8String:temp_addr->ifa_name] containsString:@"tun"] ||
                   [[NSString stringWithUTF8String:temp_addr->ifa_name] containsString:@"tap"] ||
                   [[NSString stringWithUTF8String:temp_addr->ifa_name] containsString:@"ipsec"] ||
                   [[NSString stringWithUTF8String:temp_addr->ifa_name] containsString:@"ppp"]){
                    // Get NSString from C String
                    struct sockaddr_in *in = (struct sockaddr_in*) temp_addr->ifa_addr;
                    address = [NSString stringWithUTF8String:inet_ntoa((in)->sin_addr)];
                }
            } //else { // IPv6
            //                char addr[INET6_ADDRSTRLEN];
            //                NSLog(@"%@",[NSString stringWithUTF8String:temp_addr->ifa_name]);
            //                // Check if interface is en0 which is the wifi connection on the iPhone
            //                if(
            //                   [[NSString stringWithUTF8String:temp_addr->ifa_name] containsString:@"tun"] ||
            //                   [[NSString stringWithUTF8String:temp_addr->ifa_name] containsString:@"tap"] ||
            //                   [[NSString stringWithUTF8String:temp_addr->ifa_name] containsString:@"ipsec"] ||
            //                   [[NSString stringWithUTF8String:temp_addr->ifa_name] containsString:@"ppp"]){
            //                    struct sockaddr_in6 *in6 = (struct sockaddr_in6*) temp_addr->ifa_addr;
            //                    address = [NSString stringWithUTF8String:inet_ntop(AF_INET6, &in6->sin6_addr, addr, sizeof(addr))];
            //                }
            //            }
            temp_addr = temp_addr->ifa_next;
        }
    }

    // Free memory
    freeifaddrs(interfaces);
    return address;
}

+ (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
                            @[ /*IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6,*/ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
                            @[ /*IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4,*/ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;

    NSDictionary *addresses = [RMNetworkUtilities getIPAddresses];
    NSLog(@"addresses: %@", addresses);

    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
        {
            address = addresses[key];
            if(address) *stop = YES;
        } ];
    return address ? address : @"0.0.0.0";
}

+ (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];

    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}


@end

#pragma mark -
#pragma mark - Implementation (NSData (NetworkUtils)) --

@implementation NSData (NetworkUtils)

#pragma mark - Methods --

- (char *)bytesWithHeader
{
    const NSUInteger size = [self length];
    const void *data = [self bytes];
    
    char *dataWithHeader = malloc(size + HEADER_SIZE);
    
    [RMNetworkUtilities packInteger:size intoBuffer:(uint8_t *)dataWithHeader offset:0];
    memcpy(dataWithHeader + HEADER_SIZE, data, size);
    
    return dataWithHeader;
}

- (NSUInteger)sizeWithHeader
{
    return [self length] + HEADER_SIZE;
}

@end
