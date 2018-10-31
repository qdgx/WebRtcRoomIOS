//
//  WebRtcManager.m
//  WebRtcRoomIOS
//
//  Created by wjr on 2018/10/30.
//  Copyright © 2018 wjr. All rights reserved.
//

#import "WebRtcManager.h"
#import "SignalingInteractionManager.h"

//google提供的
//static NSString *const RTCSTUNServerURL = @"stun:stun.l.google.com:19302";
static NSString *const RTCSTUNServerURL = @"stun:stun.xten.com";
static NSString *const RTCSTUNServerURL2 = @"stun:23.21.150.121";
static NSString *const RTCSTUNServerURL3 = @"stun:stun.l.google.com:19302";

@interface WebRtcManager() <RTCPeerConnectionDelegate,RTCDataChannelDelegate>
@property(nonatomic,strong) NSMutableArray* users;
@property(nonatomic,strong) RTCPeerConnectionFactory*  peerConnectionFactory;
@property(nonatomic,strong) NSMutableArray* iceServers;
@property(nonatomic,strong) RTCMediaStream* localStream;
@property(nonatomic,strong) RTCCameraVideoCapturer* capturer;
@property(nonatomic,assign) BOOL isCameraOpened;
@property(nonatomic,strong) RTCAudioTrack* localAudioTrack;
@property(nonatomic,strong) RTCVideoTrack* localVideoTrack;
@property(nonatomic,assign) BOOL isFrontCamera;

@end

@implementation WebRtcPeerConnectionInfo

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.userID = @"";
        self.peerType = PeerConnectionType_Caller;
    }
    return self;
}
@end

@implementation WebRtcManager
-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.users = [[NSMutableArray alloc] init];
        self.peerConnectionFactory = nil;
        self.iceServers = nil;
        self.isCameraOpened = NO;
        self.isFrontCamera = YES;
    }
    return self;
}
+(WebRtcManager*)getInstance
{
    static WebRtcManager* getInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        getInstance = [[WebRtcManager alloc] init];
    });
    return getInstance;
}

//创建点对点通信
-(void)connectWithUserId:(NSString *)userId
{
    WebRtcPeerConnectionInfo* userInfo = [[WebRtcPeerConnectionInfo alloc] init];
    userInfo.peerType = PeerConnectionType_Caller;
    userInfo.userID = userId;
    userInfo.peerConnection = [self createPeerConnection:userId];
    [self.users addObject:userInfo];
    [self initLocalStream];
    [userInfo.peerConnection addStream:self.localStream];
    [self createDataChannel:userInfo];
    [self createOffer:userInfo];
}
/**
 *  关闭peerConnection
 *
 */
- (void)closePeerConnection:(WebRtcPeerConnectionInfo*)info
{
    for (int i = 0; i < self.users.count; i++)
    {
        WebRtcPeerConnectionInfo* user = [self.users objectAtIndex:i];
        if ([user.userID isEqualToString:info.userID])
        {
            [self.users removeObjectAtIndex:i];
            break;
        }
    }
    
    if (info.peerConnection != nil)
        [info.peerConnection close];
    
    info.remoteStream = nil;
    info.localDataChannel = nil;
    info.remoteDataChannel = nil;
    info.peerConnection = nil;
 
}

-(void)answer:(NSString*)from to:(NSString*)to room:(NSString*)room sdp:(NSString*)sdp
{
    WebRtcPeerConnectionInfo* user = [self findUserById:from];
    if (user == nil)
    {
        LOGINFO(@"找不到用户");
        return;
    }
    
    RTCSessionDescription *remoteSdp = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeAnswer sdp:sdp];
    __weak RTCPeerConnection *peerConnection = user.peerConnection;
    __weak typeof(self) weakSelf = self;
    [peerConnection setRemoteDescription:remoteSdp completionHandler:^(NSError * _Nullable error) {
        [weakSelf setSessionDescriptionWithPeerConnection:peerConnection];
    }];
}

-(void)candidate:(NSString*)from to:(NSString*)to room:(NSString*)room sdp:(NSString*)sdp sdpMLineIndex:(int)sdpMLineIndex sdpMid:(NSString*)sdpMid
{
    WebRtcPeerConnectionInfo* user = [self findUserById:from];
    if (user == nil)
    {
        LOGINFO(@"找不到用户");
        return;
    }
    
    RTCIceCandidate* rtccandidate = [[RTCIceCandidate alloc] initWithSdp:sdp sdpMLineIndex:sdpMLineIndex sdpMid:sdpMid];
    //添加到点对点连接中
    [user.peerConnection addIceCandidate:rtccandidate];
}

-(void)joined:(NSString*)idString room:(NSString*)room
{
    //[self connectWithUserId:idString];
}
-(void)offer:(NSString*)from to:(NSString*)to room:(NSString*)room sdp:(NSString*)sdp
{
    WebRtcPeerConnectionInfo* user = [self findUserById:from];
    if (user != nil)
    {
        LOGINFO(@"找不到用户");
        return;
    }
    
    //根据类型和SDP 生成SDP描述对象
    WebRtcPeerConnectionInfo* userInfo = [[WebRtcPeerConnectionInfo alloc] init];
    userInfo.peerType = PeerConnectionType_Callee;
    userInfo.userID = from;
    userInfo.peerConnection = [self createPeerConnection:from];
    [self.users addObject:userInfo];
    [self initLocalStream];
    [userInfo.peerConnection addStream:self.localStream];
    [self createDataChannel:userInfo];
    
    RTCSessionDescription* remoteSdp = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeOffer sdp:sdp];
    
    __weak RTCPeerConnection *peerConnection = userInfo.peerConnection;
    __weak typeof(self) weakSelf = self;
    [peerConnection setRemoteDescription:remoteSdp completionHandler:^(NSError * _Nullable error)
    {
        [weakSelf setSessionDescriptionWithPeerConnection:peerConnection];
    }];
}


- (RTCPeerConnection*)createPeerConnection:(NSString *)connectionId
{
    //如果点对点工厂为空
    if (!self.peerConnectionFactory)
    {
        //先初始化工厂
        self.peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
    }
    
    //得到ICEServer
    if (!self.iceServers)
    {
        self.iceServers = [NSMutableArray array];
        [self.iceServers addObject:[self defaultSTUNServer]];
    }
    
    //用工厂来创建连接
    RTCConfiguration *configuration = [[RTCConfiguration alloc] init];
    configuration.iceServers = self.iceServers;
    RTCPeerConnection *connection = [self.peerConnectionFactory peerConnectionWithConfiguration:configuration constraints:[self creatPeerConnectionConstraint] delegate:self];
    
    return connection;
}
- (RTCIceServer *)defaultSTUNServer{
    return [[RTCIceServer alloc] initWithURLStrings:@[RTCSTUNServerURL,RTCSTUNServerURL2]];
}
- (RTCMediaConstraints *)creatPeerConnectionConstraint
{
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@{kRTCMediaConstraintsOfferToReceiveAudio:kRTCMediaConstraintsValueTrue,kRTCMediaConstraintsOfferToReceiveVideo:kRTCMediaConstraintsValueTrue} optionalConstraints:nil];
    return constraints;
}

-(BOOL)isOpenCamera
{
    return self.isCameraOpened;
}
-(void)openCamera
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.localStream == nil)
        {
            [weakSelf initLocalStream];
            [weakSelf openCamera:self.isFrontCamera];
        }
        else
        {
            //视频
            if (!weakSelf.isCameraOpened)
            {
                [weakSelf openCamera:self.isFrontCamera];
            }
        }
        if ([weakSelf.delegate respondsToSelector:@selector(rtcSetLocalStream:)])
        {
            LOGINFO(@"本地视频Stream");
            [weakSelf.delegate rtcSetLocalStream:weakSelf.localStream];
        }
    });
    
    
}
-(void)closeCamra
{
    if(self.capturer != nil)
    {
        [self.capturer stopCapture];
    }
    self.isCameraOpened = NO;
    if (self.localStream != nil)
    {
        if ([self.delegate respondsToSelector:@selector(rtcRemoveStream:)])
        {
            [self.delegate rtcRemoveStream:self.localStream];
        }
    }
}

-(void)openCamera:(BOOL)isFront
{
    if (isFront)
    {
        [self switchFrontCamera];
    }
    else
    {
        [self switchBackCamera];
    }
}

-(void)switchFrontCamera
{
    if (self.localStream == nil)
        return;
    
    self.isFrontCamera = YES;
    NSArray *deviceArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = nil;
    for (AVCaptureDevice* dev in deviceArray )
    {
        if (dev.position == AVCaptureDevicePositionFront)
        {
            device = dev;
            break;
        }
    }
    AVCaptureDeviceFormat* format = device.activeFormat;
    [self.capturer stopCapture];
    [self.capturer startCaptureWithDevice:device format:format fps:30 completionHandler:^(NSError * _Nonnull error)
    {
        if (!error)
        {
            self.isCameraOpened = YES;
        }
    }];
}
-(void)switchBackCamera
{
    if (self.localStream == nil)
        return;
    
    self.isFrontCamera = NO;
    NSArray *deviceArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = nil;
    for (AVCaptureDevice* dev in deviceArray )
    {
        if (dev.position == AVCaptureDevicePositionBack)
        {
            device = dev;
            break;
        }
    }
    AVCaptureDeviceFormat* format = device.activeFormat;
    [self.capturer stopCapture];
    [self.capturer startCaptureWithDevice:device format:format fps:30 completionHandler:^(NSError * _Nonnull error)
    {
        if (!error)
        {
            self.isCameraOpened = YES;
        }
    }];
}

-(void)initLocalStream
{
    if (self.localStream != nil)
        return;
    
   
    //先初始化工厂
    if (!self.peerConnectionFactory)
        self.peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
    
    __weak typeof(self) weakSelf = self;
    self.localStream = [self.peerConnectionFactory mediaStreamWithStreamId:@"ARDAMS"];
    
    //音频
    self.localAudioTrack = [self.peerConnectionFactory audioTrackWithTrackId:@"ARDAMSa0"];
    [self.localStream addAudioTrack:self.localAudioTrack];
    
    //视频
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)
    {
        NSLog(@"相机访问受限");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"相机访问受限" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
    }
    else
    {
        RTCVideoSource *videoSource =  [self.peerConnectionFactory videoSource];
        [videoSource adaptOutputFormatToWidth:205 height:205 fps:30];
        self.capturer = [[RTCCameraVideoCapturer alloc] initWithDelegate:videoSource];
        self.localVideoTrack = [self.peerConnectionFactory videoTrackWithSource:videoSource trackId:@"ARDAMSv0"];
        [self.localStream addVideoTrack:self.localVideoTrack];
    }
}

- (void)createDataChannel:(WebRtcPeerConnectionInfo*)userInfo
{
    //给点对点连接，创建dataChannel
    
    RTCDataChannelConfiguration *dataChannelConfiguration = [[RTCDataChannelConfiguration alloc] init];
    dataChannelConfiguration.isOrdered = YES;
    userInfo.localDataChannel = [userInfo.peerConnection dataChannelForLabel:@"testDataChannel" configuration:dataChannelConfiguration];
    userInfo.localDataChannel.delegate = self;
}
/**
 *  为所有连接创建offer
 */
- (void)createOffer:(WebRtcPeerConnectionInfo*)userInfo
{
    //给每一个点对点连接，都去创建offer
    [userInfo.peerConnection offerForConstraints:[self creatAnswerOrOfferConstraint] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        __weak RTCPeerConnection *peerConnection = userInfo.peerConnection;
        [userInfo.peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
            [self setSessionDescriptionWithPeerConnection:peerConnection];
        }];
    }];
}
/**
 *  设置offer/answer的约束
 */
- (RTCMediaConstraints *)creatAnswerOrOfferConstraint
{
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@{kRTCMediaConstraintsOfferToReceiveAudio:kRTCMediaConstraintsValueTrue,kRTCMediaConstraintsOfferToReceiveVideo:kRTCMediaConstraintsValueTrue} optionalConstraints:nil];
    return constraints;
}

-(void)close
{
    [self.capturer stopCapture];
    self.capturer = nil;
    self.localStream = nil;
    for (int i = 0; i < self.users.count; i++)
    {
        WebRtcPeerConnectionInfo* info = [self.users objectAtIndex:i];
        if (info.peerConnection != nil)
            [info.peerConnection close];
        info.remoteStream = nil;
        info.localDataChannel = nil;
        info.remoteDataChannel = nil;
        info.peerConnection = nil;
    }
    [self.users removeAllObjects];
}

// Called when setting a local or remote description.
//当一个远程或者本地的SDP被设置就会调用
- (void)setSessionDescriptionWithPeerConnection:(RTCPeerConnection *)peerConnection
{
    WebRtcPeerConnectionInfo* user = [self findUser:peerConnection];
    if (user == nil)
    {
        LOGINFO(@"找不到用户");
        return;
    }
    
    //判断，当前连接状态为，收到了远程点发来的offer，这个是进入房间的时候，尚且没人，来人就调到这里
    if (peerConnection.signalingState == RTCSignalingStateHaveRemoteOffer)
    {
        //创建一个answer,会把自己的SDP信息返回出去
        [peerConnection answerForConstraints:[self creatAnswerOrOfferConstraint] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
            __weak RTCPeerConnection *obj = peerConnection;
            [peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                [self setSessionDescriptionWithPeerConnection:obj];
            }];
        }];
    }
    //判断连接状态为本地发送offer
    else if (peerConnection.signalingState == RTCSignalingStateHaveLocalOffer)
    {
        if (user.peerType == PeerConnectionType_Callee)
        {
            LOGINFO(@"发送answer消息");
            [[SignalingInteractionManager getInstance] answer:self.userid to:user.userID room:self.roomid sdp:user.peerConnection.localDescription.sdp];
        }
        else if(user.peerType == PeerConnectionType_Caller)
        {
            LOGINFO(@"发送Offer消息");
            [[SignalingInteractionManager getInstance] offer:self.userid to:user.userID room:self.roomid sdp:user.peerConnection.localDescription.sdp];
        }
    }
    else if (peerConnection.signalingState == RTCSignalingStateStable)
    {
        if (user.peerType == PeerConnectionType_Callee)
        {
            LOGINFO(@"发送answer消息");
            [[SignalingInteractionManager getInstance] answer:self.userid to:user.userID room:self.roomid sdp:user.peerConnection.localDescription.sdp];
        }
    }
    
}

#pragma mark - 查找用户
-(WebRtcPeerConnectionInfo*)findUserById:(NSString*)userid
{
    for (int i = 0; i < self.users.count; i++)
    {
        WebRtcPeerConnectionInfo* info = [self.users objectAtIndex:i];
        if ([info.userID isEqualToString:userid])
        {
            return info;
        }
    }
    return nil;
}

-(WebRtcPeerConnectionInfo*)findUser:(RTCPeerConnection*)peerConnection
{
    for (int i = 0; i < self.users.count; i++)
    {
        WebRtcPeerConnectionInfo* info = [self.users objectAtIndex:i];
        if (info.peerConnection == peerConnection)
        {
            return info;
        }
    }
    return nil;
}

#pragma mark - RTC回调
// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged
{
    
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream
{
    WebRtcPeerConnectionInfo* user = [self findUser:peerConnection];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(rtcSetLocalStream:)])
        {
            LOGINFO(@"本地视频Stream");
            [self.delegate rtcSetLocalStream:self.localStream];
        }
        if ([self.delegate respondsToSelector:@selector(rtcSetRemoteStream:)])
        {
            LOGINFO(@"远程视频Stream");
            if (user != nil)
            {
                user.remoteStream = stream;
            }
            [self.delegate rtcSetRemoteStream:stream];
        }
    });
}

/** Called when a remote peer closes a stream. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       didRemoveStream:(RTCMediaStream *)stream
{
    
}
/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection
{
   
}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState
{

    //断开peerconection
    if (newState == RTCIceConnectionStateDisconnected)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            WebRtcPeerConnectionInfo* user = [self findUser:peerConnection];
            if (user != nil)
            {
                LOGINFO(@"关闭视频流");
                if ([self.delegate respondsToSelector:@selector(rtcRemoveStream:)])
                {
                    [self.delegate rtcRemoveStream:user.remoteStream];
                }
                [self closePeerConnection:user];
                return;
            }
            else
            {
                LOGINFO(@"关闭本地视频流");
            }
            
        });
        
    }
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState
{
   
}

//创建peerConnection之后，从server得到响应后调用，得到ICE 候选地址
/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didGenerateIceCandidate:(RTCIceCandidate *)candidate
{
    WebRtcPeerConnectionInfo* user = [self findUser:peerConnection];
    if (user == nil)
    {
        LOGINFO(@"找不到用户")
        return;
    }
    LOGINFO(@"发送 candidate 事件");
    [[SignalingInteractionManager getInstance] candidate:self.userid to:user.userID room:self.roomid sdp:candidate.sdp sdpMLineIndex:candidate.sdpMLineIndex sdpMid:candidate.sdpMid];
}

/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates
{
   
}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection*)peerConnection didOpenDataChannel:(RTCDataChannel*)dataChannel
{

    
}

#pragma mark--RTCDataChannelDelegate

/** The data channel state changed. */
- (void)dataChannelDidChangeState:(RTCDataChannel *)dataChannel
{

}

/** The data channel successfully received a data buffer. */
- (void)dataChannel:(RTCDataChannel *)dataChannel didReceiveMessageWithBuffer:(RTCDataBuffer *)buffer
{
    NSString *message = [[NSString alloc] initWithData:buffer.data encoding:NSUTF8StringEncoding];
}
@end
