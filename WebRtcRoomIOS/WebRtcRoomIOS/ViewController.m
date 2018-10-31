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
#import "VideoRendererView.h"


@interface ViewController () <WebRtcManagerDelegate,RTCVideoViewDelegate>
@property(nonatomic,strong) UILabel* tipLabel;
@property(nonatomic,strong) UITextField* roomIDTextField;
@property(nonatomic,strong) UIButton* joinRoomBtn;
@property(nonatomic,strong) UIButton* exitRoomBtn;
@property(nonatomic,strong) UIButton* cameraBtn;
@property(nonatomic,strong) UIButton* switchCameraBtn;
@property(nonatomic,assign) BOOL isFontCamera;

@property(nonatomic,copy) NSString* userID;
@property(nonatomic,strong) NSArray<NSString*>* users;
@property(nonatomic,strong) NSMutableArray<VideoRendererView*>* views;
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
    self.isFontCamera = YES;
    self.views = [[NSMutableArray alloc] init];
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
    
    self.cameraBtn = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.cameraBtn addTarget:self action:@selector(openCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.cameraBtn setTitle:@"开启摄像头" forState:UIControlStateNormal];
    self.cameraBtn.backgroundColor = [UIColor colorWithRed:170.0f/255.0f green:170.0f/255.0f blue:170.0f/255.0f alpha:1.0];
    [self.view addSubview:self.cameraBtn];
    
    self.switchCameraBtn = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.switchCameraBtn addTarget:self action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.switchCameraBtn setTitle:@"切换摄像头" forState:UIControlStateNormal];
    self.switchCameraBtn.backgroundColor = [UIColor colorWithRed:170.0f/255.0f green:170.0f/255.0f blue:170.0f/255.0f alpha:1.0];
    [self.view addSubview:self.switchCameraBtn];
    
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
    
    [self.cameraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tipLabel.mas_bottom).mas_offset(5);
        make.left.mas_equalTo(self.exitRoomBtn.mas_right).mas_offset(5);
        make.size.mas_equalTo(CGSizeMake(width, 40));
    }];
    
    [self.switchCameraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.joinRoomBtn.mas_bottom).mas_offset(5);
        make.left.mas_equalTo(5);
        make.size.mas_equalTo(CGSizeMake(width, 40));
    }];
}

-(void)joinRoom
{
    if (![[WebRtcManager getInstance] isOpenCamera])
    {
        self.tipLabel.text = @"先开启摄像头";
        return;
    }
    
    [[SignalingInteractionManager getInstance] createAndJoinRoom:self.roomIDTextField.text];
}

-(void)exitRoom
{
    [[WebRtcManager getInstance] close];
    [[SignalingInteractionManager getInstance] exit:self.userID room:self.roomIDTextField.text];
    for (int i = 0; i < self.views.count; i++)
    {
        VideoRendererView* view = [self.views objectAtIndex:i];
        [view removeFromSuperview];
    }
    [self.views removeAllObjects];
}
-(void)openCamera
{
    if ([[WebRtcManager getInstance] isOpenCamera])
    {
        [self.cameraBtn setTitle:@"开启摄像头" forState:UIControlStateNormal];
        [[WebRtcManager getInstance] closeCamra];
    }
    else
    {
        [self.cameraBtn setTitle:@"关闭摄像头" forState:UIControlStateNormal];
        [[WebRtcManager getInstance] openCamera];
    }
}

-(void)switchCamera
{
    if (![[WebRtcManager getInstance] isOpenCamera])
    {
        self.tipLabel.text = @"先开启摄像头";
        return;
    }
    
    if (self.isFontCamera)
    {
        [[WebRtcManager getInstance] switchBackCamera];
        self.isFontCamera = NO;
    }
    else
    {
        [[WebRtcManager getInstance] switchFrontCamera];
        self.isFontCamera = YES;
    }
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
        //LOGINFO(@"收到 candidate event");
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
    else if ([eventName isEqualToString:@"joined"])
    {
        NSString* idString = [data objectForKey:@"id"];
        NSString* room = [data objectForKey:@"room"];
        [[WebRtcManager getInstance] joined:idString room:room];
    }
    else if ([eventName isEqualToString:@"offer"])
    {
        LOGINFO(@"收到 offer event");
        NSString* from = [data objectForKey:@"from"];
        NSString* to = [data objectForKey:@"to"];
        NSString* sdp = [data objectForKey:@"sdp"];
        NSString* room = [data objectForKey:@"room"];
        [[WebRtcManager getInstance] offer:from to:to room:room sdp:sdp];
    }
    
    
    
}

#pragma mark - WebRtcDelegate
-(void)rtcSetLocalStream:(RTCMediaStream*)stream
{
    for (int i = 0; i < self.views.count; i++)
    {
        VideoRendererView* view = [self.views objectAtIndex:i];
        if (view.isLocal)
        {
            return;
        }
    }
    VideoRendererView* videoView = [[VideoRendererView alloc] initWidthStream:stream];
    videoView.isLocal = YES;
    [self.views addObject:videoView];
    [self.view addSubview:videoView];
    [self layoutVideoView];
}
-(void)rtcSetRemoteStream:(RTCMediaStream*)stream
{
    VideoRendererView* videoView = [[VideoRendererView alloc] initWidthStream:stream];
    videoView.isLocal = NO;
    [self.views addObject:videoView];
    [self.view addSubview:videoView];
    [self layoutVideoView];
}

-(void)rtcRemoveStream:(RTCMediaStream*)stream
{
    for (int i = 0; i < self.views.count; i++)
    {
        VideoRendererView* view = [self.views objectAtIndex:i];
        if (view.stream == stream)
        {
            [view removeFromSuperview];
            [self.views removeObjectAtIndex:i];
            break;
        }
    }
    [self layoutVideoView];
}
-(void)layoutVideoView
{
    float x = 0;
    float y = 250;
    float width = self.view.bounds.size.width / 3;
    for (int i = 0; i < self.views.count; i++)
    {
        VideoRendererView* view = [self.views objectAtIndex:i];
        [view setFrame:CGRectMake(x, y, width, width)];
        x += width;
        if (x >= self.view.bounds.size.width)
        {
            x = 0;
            y += width;
        }
    }
}

@end
