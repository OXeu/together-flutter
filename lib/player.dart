import 'dart:collection';
import 'dart:convert';

import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:together/ext.dart';
import 'package:together/player_ui.dart';
import 'package:together/room_info.dart';
import 'package:video_player/video_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'chat_ui.dart';

// const baseUrl = "http://124.221.74.54:8000";
const baseUrl = "wss://together.kafi.work";
// const baseUrl = "ws://10.0.0.100:8080";
const roomId = "room";
// final uid = randomAlpha(4);

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
  var connectState = 0;
  var disposed = false;
  var showChat = false;
  String uid = "";
  RoomInfo? room;
  Map<String, UserWithId> users = HashMap();
  List<Message> msg = List.empty(growable: true);
  String? source;
  String? tips;

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
      loadSource("0${widget.source ?? ""}");
    }
    requestSource();
  }

  setLandscape() {
    WidgetsFlutterBinding.ensureInitialized(); //不加这个强制横/竖屏会报错
    if (context.landscape()) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        //全屏时旋转方向，左边
      ]);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      setState(() {});
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        //全屏时旋转方向，左边
      ]);
      setState(() {});
    }
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
      await Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !disposed && (source == null || source == "")) {
          channel.sink.add("/share request");
        }
        if (source == null || source == "") {
          tips = "未配置源，等待下发";
        } else if (_controller.value.isBuffering) {
          tips = "缓冲中...";
        } else if (!_controller.value.isInitialized) {
          tips = "加载中...";
        } else {
          tips = "";
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

  void loadSource(String source, {Duration? position}) {
    var isPlay = source.substring(0, 1);
    var src = source.substring(1);
    setState(() {
      this.source = src;
      _controller = VideoPlayerController.network(src)
        ..initialize().then((_) {
          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
          setState(() {});
          if (isPlay == "0") {
            _controller.pause();
          } else {
            if (position != null) {
              _controller.seekTo(position);
            }
            _controller.play();
          }
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
            final newUsers = room?.members.map((e) {
              if (e.name == widget.name) {
                uid = e.id;
              }
              return MapEntry(e.id, e);
            });
            if (newUsers != null) {
              users.addEntries(newUsers);
            }
            print(users);
          });
          break;
        case 5: //速度控制
          final speed = double.parse(list[1]);
          if (speed > 0) {
            if (mounted && !disposed) {
              setState(() {
                _controller.setPlaybackSpeed(speed);
              });
            }
          }
          break;
        case 4: // 分享内容
          if (list[1] == "request" && roomer) {
            // /share request
            channel.sink.add(
                "/share ${_controller.value.isPlaying ? "1" : "0"}${source ?? ""}");
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
          var flag = true;
          switch (list[1][0]) {
            case "play":
              setState(() {
                _controller.play();
              });
              break;
            case "pause":
              setState(() {
                _controller.pause();
              });
              break;
            default:
              Duration t = parseTime(list[1][0]);
              Duration? local = await _controller.position;
              if (local != null) {
                final distance = (local - t);
                final speed = double.parse(list[1][1]);
                if (distance.abs() < const Duration(seconds: 2)) {
                  setState(() {
                    _controller.setPlaybackSpeed(
                        distance > Duration.zero ? 0.8 * speed : 1.3 * speed);
                    flag = false;
                  });
                } else if (distance.abs() < const Duration(seconds: 20)) {
                  setState(() {
                    _controller.setPlaybackSpeed(
                        distance > Duration.zero ? 0.5 * speed : 3 * speed);
                    flag = false;
                  });
                } else {
                  setState(() {
                    _controller.seekTo(t);
                  });
                }
                if (distance.abs() < const Duration(milliseconds: 500)) {
                  flag = true;
                }
              }
              break;
          }
          if (_controller.value.isPlaying && flag) {
            final speed = double.parse(list[1][1]);
            if (speed > 0) {
              setState(() {
                _controller.setPlaybackSpeed(speed);
              });
            }
          }
          break;
        case 1:
          if (list[1].contains("房间")) {
            // 更新成员信息
            updateMembers();
          }
          if (list[1] != "NOT_ROOMER") {
            setState(() {
              msg.insert(0, Message(type: 1, uid: null, msg: list[1]));
            });
          }
          break;
        case 0: //用户信息
          List<dynamic> t = list[1];
          setState(() {
            msg.insert(0,
                Message(type: 0, uid: t[0].toString(), msg: t[1].toString()));
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
    if (duration != null && roomer) {
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
      title: 'WeTogether',
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Flex(
            direction: context.landscape() ? Axis.horizontal : Axis.vertical,
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
                  if (tips != null)
                    Center(
                      child: Text(
                        tips ?? "",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
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
                    setLandscape: setLandscape,
                    setShowChat: setShowChat,
                    refresh: () {
                      if (mounted && !disposed) {
                        _controller.dispose();
                        loadSource(
                            "${_controller.value.isPlaying ? "1" : "0"}${source ?? ""}",
                            position: _controller.value.position);
                      }
                    },
                  )
                ]),
              ),
              if (showChat)
                Expanded(
                  flex: showChat
                      ? context.landscape()
                          ? 2
                          : 6
                      : 0,
                  child: ChatUI(
                    roomInfo: room,
                    channel: channel,
                    msg: msg,
                    self: uid,
                    user: users,
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
