//
//  VideoRendererView.m
//  WebRtcRoomIOS
//
//  Created by wjr on 2018/10/31.
//  Copyright © 2018 wjr. All rights reserved.
//

#import "VideoRendererView.h"

@interface VideoRendererView()<RTCVideoViewDelegate>
@property(nonatomic,assign) CGSize videoSize;
@end

@implementation VideoRendererView

-(instancetype)initWidthStream:(RTCMediaStream*)stream
{
    self = [super init];
    if (self)
    {
        self.isLocal = YES;
        self.videoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        self.stream = stream;
        RTCVideoTrack* track = [stream.videoTracks lastObject];
        [track addRenderer:self.videoView];
        self.videoView.delegate = self;
        [self addSubview:self.videoView];
        self.clipsToBounds = YES;
        
        
        
        
    }
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    if (self.videoSize.width > 0 && self.videoSize.height > 0)
    {
        if (self.isLocal)
        {
            self.videoSize = [UIScreen mainScreen].bounds.size;            
        }
        
        // Aspect fill remote video into bounds.
        CGRect remoteVideoFrame = AVMakeRectWithAspectRatioInsideRect(self.videoSize, bounds);
        CGFloat scale = 1;
        if (remoteVideoFrame.size.width > remoteVideoFrame.size.height) {
            // Scale by height.
            scale = bounds.size.height / remoteVideoFrame.size.height;
        } else {
            // Scale by width.
            scale = bounds.size.width / remoteVideoFrame.size.width;
        }
        remoteVideoFrame.size.height *= scale;
        remoteVideoFrame.size.width *= scale;
        self.videoView.frame = remoteVideoFrame;
        self.videoView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    }
    else if(bounds.size.width > 0 && bounds.size.height > 0)
    {
        self.videoView.frame = bounds;
    }
}
- (void)videoView:(id<RTCVideoRenderer>)videoView didChangeVideoSize:(CGSize)size {
    if (videoView == self.videoView)
    {
        self.videoSize = size;
        [self setNeedsLayout];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
