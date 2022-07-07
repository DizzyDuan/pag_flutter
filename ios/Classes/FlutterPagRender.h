//
//  TGFlutterPagRender.h
//  pag_flutter
//
//  Created by zhaodeyu on 2022/7/6.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^FrameUpdateCallback)(void);
typedef void(^PlayerStatusCallback)(NSString *status);

/**
  Pag纹理渲染类
  */
@interface FlutterPagRender : UIView <FlutterTexture>

//当前pag的size
 @property(nonatomic, readonly) CGSize size;

 - (instancetype)initWithPagData:(NSData*)pagData
                        progress:(double)initProgress
                        autoPlay:(BOOL)autoPlay
             frameUpdateCallback:(FrameUpdateCallback)callback playerStatusCallback:(PlayerStatusCallback)playerCallback;

 - (void)startRender;

 - (void)stopRender;

 - (void)pauseRender;

 - (void)releaseRender;

 - (void)setProgress:(double)progress;

 - (void)setRepeatCount:(int)repeatCount;

@end

NS_ASSUME_NONNULL_END
