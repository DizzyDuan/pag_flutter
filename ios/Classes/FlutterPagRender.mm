//
//  TGFlutterPagRender.m
//  pag_flutter
//
//  Created by zhaodeyu on 2022/7/6.
//

#import "FlutterPagRender.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>
#import <libpag/PAGPlayer.h>
#include <chrono>
#include <mutex>

@interface FlutterPagRender()

@property(nonatomic, strong) PAGSurface *surface;

@property (nonatomic, strong) PAGPlayer *player;

@property (nonatomic, strong) PAGFile *pagFile;
 
@property (nonatomic, assign) double initProgress;

@end

static int64_t GetCurrentTimeUS() {
   static auto START_TIME = std::chrono::high_resolution_clock::now();
   auto now = std::chrono::high_resolution_clock::now();
   auto ns = std::chrono::duration_cast<std::chrono::nanoseconds>(now - START_TIME);
   return static_cast<int64_t>(ns.count() * 1e-3);
 }


@implementation FlutterPagRender
{
     FrameUpdateCallback _callback;
    PlayerStatusCallback _playerCallback;
     CADisplayLink *_displayLink;
     int _lastUpdateTs;
     int _repeatCount;
     int64_t start;
}


- (CVPixelBufferRef)copyPixelBuffer {

    CVPixelBufferRef target = [_surface getCVPixelBuffer];
    CVBufferRetain(target);
    return target;
}

- (instancetype)initWithPagData:(NSData*)pagData
                       progress:(double)initProgress
                       autoPlay:(BOOL)autoPlay
            frameUpdateCallback:(FrameUpdateCallback)callback playerStatusCallback:(PlayerStatusCallback)playerCallback
{
    if (self = [super init]) {
        _callback = callback;
        _playerCallback = playerCallback;
        _initProgress = initProgress;
        if(pagData){
            _pagFile = [PAGFile Load:pagData.bytes size:pagData.length];
//            _pagFile = [PAGFile Load:resourcePath];
            _player = [[PAGPlayer alloc] init];
            [_player setComposition:_pagFile];
            _surface = [PAGSurface MakeFromGPU:CGSizeMake(_pagFile.width, _pagFile.height)];
            [_player setSurface:_surface];
            [_player setProgress:initProgress];
            [_player flush];
            _callback();
            if(autoPlay){
                [self startRender];
            }
        }
    }
    return self;
}

- (void)startRender
{
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        _playerCallback(@"onStart");
    }
    start = GetCurrentTimeUS();
}

- (void)stopRender
{
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
    [_player setProgress:_initProgress];
    [_player flush];
    _callback();

}

- (void)pauseRender{
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
}
- (void)setRepeatCount:(int)repeatCount{
    _repeatCount = repeatCount;
}

- (void)setProgress:(double)progress{
    [_player setProgress:progress];
    [_player flush];
    _callback();
}

- (CGSize)size{
    return CGSizeMake(_pagFile.width, _pagFile.height);
}

- (void)update
{
    int64_t duration = [_player duration];
    if(duration <= 0){
        duration = 1;
    }
    int64_t timestamp = GetCurrentTimeUS();
    auto count = (timestamp - start) / duration;
    double value = 0;
    if (_repeatCount >= 0 && count > _repeatCount) {
        value = 1;
    } else {
        double playTime = (timestamp - start) % duration;
        value = static_cast<double>(playTime) / duration;
    }
    [_player setProgress:value];
    [_player flush];
    _callback();
    
    if (value == 1.0) {
        _playerCallback(@"onEnd");
        [self stopRender];
    }
}
- (void)releaseRender{
    [self stopRender];
    _callback = nil;
    _playerCallback = nil;
    _surface = nil;
    self.player = nil;
}


@end
