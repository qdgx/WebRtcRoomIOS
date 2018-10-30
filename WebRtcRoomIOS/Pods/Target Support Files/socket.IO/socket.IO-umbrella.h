#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SocketIO.h"
#import "SocketIOJSONSerialization.h"
#import "SocketIOPacket.h"
#import "SocketIOTransport.h"
#import "SocketIOTransportWebsocket.h"
#import "SocketIOTransportXHR.h"

FOUNDATION_EXPORT double socket_IOVersionNumber;
FOUNDATION_EXPORT const unsigned char socket_IOVersionString[];

