import 'package:codepan/media/callback.dart';
import 'package:codepan/resources/dimensions.dart';
import 'package:codepan/services/navigation.dart';
import 'package:codepan/transitions/route_transition.dart';
import 'package:codepan/widgets/button.dart';
import 'package:codepan/widgets/icon.dart';
import 'package:codepan/widgets/loading_indicator.dart';
import 'package:codepan/widgets/media_progress_indicator.dart';
import 'package:codepan/widgets/text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class PanVideoPlayer extends StatefulWidget {
  final OnProgressChanged onProgressChanged;
  final OnCompleted onCompleted;
  final bool isFullScreen;
  final Color color;
  final double width;
  final double height;
  final String uri;
  final _PanVideoPlayerState state;

  PanVideoPlayer({
    Key key,
    @required this.uri,
    this.color,
    this.width,
    this.height,
    this.isFullScreen = false,
    this.state,
    this.onProgressChanged,
    this.onCompleted,
  }) : super(key: key);

  @override
  _PanVideoPlayerState createState() => _PanVideoPlayerState();
}

class _PanVideoPlayerState extends State<PanVideoPlayer> {
  VideoPlayerController _controller;
  bool _isControllerVisible = true;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  double _buffered = 0;
  double _current = 0;
  double _max = 0;

  VideoPlayerValue get _value => _controller?.value;

  bool get isFullscreen => widget.isFullScreen;

  double get aspectRatio => _isInitialized ? _value.aspectRatio : 16 / 9;

  @override
  void initState() {
    if (widget.isFullScreen) {
      final state = widget.state;
      _controller = state._controller;
      _isControllerVisible = state._isControllerVisible;
      _isInitialized = state._isInitialized;
      _isLoading = state._isLoading;
      _isPlaying = state._isPlaying;
      _isBuffering = state._isBuffering;
      _current = state._current;
      _buffered = state._buffered;
      _max = state._max;
      if (_isInitialized) {
        _controller.addListener(_listener);
      }
    } else {
      _controller = VideoPlayerController.network(widget.uri);
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller?.removeListener(_listener);
    if (!widget.isFullScreen) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = Dimension.of(context);
    final width = widget.width ?? d.maxWidth;
    final height =
        isFullscreen ? d.maxHeight : widget.height ?? d.maxWidth / aspectRatio;
    return WillPopScope(
        child: Material(
          color: Colors.grey.shade900,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: <Widget>[
                Center(
                  child: _isInitialized
                      ? Stack(
                          children: <Widget>[
                            Center(
                              child: AspectRatio(
                                aspectRatio: aspectRatio,
                                child: VideoPlayer(_controller),
                              ),
                            ),
                            Container(
                              child: _isBuffering
                                  ? LoadingIndicator(
                                      color: widget.color,
                                    )
                                  : null,
                            ),
                          ],
                        )
                      : Container(
                          child: _isLoading
                              ? LoadingIndicator(
                                  color: widget.color,
                                )
                              : null,
                        ),
                ),
                SizedBox(
                  width: width,
                  height: height,
                  child: GestureDetector(
                    child: AnimatedOpacity(
                      duration: Duration(milliseconds: 250),
                      opacity: _isControllerVisible ? 1 : 0,
                      child: Container(
                        color: Colors.black.withOpacity(0.2),
                        child: _isControllerVisible
                            ? Stack(
                                children: <Widget>[
                                  Center(
                                    child: !_isLoading
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Expanded(
                                                flex: 4,
                                                child: SkipButton(
                                                  direction: Direction.backward,
                                                  onPressed: () {
                                                    _seekTo(_current - 10000);
                                                  },
                                                  isInitialized: _isInitialized,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 5,
                                                child: Center(
                                                  child: PanButton(
                                                    background: !_isInitialized
                                                        ? widget.color ??
                                                            Theme.of(context)
                                                                .primaryColor
                                                        : Colors.transparent,
                                                    radius: d.at(70),
                                                    width: d.at(70),
                                                    height: d.at(70),
                                                    child: Icon(
                                                      _isPlaying
                                                          ? Icons.pause
                                                          : Icons.play_arrow,
                                                      size: _isInitialized
                                                          ? d.at(50)
                                                          : d.at(40),
                                                      color: Colors.white,
                                                    ),
                                                    splashColor: Colors.white
                                                        .withOpacity(0.4),
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onPressed: _onPlay,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 4,
                                                child: SkipButton(
                                                  direction: Direction.forward,
                                                  onPressed: () {
                                                    _seekTo(_current + 10000);
                                                  },
                                                  isInitialized: _isInitialized,
                                                ),
                                              ),
                                            ],
                                          )
                                        : LoadingIndicator(
                                            color: widget.color,
                                          ),
                                  ),
                                  Container(
                                    alignment: Alignment.bottomCenter,
                                    child: _isInitialized
                                        ? Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: d.at(20),
                                            ),
                                            child: MediaProgressIndicator(
                                              activeColor: widget.color,
                                              buffered: _buffered,
                                              current: _current,
                                              max: _max,
                                              onSeekProgress: (value) {
                                                _seekTo(value);
                                              },
                                            ),
                                          )
                                        : null,
                                  ),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: PanButton(
                                      radius: d.at(50),
                                      width: d.at(40),
                                      height: d.at(40),
                                      margin: EdgeInsets.all(d.at(5)),
                                      alignment: Alignment.center,
                                      splashColor:
                                          Colors.white.withOpacity(0.4),
                                      highlightColor: Colors.transparent,
                                      child: Icon(
                                        isFullscreen
                                            ? Icons.fullscreen_exit
                                            : Icons.fullscreen,
                                        size: d.at(30),
                                        color: Colors.white,
                                      ),
                                      onPressed: _fullScreen,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                    onTap: () {
                      _setControllerVisible(!_isControllerVisible);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        onWillPop: () async {
          if (isFullscreen) {
            await SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          }
          return true;
        });
  }

  Future<void> initializeVideo() async {
    if (!_isInitialized) {
      _setLoading(true);
      _setControllerVisible(false);
      await _controller.initialize();
      _controller.addListener(_listener);
      print('Video Initialized Success');
      setState(() {
        _max = _value.duration.inMilliseconds.toDouble();
        _isInitialized = true;
      });
      _setLoading(false);
    }
  }

  void _onPlay() async {
    await initializeVideo();
    if (_current == _max) {
      await _seekTo(1);
    }
    if (_value.isPlaying) {
      await _controller.pause();
    } else {
      _setLoading(true);
      await _controller.play();
      _setLoading(false);
    }
    _setPlaying(_value.isPlaying);
  }

  void _listener() async {
    double value = _value.position.inMilliseconds.toDouble();
    if (value != _current) {
      _setCurrent(value);
      widget.onProgressChanged?.call(value, _max);
    }
    if (value == _max) {
      _setPlaying(false);
      widget.onCompleted?.call();
    }
    _updateBuffered();
  }

  Future<void> _seekTo(double input) async {
    final milliseconds = input < 0.0 ? 0.0 : (input > _max ? _max : input);
    _setLoading(true);
    await _controller.seekTo(
      Duration(
        milliseconds: milliseconds.toInt(),
      ),
    );
    _setCurrent(milliseconds);
    _setLoading(false);
  }

  void _setCurrent(double current) {
    setState(() {
      _current = current;
    });
  }

  void _updateBuffered() {
    setState(() {
      _buffered = _getBuffered();
    });
  }

  void _setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  void _setPlaying(bool isPlaying) {
    setState(() {
      _isPlaying = isPlaying;
    });
  }

  void _setControllerVisible(isControllerVisible) {
    setState(() {
      _isControllerVisible = isControllerVisible;
    });
  }

  double _getBuffered() {
    final range = _value.buffered;
    if (range.length > 0) {
      final iterable = range.map((element) {
        final start = element.start.inMilliseconds;
        final end = element.end.inMilliseconds;
        return end - start;
      });
      final list = iterable.toList();
      final buffered = list.reduce((value, element) => value + element);
      return buffered / _max;
    }
    return 0;
  }

  void _fullScreen() async {
    if (!isFullscreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      NavigationService().push(FadeRoute(
        enter: PanVideoPlayer(
          uri: widget.uri,
          color: widget.color,
          isFullScreen: !isFullscreen,
          state: this,
        ),
      ));
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      NavigationService().pop();
    }
  }
}

enum Direction {
  backward,
  forward,
}

class SkipButton extends StatelessWidget {
  final Direction direction;
  final VoidCallback onPressed;
  final bool isInitialized;

  const SkipButton({
    Key key,
    @required this.direction,
    this.onPressed,
    this.isInitialized,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final d = Dimension.of(context);
    final isForward = direction == Direction.forward;
    return Container(
      alignment: isForward ? Alignment.centerLeft : Alignment.centerRight,
      child: isInitialized
          ? PanButton(
              radius: d.at(60),
              width: d.at(60),
              height: d.at(60),
              margin: EdgeInsets.only(
                top: d.at(20),
              ),
              splashColor: Colors.white.withOpacity(0.4),
              highlightColor: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  PanIcon(
                    icon: isForward ? 'fast_forward' : 'fast_rewind',
                    width: d.at(20),
                    height: d.at(18),
                    isInternal: true,
                  ),
                  PanText(
                    text: '10',
                    fontColor: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    margin: EdgeInsets.only(top: d.at(3)),
                  )
                ],
              ),
              onPressed: onPressed,
            )
          : null,
    );
  }
}
