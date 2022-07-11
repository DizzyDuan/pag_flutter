#import "PagFlutterPlugin.h"
#import "FlutterPagRender.h"

/**
  FlutterPagPlugin，处理flutter MethodChannel约定的方法
  */
 @interface PagFlutterPlugin()

/// flutter引擎注册的textures对象
@property(nonatomic, weak) NSObject<FlutterTextureRegistry>* textures;

/// flutter引擎注册的registrar对象
@property(nonatomic, weak) NSObject<FlutterPluginRegistrar>* registrar;

/// 保存textureId跟render对象的对应关系
@property (nonatomic, strong) NSMutableDictionary *renderMap;

@property (nonatomic, strong) FlutterMethodChannel *channel;
@end


@implementation PagFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {

  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"pag_flutter"
            binaryMessenger:[registrar messenger]];
    
  PagFlutterPlugin* instance = [[PagFlutterPlugin alloc] init];
  instance.textures = registrar.textures;
  instance.registrar = registrar;
  instance.channel = channel;
  [registrar addMethodCallDelegate:instance channel:channel];
        
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

    id arguments = call.arguments;
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if([@"init" isEqualToString:call.method]){
        [self initPag:arguments result:result];
    } else if([@"start" isEqualToString:call.method]){
        [self start:arguments result:result];
    } else if([@"stop" isEqualToString:call.method]){
        [self stop:arguments result:result];
    }  else if([@"release" isEqualToString:call.method]){
        [self release:arguments result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)release:(id)arguments result:(FlutterResult _Nonnull)result {
     NSNumber* textureId = arguments[@"textureId"];
     if(textureId == nil){
         result(@{});
         return;
     }
    FlutterPagRender *render = [_renderMap objectForKey:textureId];
     [render releaseRender];
     [_renderMap removeObjectForKey:textureId];
     result(@{});
 }

- (void)stop:(id)arguments result:(FlutterResult _Nonnull)result {
     NSNumber* textureId = arguments[@"textureId"];
     if(textureId == nil){
         result(@{});
         return;
     }
    FlutterPagRender *render = [_renderMap objectForKey:textureId];
     [render stopRender];
     result(@{});
}

- (void)start:(id)arguments result:(FlutterResult _Nonnull)result {
     NSNumber* textureId = arguments[@"textureId"];
     if(textureId == nil){
         result(@{});
         return;
     }
    FlutterPagRender *render = [_renderMap objectForKey:textureId];
     [render startRender];
     result(@{});
 }

- (void)initPag:(id)arguments result:(FlutterResult _Nonnull)result {
     if (arguments == nil || (arguments[@"assetName"] == nil && arguments[@"url"] == nil)) {
         result(@-1);
         NSLog(@"showPag arguments is nil");
         return;
     }
     double initProgress = 0.0;
     int repeatCount = 0;
     BOOL autoPlay = YES;
    
     NSString* assetName = arguments[@"assetName"];

     NSData *pagData = nil;
     if ([assetName isKindOfClass:NSString.class] && assetName.length > 0) {
         if (!pagData) {
             NSString* resourcePath = [self.registrar lookupKeyForAsset:assetName];
             resourcePath = [[NSBundle mainBundle] pathForResource:resourcePath ofType:nil];

             pagData = [NSData dataWithContentsOfFile:resourcePath];

         }
         [self pagRenderWithPagData:pagData progress:initProgress repeatCount:repeatCount autoPlay:autoPlay result:result];
     }else{
         if (!pagData) {
            
             NSString *filePath = arguments[@"filePath"];
             pagData = [NSData dataWithContentsOfFile:filePath];
         }
         [self pagRenderWithPagData:pagData progress:initProgress repeatCount:repeatCount autoPlay:autoPlay result:result];
     }
    
     
}

- (void)pagRenderWithPagData:(NSData *)pagData progress:(double)progress repeatCount:(int)repeatCount autoPlay:(BOOL)autoPlay result:(FlutterResult)result{
     __block int64_t textureId = -1;

    FlutterPagRender *render = [[FlutterPagRender alloc] initWithPagData:pagData progress:progress autoPlay:autoPlay frameUpdateCallback:^{
         
          [self.textures textureFrameAvailable:textureId];
     } playerStatusCallback:^(NSString * _Nonnull status) {
         [self.channel invokeMethod:status arguments:@{@"textureId":@(textureId)}];
     }];
     [render setRepeatCount:repeatCount];
     textureId = [self.textures registerTexture:render];
     if(_renderMap == nil){
       _renderMap = [[NSMutableDictionary alloc] init];
     }
     [_renderMap setObject:render forKey:@(textureId)];
     result(@{@"textureId":@(textureId), @"width":@([render size].width), @"height":@([render size].height)});
}

@end
