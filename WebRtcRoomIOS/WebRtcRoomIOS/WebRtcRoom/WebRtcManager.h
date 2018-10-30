//
//  WebRtcManager.h
//  WebRtcRoomIOS
//
//  Created by wjr on 2018/10/30.
//  Copyright © 2018 wjr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCPeerConnection.h>
#import <WebRTC/RTCMediaConstraints.h>
#import <WebRTC/RTCVideoCapturer.h>
#import <WebRTC/RTCVideoTrack.h>
#import <WebRTC/RTCEAGLVideoView.h>
#import <WebRTC/RTCIceServer.h>
#import <WebRTC/RTCIceCandidate.h>
#import <WebRTC/RTCConfiguration.h>
#import <WebRTC/RTCMediaStream.h>
#import <WebRTC/RTCDataChannel.h>
#import <WebRTC/RTCDataChannelConfiguration.h>
#import <WebRTC/RTCSessionDescription.h>
#import <WebRTC/RTCVideoSource.h>
#import <WebRTC/RTCCameraVideoCapturer.h>
#import "SignalingInteractionManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,PeerConnectionType)
{
    //发送者
    PeerConnectionType_Caller,
    //被发送
    PeerConnectionType_Callee,
    
};

@protocol WebRtcManagerDelegate <NSObject>
@optional
-(void)rtcSetLocalStream:(RTCMediaStream*)stream;
-(void)rtcSetRemoteStream:(RTCMediaStream*)stream;
-(void)rtcRemoveStream:(RTCMediaStream*)stream;
@end

@interface WebRtcPeerConnectionInfo : NSObject
@property(nonatomic,strong,nullable) RTCPeerConnection* peerConnection;
@property(nonatomic,strong) NSString* userID;
@property(nonatomic,strong,nullable) RTCMediaStream* remoteStream;
@property(nonatomic,strong,nullable) RTCDataChannel* localDataChannel;
@property(nonatomic,strong,nullable) RTCDataChannel* remoteDataChannel;
@property(nonatomic,assign) PeerConnectionType peerType;
@end

@interface WebRtcManager : NSObject
+(WebRtcManager*)getInstance;
@property(nonatomic,weak) id<WebRtcManagerDelegate> delegate;
//用户自己的userid
@property(nonatomic,strong) NSString* userid;
//用户自己的roomid
@property(nonatomic,strong) NSString* roomid;
-(void)connectWithUserId:(NSString *)userId;
-(void)answer:(NSString*)from to:(NSString*)to room:(NSString*)room sdp:(NSString*)sdp;
-(void)candidate:(NSString*)from to:(NSString*)to room:(NSString*)room sdp:(NSString*)sdp sdpMLineIndex:(int)sdpMLineIndex sdpMid:(NSString*)sdpMid;
-(void)close;
@end

NS_ASSUME_NONNULL_END
