import 'package:flutter/material.dart';
import 'package:pag_flutter/pag_plugin.dart';

class PAGView extends StatefulWidget {
  final String? assetName;
  final String? filePath;
  final double? width;
  final double? height;
  final Function()? onStart;
  final Function()? onEnd;

  const PAGView.asset(
    this.assetName, {
    Key? key,
    this.width,
    this.height,
    this.onStart,
    this.onEnd,
  })  : filePath = null,
        super(key: key);

  const PAGView.file(
    this.filePath, {
    Key? key,
    this.width,
    this.height,
    this.onStart,
    this.onEnd,
  })  : assetName = null,
        super(key: key);

  @override
  State<PAGView> createState() => PAGViewState();
}

class PAGViewState extends State<PAGView> {
  int _textureId = -1;
  double _width = 0;
  double _height = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    Map result = await PagPlugin.getChannel().invokeMethod(
      "init",
      {"assetName": widget.assetName, "filePath": widget.filePath},
    );
    _textureId = result["textureId"];
    _width = result["width"];
    _height = result["height"];
    PagPlugin.addHandler(_textureId, (call) {
      Map map = call.arguments;
      if (map["textureId"] == _textureId) {
        switch (call.method) {
          case "onStart":
            if (widget.onStart != null) widget.onStart!();
            break;
          case "onEnd":
            if (widget.onEnd != null) widget.onEnd!();
            break;
        }
      }
    });
    _isInitialized = true;
    if (mounted) {
      setState(() {});
    }
  }

  Future play() {
    return PagPlugin.getChannel().invokeMethod(
      "play",
      {"textureId": _textureId},
    );
  }

  Future stop() {
    return PagPlugin.getChannel().invokeMethod(
      "stop",
      {"textureId": _textureId},
    );
  }

  @override
  void dispose() {
    PagPlugin.getChannel().invokeMethod(
      "release",
      {"textureId": _textureId},
    );
    PagPlugin.removeHandler(_textureId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = const SizedBox();
    if (_isInitialized) {
      child = FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _width / 2,
          height: _height / 2,
          child: Texture(textureId: _textureId),
        ),
      );
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: child,
    );
  }
}
