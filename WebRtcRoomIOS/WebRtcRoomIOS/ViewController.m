//
//  ViewController.m
//  WebRtcRoomIOS
//
//  Created by wjr on 2018/10/30.
//  Copyright © 2018 wjr. All rights reserved.
//

#import "ViewController.h"
#import "SignalingInteractionManager.h"
#import "WebRtcManager.h"
#import <Masonry/Masonry.h>


@interface ViewController () <WebRtcManagerDelegate,RTCVideoViewDelegate>
@property(nonatomic,strong) UILabel* tipLabel;
@property(nonatomic,strong) UITextField* roomIDTextField;
@property(nonatomic,strong) UIButton* joinRoomBtn;
@property(nonatomic,strong) UIButton* exitRoomBtn;

@property(nonatomic,copy) NSString* userID;
@property(nonatomic,strong) NSArray<NSString*>* users;
@property(nonatomic,strong) NSMutableArray<NSDictionary*>* viewInfos;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"WebRtcTest";
    [self setupView];
    __weak typeof(self) weakSelf = self;
    [SignalingInteractionManager getInstance].dataBlock = ^(NSString *eventName, NSDictionary *data) {
        [weakSelf handleSignaling:eventName data:data];
    };
    self.viewInfos = [[NSMutableArray alloc] init];
    [WebRtcManager getInstance].delegate = self;
}

-(void)setupView
{
    self.roomIDTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.roomIDTextField.text = @"1";
    self.roomIDTextField.placeholder = @"请输入房间号";
    self.roomIDTextField.backgroundColor = [UIColor colorWithRed:170.0f/255.0f green:170.0f/255.0f blue:170.0f/255.0f alpha:1.0];
    [self.view addSubview:self.roomIDTextField];
    
    
    self.joinRoomBtn = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.joinRoomBtn addTarget:self action:@selector(joinRoom) forControlEvents:UIControlEventTouchUpInside];
    [self.joinRoomBtn setTitle:@"加入房间" forState:UIControlStateNormal];
    self.joinRoomBtn.backgroundColor = [UIColor colorWithRed:170.0f/255.0f green:170.0f/255.0f blue:170.0f/255.0f alpha:1.0];
    [self.view addSubview:self.joinRoomBtn];
    
    self.exitRoomBtn = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.exitRoomBtn addTarget:self action:@selector(exitRoom) forControlEvents:UIControlEventTouchUpInside];
    [self.exitRoomBtn setTitle:@"退出房间" forState:UIControlStateNormal];
    self.exitRoomBtn.backgroundColor = [UIColor colorWithRed:170.0f/255.0f green:170.0f/255.0f blue:170.0f/255.0f alpha:1.0];
    [self.view addSubview:self.exitRoomBtn];
    
    self.tipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.tipLabel.numberOfLines = 0;
    [self.view addSubview:self.tipLabel];
    
    [self.roomIDTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuideBottom);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(40);
    }];
    
    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.roomIDTextField.mas_bottom);
        make.left.right.mas_equalTo(0);
    }];
    
    float width = (self.view.bounds.size.width  - 4 * 5) / 3;
    [self.joinRoomBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tipLabel.mas_bottom).mas_offset(5);
        make.left.mas_equalTo(5);
        make.size.mas_equalTo(CGSizeMake(width, 40));
    }];
    
    [self.exitRoomBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tipLabel.mas_bottom).mas_offset(5);
        make.left.mas_equalTo(self.joinRoomBtn.mas_right).mas_offset(5);
        make.size.mas_equalTo(CGSizeMake(width, 40));
    }];
}

-(void)joinRoom
{
    [[SignalingInteractionManager getInstance] createAndJoinRoom:self.roomIDTextField.text];
}

-(void)exitRoom
{
    [[WebRtcManager getInstance] close];
    [[SignalingInteractionManager getInstance] exit:self.userID room:self.roomIDTextField.text];
    for (int i = 0; i < self.viewInfos.count; i++)
    {
        NSDictionary* dic = [self.viewInfos objectAtIndex:i];
        RTCEAGLVideoView* view = [dic objectForKey:@"view"];
        [view removeFromSuperview];
    }
    [self.viewInfos removeAllObjects];
}

-(void)handleSignaling:(NSString*)eventName data:(NSDictionary*)data
{
    if ([eventName isEqualToString:@"created"])
    {
        LOGINFO(@"加入房间成功");
        //创建房间成功
        self.userID = [data objectForKey:@"id"];
        self.users = [data objectForKey:@"peers"];
        [WebRtcManager getInstance].userid = self.userID;
        [WebRtcManager getInstance].roomid = self.roomIDTextField.text;
        self.tipLabel.text = [NSString stringWithFormat:@"加入房间成功:userid=%@ 当前在线人数:%lu",self.userID,self.users.count];
        if (self.users.count > 0)
        {
            for (NSDictionary* dic in self.users)
            {
                NSString* idString = [dic objectForKey:@"id"];
                [[WebRtcManager getInstance] connectWithUserId:idString];
            }
        }
    }
    else if ([eventName isEqualToString:@"answer"])
    {
        LOGINFO(@"收到 answer event");
        NSString* from = [data objectForKey:@"from"];
        NSString* to = [data objectForKey:@"to"];
        NSString* sdp = [data objectForKey:@"sdp"];
        NSString* room = [data objectForKey:@"room"];
        [[WebRtcManager getInstance] answer:from to:to room:room sdp:sdp];
    }
    else if ([eventName isEqualToString:@"candidate"])
    {
        LOGINFO(@"收到 candidate event");
        NSString* from = [data objectForKey:@"from"];
        NSString* to = [data objectForKey:@"to"];
        NSDictionary* candidate = [data objectForKey:@"candidate"];
        NSString* room = [data objectForKey:@"room"];
        NSString* sdp = [candidate objectForKey:@"sdp"];
        NSString* sdpMid = [candidate objectForKey:@"sdpMid"];
        NSNumber* sdpMLineIndex = [candidate objectForKey:@"sdpMLineIndex"];
        [[WebRtcManager getInstance] candidate:from to:to room:room sdp:sdp sdpMLineIndex:sdpMLineIndex.intValue sdpMid:sdpMid];
    }
    else if ([eventName isEqualToString:@"exit"])
    {
        LOGINFO(@"收到 exit event");
    }
    
    
}

#pragma mark - WebRtcDelegate
-(void)rtcSetLocalStream:(RTCMediaStream*)stream
{
    RTCEAGLVideoView* localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 300, 100, 100)];
    localVideoView.contentMode = UIViewContentModeScaleAspectFit;
    localVideoView.delegate = self;
    RTCVideoTrack* track = [stream.videoTracks lastObject];
    [track addRenderer:localVideoView];
    [self.view addSubview:localVideoView];
    
    NSDictionary* dic = @{@"view":localVideoView,@"stream":stream};
    [self.viewInfos addObject:dic];
    [self layoutVideoView];
}
-(void)rtcSetRemoteStream:(RTCMediaStream*)stream
{
    RTCEAGLVideoView* localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(200, 300, 100, 100)];
    localVideoView.contentMode = UIViewContentModeScaleAspectFit;
    localVideoView.delegate = self;
    RTCVideoTrack* track = [stream.videoTracks lastObject];
    [track addRenderer:localVideoView];
    [self.view addSubview:localVideoView];
    
    NSDictionary* dic = @{@"view":localVideoView,@"stream":stream};
    [self.viewInfos addObject:dic];
    [self layoutVideoView];
}

-(void)rtcRemoveStream:(RTCMediaStream*)stream
{
    for (int i = 0; i < self.viewInfos.count; i++)
    {
        NSDictionary* dic = [self.viewInfos objectAtIndex:i];
        RTCMediaStream* s = [dic objectForKey:@"stream"];
        RTCEAGLVideoView* view = [dic objectForKey:@"view"];
        if (s == stream)
        {
            [view removeFromSuperview];
            [self.viewInfos removeObjectAtIndex:i];
            break;
        }
    }
    [self layoutVideoView];
}
-(void)layoutVideoView
{
    float x = 0;
    float y = 200;
    float width = self.view.bounds.size.width / 3;
    for (int i = 0; i < self.viewInfos.count; i++)
    {
        NSDictionary* dic = [self.viewInfos objectAtIndex:i];
        RTCEAGLVideoView* view = [dic objectForKey:@"view"];
        [view setFrame:CGRectMake(x, y, width, width)];
        x += width;
        if (x >= self.view.bounds.size.width)
        {
            x = 0;
            y += width;
        }
    }
}

- (void)videoView:(id<RTCVideoRenderer>)videoView didChangeVideoSize:(CGSize)size
{
//    RTCEAGLVideoView* view = (RTCEAGLVideoView*)videoView;
//    CGRect rect = view.frame;
//    rect.size.width = size.width;
//    rect.size.height = size.height;
//    [view setFrame:rect];
}
@end
