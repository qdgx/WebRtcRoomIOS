//
//  VideoRendererView.h
//  WebRtcRoomIOS
//
//  Created by wjr on 2018/10/31.
//  Copyright © 2018 wjr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebRTC/RTCEAGLVideoView.h>
#import <WebRTC/RTCMediaStream.h>
#import <WebRTC/RTCVideoTrack.h>
NS_ASSUME_NONNULL_BEGIN

@interface VideoRendererView : UIView
@property(nonatomic,strong) RTCEAGLVideoView* videoView;
@property(nonatomic,weak) RTCMediaStream* stream;
@property(nonatomic,assign) BOOL isLocal;
-(instancetype)initWidthStream:(RTCMediaStream*)stream;
-(void)setVideoSize:(CGSize)size;
@end

NS_ASSUME_NONNULL_END
