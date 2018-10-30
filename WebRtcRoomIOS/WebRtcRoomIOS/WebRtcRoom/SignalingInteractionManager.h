//
//  SignalingInteractionManager.h
//  WebRtcRoomIOS
//
//  Created by wjr on 2018/10/30.
//  Copyright © 2018 wjr. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LOGINFO(fmt, ...) NSLog((@"%s [No.%d]\r\n" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

typedef void (^SignalingInteractionCallBack)(NSString* eventName,NSDictionary* data);

//信令交互管理

NS_ASSUME_NONNULL_BEGIN

@interface SignalingInteractionManager : NSObject
@property(nonatomic,strong) SignalingInteractionCallBack dataBlock;
+(SignalingInteractionManager*)getInstance;
-(void)createAndJoinRoom:(NSString*)roomid;
-(void)offer:(NSString*)from to:(NSString*)to room:(NSString*)room sdp:(NSString*)sdp;
-(void)answer:(NSString*)from to:(NSString*)to room:(NSString*)room sdp:(NSString*)sdp;
-(void)candidate:(NSString*)from to:(NSString*)to room:(NSString*)room sdp:(NSString*)sdp sdpMLineIndex:(int)sdpMLineIndex sdpMid:(NSString*)sdpMid;
-(void)exit:(NSString*)from room:(NSString*)room;
@end

NS_ASSUME_NONNULL_END
