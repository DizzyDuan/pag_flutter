import 'package:flutter/services.dart';

class PagPlugin {
  static const MethodChannel _channel = MethodChannel('pag_flutter');

  static MethodChannel getChannel() => _channel;
}
