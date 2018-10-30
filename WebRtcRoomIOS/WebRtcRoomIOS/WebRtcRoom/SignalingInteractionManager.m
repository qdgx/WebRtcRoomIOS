//
//  SignalingInteractionManager.m
//  WebRtcRoomIOS
//
//  Created by wjr on 2018/10/30.
//  Copyright © 2018 wjr. All rights reserved.
//

#import "SignalingInteractionManager.h"
#import <SocketIO/SocketIO-Swift.h>

//https://github.com/socketio/socket.io-client-swift

@interface SignalingInteractionManager() <NSURLSessionDelegate>
@property(nonatomic,strong) SocketManager* socketManager;
@property(nonatomic,strong) SocketIOClient* socketClient;
@end

@implementation SignalingInteractionManager
-(instancetype)init
{
    self = [super init];
    if (self)
    {
        NSURL* url = [[NSURL alloc] initWithString:@"https://172.16.70.248:8443"];
        //NSURL* url = [[NSURL alloc] initWithString:@"https://172.16.70.226:8443"];
        SSLSecurity* sec = [[SSLSecurity alloc] initWithUsePublicKeys:YES];
        self.socketManager = [[SocketManager alloc] initWithSocketURL:url config:@{@"log": @NO, @"compress": @YES,@"security":sec,@"secure":@(YES),@"sessionDelegate":self}];
        self.socketClient = self.socketManager.defaultSocket;
        
        __weak typeof(self) weakSelf = self;
        [self.socketClient on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack)
        {
            LOGINFO(@"服务器连接成功");
        }];
        [self.socketClient on:@"created" callback:^(NSArray* data, SocketAckEmitter* ack)
        {
            if (weakSelf.dataBlock) {
                weakSelf.dataBlock(@"created",[data objectAtIndex:0]);
            }
        }];
        [self.socketClient on:@"joined" callback:^(NSArray* data, SocketAckEmitter* ack)
        {
            if (weakSelf.dataBlock) {
                weakSelf.dataBlock(@"joined",[data objectAtIndex:0]);
            }
        }];
        [self.socketClient on:@"offer" callback:^(NSArray* data, SocketAckEmitter* ack)
        {
            if (weakSelf.dataBlock) {
                weakSelf.dataBlock(@"offer",[data objectAtIndex:0]);
            }
        }];
        [self.socketClient on:@"answer" callback:^(NSArray* data, SocketAckEmitter* ack)
        {
            if (weakSelf.dataBlock) {
                weakSelf.dataBlock(@"answer",[data objectAtIndex:0]);
            }
        }];
        [self.socketClient on:@"candidate" callback:^(NSArray* data, SocketAckEmitter* ack)
        {
            if (weakSelf.dataBlock) {
                weakSelf.dataBlock(@"candidate",[data objectAtIndex:0]);
            }
        }];
        [self.socketClient on:@"exit" callback:^(NSArray* data, SocketAckEmitter* ack)
         {
             if (weakSelf.dataBlock) {
                 weakSelf.dataBlock(@"exit",[data objectAtIndex:0]);
             }
        }];
        [self.socketClient connect];
    }
    return self;
}

+(SignalingInteractionManager*)getInstance
{
    static SignalingInteractionManager* getInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        getInstance = [[SignalingInteractionManager alloc] init];
    });
    return getInstance;
}

-(void)createAndJoinRoom:(NSString*)roomid
{
    [self.socketClient emit:@"createAndJoinRoom" with:@[@{@"room":roomid}]];
}
-(void)offer:(NSString*)from to:(NSString*)to room:(NSString*)room sdp:(NSString*)sdp
{
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setObject:from forKey:@"from"];
    [dic setObject:to forKey:@"to"];
    [dic setObject:sdp forKey:@"sdp"];
    [dic setObject:room forKey:@"room"];
    [self.socketClient emit:@"offer" with:@[dic]];
}
-(void)answer:(NSString*)from to:(NSString*)to room:(NSString*)room sdp:(NSString*)sdp
{
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setObject:from forKey:@"from"];
    [dic setObject:to forKey:@"to"];
    [dic setObject:sdp forKey:@"sdp"];
    [dic setObject:room forKey:@"room"];
    [self.socketClient emit:@"answer" with:@[dic]];
}

-(void)candidate:(NSString*)from to:(NSString*)to room:(NSString*)room sdp:(NSString*)sdp sdpMLineIndex:(int)sdpMLineIndex sdpMid:(NSString*)sdpMid
{
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setObject:from forKey:@"from"];
    [dic setObject:to forKey:@"to"];
    [dic setObject:room forKey:@"room"];
    
    NSMutableDictionary* candidate = [[NSMutableDictionary alloc] init];
    [candidate setObject:sdp forKey:@"sdp"];
    [candidate setObject:@(sdpMLineIndex) forKey:@"sdpMLineIndex"];
    [candidate setObject:sdpMid forKey:@"sdpMid"];
    [dic setObject:candidate forKey:@"candidate"];
    [self.socketClient emit:@"candidate" with:@[dic]];
}

-(void)exit:(NSString*)from room:(NSString*)room
{
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setObject:from forKey:@"from"];
    [dic setObject:room forKey:@"room"];
    [self.socketClient emit:@"exit" with:@[dic]];
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    if(challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust)
    {
        // 告诉服务器，客户端信任证书
        // 创建凭据对象
        NSURLCredential *credntial = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // 通过completionHandler告诉服务器信任证书
        completionHandler(NSURLSessionAuthChallengeUseCredential,credntial);
    }
}
@end
