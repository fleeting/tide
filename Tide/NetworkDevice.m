//
//  NetworkDevice.m
//  Tide
//
//  Created by Joe Rickerby on 22/03/2015.
//  Copyright (c) 2015 Tingbot. All rights reserved.
//

#import "NetworkDevice.h"

@implementation NetworkDevice

- (instancetype)initWithHostname:(NSString *)hostname
{
    self = [super init];
    
    if (self) {
        _hostname = hostname;
    }
    
    return self;
}

+ (BOOL)canInstall
{
    return YES;
}

- (NSFileHandle *)run:(NSString *)path error:(NSError **)error
{
    NSTask *task = [NSTask new];
    
    task.launchPath = [[NSBundle mainBundle] pathForResource:@"tbtool" ofType:@""];
    task.arguments = @[ @"run", path, _hostname ];
    NSPipe *taskStdout = task.standardOutput = [NSPipe pipe];
    
    [task launch];
    
    return [taskStdout fileHandleForReading];
}

- (void)install:(NSString *)path
{
    NSTask *task = [NSTask new];
    
    task.launchPath = [[NSBundle mainBundle] pathForResource:@"tbtool" ofType:@""];
    task.arguments = @[ @"install", path, _hostname ];
    
    [task launch];
}

- (NSString *)name
{
    return _hostname;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[NetworkDevice class]]) {
        return NO;
    }
    
    return [self isEqualToNetworkDevice:object];
}

- (BOOL)isEqualToNetworkDevice:(NetworkDevice *)object
{
    return [self.hostname isEqualToString:object.hostname];
}



@end
