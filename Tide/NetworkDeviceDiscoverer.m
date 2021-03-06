//
//  NetworkDeviceDiscoverer.m
//  Tide
//
//  Created by Joe Rickerby on 11/04/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import "NetworkDeviceDiscoverer.h"

#import <sys/socket.h>
#include <arpa/inet.h>

#import "NetworkDevice.h"

@interface NetworkDeviceDiscoverer () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
{
    NSNetServiceBrowser *_browser;
    
    NSSet *_newDevices;
    
    NSMutableSet *_resolvingServices;
}

@end

@implementation NetworkDeviceDiscoverer

+ (instancetype)sharedInstance
{
    static id result;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = [[self alloc] init];
    });
    
    return result;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _browser = [[NSNetServiceBrowser alloc] init];
        _browser.delegate = self;
        [_browser searchForServicesOfType:@"_tingbot-ssh._tcp" inDomain:@""];
//        [_browser searchForServicesOfType:@"_afpovertcp._tcp." inDomain:@""];
        self.devices = [NSSet set];
        _resolvingServices = [NSMutableSet set];
    }
    
    return self;
}

- (void)dealloc
{
    _browser.delegate = nil;
}

#pragma mark NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog(@"%s", __func__);
    
    if (!_newDevices) {
        _newDevices = [NSSet set];
    }
    
    NSString *ipAddress = nil;
    
    for (NSData *sockAddrData in sender.addresses) {
        const struct sockaddr *addr = sockAddrData.bytes;
        
        // only accept IPv4 addresses
        if (addr->sa_family == AF_INET) {
            char *ipChars = inet_ntoa(((struct sockaddr_in *)addr)->sin_addr);
            ipAddress = [NSString stringWithUTF8String:ipChars];
        }
    }
    
    if (!ipAddress) {
        NSLog(@"No IPv4 address found for host %@", sender.hostName);
        return;
    }

    NetworkDevice *device = [[NetworkDevice alloc] initWithHostname:ipAddress];
    
    _newDevices = [_newDevices setByAddingObject:device];
    // add to current devices as well so it can be used straight away
    self.devices = [self.devices setByAddingObject:device];
    
    [_resolvingServices removeObject:sender];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog(@"%s", __func__);
    
    [_resolvingServices removeObject:sender];
}

#pragma mark NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser
           didFindService:(NSNetService *)aNetService
               moreComing:(BOOL)moreComing
{
    NSLog(@"%s", __func__);
    
    aNetService.delegate = self;
    [aNetService scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [aNetService resolveWithTimeout:20];
    [_resolvingServices addObject:aNetService];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeOldDevices) object:nil];

    if (!moreComing) {
        [self performSelector:@selector(removeOldDevices) withObject:nil afterDelay:20];
    }
}

#pragma mark Private

- (void)removeOldDevices
{
    if (_newDevices) {
        self.devices = _newDevices;
        _newDevices = nil;
    }
}

@end
