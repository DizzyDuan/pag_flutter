package com.path.pag_flutter;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.SurfaceTexture;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.ArrayMap;
import android.view.Surface;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.libpag.PAGFile;
import org.libpag.PAGSurface;

import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.view.TextureRegistry;

public class PagFlutterPlugin implements FlutterPlugin, MethodCallHandler {
    private final Map<String, PagFlutterView> pagViewMap = new ArrayMap<>();

    private Context context;
    private MethodChannel channel;
    private FlutterAssets flutterAssets;
    private TextureRegistry textureRegistry;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "pag_flutter");
        channel.setMethodCallHandler(this);
        flutterAssets = flutterPluginBinding.getFlutterAssets();
        textureRegistry = flutterPluginBinding.getTextureRegistry();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "init":
                init(call, result);
                break;
            case "play":
                play(call, result);
                break;
            case "stop":
                stop(call, result);
                break;
            case "release":
                release(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void init(MethodCall call, Result result) {
        String assetName = call.argument("assetName");
        String filePath = call.argument("filePath");
        PAGFile pagFile = null;
        if (!TextUtils.isEmpty(assetName)) {
            String assetPath = flutterAssets.getAssetFilePathByName(assetName);
            pagFile = PAGFile.Load(context.getAssets(), assetPath);
        } else if (!TextUtils.isEmpty(filePath)) {
            pagFile = PAGFile.Load(context.getAssets(), filePath);
        }
        if (pagFile == null) return;
        TextureRegistry.SurfaceTextureEntry entry = textureRegistry.createSurfaceTexture();
        SurfaceTexture texture = entry.surfaceTexture();
        texture.setDefaultBufferSize(pagFile.width(), pagFile.height());
        Surface surface = new Surface(texture);
        PAGSurface pagSurface = PAGSurface.FromSurface(surface);
        PagFlutterView pagView = new PagFlutterView();
        pagView.setComposition(pagFile);
        pagView.setSurface(pagSurface);
        pagView.addAnimatorListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationStart(Animator animation) {
                channel.invokeMethod("onStart", null);
            }

            @Override
            public void onAnimationEnd(Animator animation) {
                channel.invokeMethod("onEnd", null);
            }
        });
        pagView.setReleaseListener(() -> {
            entry.release();
            surface.release();
            pagSurface.release();
        });
        pagViewMap.put(String.valueOf(entry.id()), pagView);
        pagView.play();
        Map<String, Object> map = new ArrayMap<>();
        map.put("textureId", entry.id());
        map.put("width", (double) pagFile.width());
        map.put("height", (double) pagFile.height());
        result.success(map);
    }

    private void play(MethodCall call, Result result) {
        PagFlutterView pagView = getPagFlutterView(call);
        if (pagView != null) {
            pagView.play();
        }
        result.success("play");
    }

    private void stop(MethodCall call, Result result) {
        PagFlutterView pagView = getPagFlutterView(call);
        if (pagView != null) {
            pagView.stop();
        }
        result.success("stop");
    }

    private void release(MethodCall call, Result result) {
        PagFlutterView pagView = getPagFlutterView(call);
        if (pagView != null) {
            pagView.stop();
            pagView.release();
        }
        result.success("release");
    }

    private PagFlutterView getPagFlutterView(MethodCall call) {
        return pagViewMap.get(getTextureId(call));
    }

    private String getTextureId(MethodCall call) {
        return call.argument("textureId").toString();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        for (PagFlutterView pagPlayer : pagViewMap.values()) {
            pagPlayer.release();
        }
        pagViewMap.clear();
        channel.setMethodCallHandler(null);
    }

}
