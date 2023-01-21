import 'dart:convert';

import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:random_string/random_string.dart';
import 'package:together/player_ui.dart';
import 'package:together/room_info.dart';
import 'package:video_player/video_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'chat_ui.dart';

// const baseUrl = "http://124.221.74.54:8000";
const baseUrl = "wss://together.kafi.work";
// const baseUrl = "ws://10.0.0.100:8080";
const roomId = "room";
final uid = randomAlpha(4);

/// Stateful widget to fetch and then display video content.
class VideoApp extends StatefulWidget {
  const VideoApp(
      {Key? key,
      this.source,
      required this.room,
      required this.name,
      required this.avatar})
      : super(key: key);
  final String? source;
  final String room;
  final String name;
  final String avatar;

  @override
  VideoAppState createState() => VideoAppState();
}

class VideoAppState extends State<VideoApp> {
  late VideoPlayerController _controller;
  var roomer = true;
  var landscape = false;
  var connectState = 0;
  var disposed = false;
  var showChat = false;
  RoomInfo? room;
  List<Message> msg = List.empty(growable: true);
  String? source;

  // 0连接中 1在线 2重试 3离线
  WebSocketChannel channel = WebSocketChannel.connect(
    Uri.parse('$baseUrl/ws'),
  );

  // 'https://ccp-bj29-video-preview.oss-enet.aliyuncs.com/lt/9D999EBA9307DA6E1DBD238B6BB53DC649D9006C_803716420__sha1_bj29/FHD/media.m3u8?di=bj29&dr=802942801&f=63c911882aecb85ee91549ac9c65c66c83cd060c&security-token=CAIS%2BgF1q6Ft5B2yfSjIr5bAGuPjvup744CYekzclU09a8kb2vzggzz2IHFPeHJrBeAYt%2FoxmW1X5vwSlq5rR4QAXlDfNVvfYnDiqVHPWZHInuDox55m4cTXNAr%2BIhr%2F29CoEIedZdjBe%2FCrRknZnytou9XTfimjWFrXWv%2Fgy%2BQQDLItUxK%2FcCBNCfpPOwJms7V6D3bKMuu3OROY6Qi5TmgQ41Uh1jgjtPzkkpfFtkGF1GeXkLFF%2B97DRbG%2FdNRpMZtFVNO44fd7bKKp0lQLukMWr%2Fwq3PIdp2ma447NWQlLnzyCMvvJ9OVDFyN0aKEnH7J%2Bq%2FzxhTPrMnpkSlacGoABkk1yODbtjZJ55J68eCoIy7%2BBz1BSg1a5IZgrdZjuhPKHVp2kZIH63pdY%2FeuwzBztlr%2F8LbIjYUeNqMCALRimLbIfDror3MlDDaYtXMnlVgUjnaZc4GTUjspThE%2FXUviomRp5mL7NmifSsGo5NQy%2BYcJ9XBumqInvLlsAgUms4wo%3D&u=b373622d9e704ffc8851862de564f4fa&x-oss-access-key-id=STS.NUuQYWS5ZTBsxjmqMhgF759Ka&x-oss-expires=1674146845&x-oss-process=hls%2Fsign&x-oss-signature=z95LedJ8jH%2FpMImSgmvWxGz%2FxqFlzogC0qg6bQyCwG8%3D&x-oss-signature-version=OSS2'
  // 'https://vod1.jegms.com/20221123/vnsPRQDZ/index.m3u8'
  @override
  void initState() {
    super.initState();
    source = widget.source;
    reconnect(init: true);
    syncMembers();
    if (mounted) {
      loadSource(widget.source ?? "");
    }
    requestSource();
  }

  setLandscape() {
    setState(() {
      if (landscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        landscape = false;
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          //全屏时旋转方向，左边
        ]);
        landscape = true;
      }
    });
  }

  setShowChat() {
    setState(() {
      showChat = !showChat;
    });
  }

  syncMembers() async {
    updateMembers();
    while (true) {
      await Future.delayed(const Duration(seconds: 10), () {
        updateMembers();
      });
    }
  }

  void requestSource() async {
    while (true) {
      await Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !disposed && (source == null || source == "")) {
          channel.sink.add("/share request");
        }
      });
    }
  }

  void updateConnectState(int state) {
    if (connectState != state && mounted) {
      setState(() {
        connectState = state;
      });
    }
  }

  void loadSource(String source) {
    setState(() {
      this.source = source;
      _controller = VideoPlayerController.network(source)
        ..initialize().then((_) {
          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
          setState(() {});
          syncProgress();
        });
    });
  }

  void reconnect({init = false}) async {
    if (mounted && !disposed) {
      print("Reconnect:${channel.closeCode}");
      if (!init) {
        setState(() {
          try {
            channel.sink.close();
            channel = WebSocketChannel.connect(
              Uri.parse('$baseUrl/ws'),
            );
          } catch (e) {
            print("WebSocketError:$e");
          }
        });
      }
      channel.stream.listen(
        (event) {
          updateConnectState(1);
          _receiveMsg(event);
        },
        onError: (obj) async {
          updateConnectState(3);
          print("EventSource Error$obj");
          await Future.delayed(const Duration(seconds: 4));
          updateConnectState(2);
          reconnect();
        },
        onDone: () async {
          print("EventSource Done");
          updateConnectState(3);
          await Future.delayed(const Duration(seconds: 4));
          updateConnectState(2);
          reconnect();
        },
        cancelOnError: true,
      );
      channel.sink.add("/login ${widget.name}\n${widget.avatar}");
      channel.sink.add("/join ${widget.room}");
      if (widget.source != null) {
        channel.sink.add("/share ${widget.source}");
      }
    }
  }

  void _receiveMsg(dynamic event) async {
    print(event);
    List<dynamic> list = jsonDecode(event);
    if (list.length >= 2) {
      switch (list[0]) {
        case 6: //成员信息
          setState(() {
            room = RoomInfo.fromJson(list[1]);
          });
          break;
        case 5: //速度控制
          final speed = double.parse(list[1]);
          if (speed > 0) {
            _controller.setPlaybackSpeed(speed);
          }
          break;
        case 4: // 分享内容
          if (list[1] == "request" && roomer) {
            print("Roomer got the share request,share");
            channel.sink.add("/share $source");
          } else {
            loadSource(list[1]);
          }
          break;
        case 3: // 房主通知
          if (mounted) {
            setState(() {
              roomer = list[1];
              if (roomer) {
                showToast("你已成为房主", context: context);
              }
            });
          }
          break;
        case 2: //进度控制
          switch (list[1][0]) {
            case "play":
              _controller.play();
              break;
            case "pause":
              _controller.pause();
              break;
            default:
              if (!_controller.value.isPlaying) {
                _controller.play();
              }
              Duration t = parseTime(list[1][0]);
              Duration? local = await _controller.position;
              if (local != null &&
                  (local - t).abs() > const Duration(seconds: 3)) {
                _controller.seekTo(t + const Duration(seconds: 1));
              }
              break;
          }
          final speed = double.parse(list[1][1]);
          if (speed > 0) {
            _controller.setPlaybackSpeed(speed);
          }
          break;
        case 1:
          if (list[1].contains("房间")) {
            // 更新成员信息
            updateMembers();
          }
          setState(() {
            msg.add(Message(type: 1, name: null, avatar: null, msg: list[1]));
          });
          break;
        case 0:
          List<dynamic> t = list[1];
          setState(() {
            msg.add(Message(
                type: 0,
                name: t[0].toString(),
                avatar: t[1].toString(),
                msg: t[2].toString()));
          });
          break;
      }
    }
  }

  void updateMembers() async {
    if (mounted && !disposed) {
      channel.sink.add("/members");
    }
  }

  void syncProgress() async {
    while (true) {
      await Future.delayed(const Duration(seconds: 1), () {
        _controller.position.then((value) {
          if (_controller.value.isPlaying) {
            _sendMessage(value);
          }
        });
      });
    }
  }

  void _sendMessage(Duration? duration) async {
    if (duration != null) {
      try {
        // var response = await Dio().post('$baseUrl/message', data: formData);
        var post = "/progress $duration\n${_controller.value.playbackSpeed}";
        print(post);
        channel.sink.add(post);
        // print(response);
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Demo',
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Flex(
            direction: landscape ? Axis.horizontal : Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 4,
                child: Stack(fit: StackFit.loose, children: [
                  Center(
                    child: _controller.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          )
                        : Container(),
                  ),
                  if (source == null)
                    const Center(
                      child: Text(
                        "未配置源，等待下发",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  PlayerUI(
                    room: widget.room,
                    roomer: roomer,
                    controller: _controller,
                    channel: channel,
                    connectState: connectState,
                    roomInfo: room,
                    msg: msg,
                    selfName: widget.name,
                    landscape: landscape,
                    setLandscape: setLandscape,
                    setShowChat: setShowChat,
                  )
                ]),
              ),
              if (showChat)
                Expanded(
                  flex: showChat
                      ? landscape
                          ? 2
                          : 6
                      : 0,
                  child: ChatUI(
                    roomInfo: room,
                    channel: channel,
                    msg: msg,
                    selfName: widget.name,
                  ),
                ),
            ]),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    try {
      disposed = true;
      channel.sink.close(1000);
      print("Close Channel");
    } catch (e) {
      print("Close Channel Error:$e");
    }
    super.dispose();
  }
}
