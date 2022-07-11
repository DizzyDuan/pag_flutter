import 'package:flutter/services.dart';

class PagPlugin {
  static const MethodChannel _channel = MethodChannel("pag_flutter");

  static MethodChannel getChannel() => _channel;

  static bool isHandler = false;
  static Map handlerMap = {};

  static void addHandler(
    int textureId,
    Function(MethodCall call) callback,
  ) {
    handlerMap.putIfAbsent(textureId.toString(), () => callback);
    if (isHandler) return;
    isHandler = true;
    _channel.setMethodCallHandler((call) async {
      handlerMap.forEach((key, value) {
        value(call);
      });
    });
  }

  static void removeHandler(int textureId) {
    handlerMap.remove(textureId.toString());
  }
}
