import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:custom_radio_grouped_button/custom_radio_grouped_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';
import 'package:together/chat_ui.dart';
import 'package:together/ext.dart';
import 'package:together/room_info.dart';
import 'package:video_player/video_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PlayerUI extends StatefulWidget {
  final bool roomer;
  final String room;
  final void Function() setLandscape;
  final void Function() setShowChat;
  final void Function() refresh;
  final String selfName;
  final int connectState;
  final VideoPlayerController? controller;
  final WebSocketChannel channel;
  final RoomInfo? roomInfo;
  final List<Message> msg;

  const PlayerUI(
      {Key? key,
      required this.roomer,
      required this.controller,
      required this.channel,
      required this.connectState,
      required this.room,
      required this.roomInfo,
      required this.msg,
      required this.selfName,
      required this.setLandscape,
      required this.setShowChat,
      required this.refresh})
      : super(key: key);

  @override
  State<PlayerUI> createState() => _PlayerUIState();
}

class _PlayerUIState extends State<PlayerUI>
    with SingleTickerProviderStateMixin {
  var show = true;
  var lock = false;
  var progress = "00:00";
  var duration = "00:00";
  var progressDur = Duration.zero;
  var slideDur = Duration.zero;
  var cachedDur = Duration.zero;
  var startSlide = false;
  var durationDur = Duration.zero;
  late Animation<double> animation;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    animation = Tween<double>(begin: 0, end: 100).animate(controller)
      ..addListener(() {
        setState(() {});
      });
    controller.forward();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    syncProgress();
    syncCached();
  }

  syncCached() async {
    while (true) {
      await Future.delayed(const Duration(seconds: 2), () {
        cachedDur = (widget.controller?.value.buffered ??
                [DurationRange(Duration.zero, Duration.zero)])
            .fold(
                Duration.zero,
                (previousValue, element) =>
                    previousValue + element.end - element.start);
      });
    }
  }

  void syncProgress() async {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 400), () {
        final ctrl = widget.controller;
        if (ctrl != null) {
          if (duration == "00:00") {
            duration = ctrl.value.duration.string();
            durationDur = ctrl.value.duration;
          }
          ctrl.position.then((value) {
            if (mounted) {
              setState(() {
                if (!startSlide && durationDur != Duration.zero) {
                  progress = value?.string() ?? "00:00";
                  progressDur = value ?? Duration.zero;
                  slideDur = progressDur;
                }
              });
            }
          });
        }
      });
    }
  }

  void seek(Duration duration) async {
    final controller = widget.controller;
    final channel = widget.channel;
    if (controller != null) {
      controller.position.then((value) {
        if (value != null) {
          Duration dest = value + duration;
          controller.seekTo(dest);
          var post = "/progress $duration\n${controller.value.playbackSpeed}";
          channel.sink.add(post);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var connectState = "连接中";
    switch (widget.connectState) {
      case 0:
        connectState = "连接中";
        break;
      case 1:
        connectState = "在线";
        break;
      case 2:
        connectState = "重试中";
        break;
      case 3:
        connectState = "连接已断开";
        break;
    }
    return Container(
      color: show ? const Color(0x48000000) : Colors.transparent,
      child: Flex(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (show && !lock)
            Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              textBaseline: TextBaseline.ideographic,
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) context.pop();
                  },
                  icon: const Icon(
                    Remix.arrow_left_s_fill,
                    size: 24,
                    color: Colors.white,
                  ),
                  tooltip: "返回",
                ),
                Text(
                  "${widget.room}${widget.roomer ? "(房主)" : "(成员)"}",
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  strutStyle: const StrutStyle(forceStrutHeight: true),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 2),
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.connectState == 1
                            ? Colors.green
                            : Colors.red),
                    child: const SizedBox(
                      height: 8,
                      width: 8,
                    ),
                  ),
                ),
                Text(
                  connectState,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  strutStyle:
                      const StrutStyle(height: 1.2, forceStrutHeight: true),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    widget.setShowChat();
                  },
                  icon: const Icon(
                    Remix.chat_1_line,
                    size: 24,
                    color: Colors.white,
                  ),
                  tooltip: "聊天",
                ),
              ],
            ),
          Expanded(
            child: Stack(alignment: AlignmentDirectional.centerEnd, children: [
              GestureDetector(
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        show = !show;
                      });
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                  )),
              if (show)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        lock = !lock;
                      });
                    },
                    icon: Icon(
                      lock
                          ? Icons.lock_outline_rounded
                          : Icons.lock_open_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                    tooltip: lock ? "解锁" : "锁定",
                  ),
                ),
            ]),
          ),
          if (show && !lock)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Flex(
                direction: Axis.horizontal,
                children: [
                  Expanded(
                    child: ProgressBar(
                      progress: slideDur,
                      buffered: cachedDur,
                      total: durationDur,
                      onSeek: (duration) {
                        if (widget.roomer) {
                          startSlide = false;
                          if ((duration - progressDur).abs() >
                              const Duration(seconds: 5)) {
                            widget.controller?.seekTo(duration);
                          }
                        }
                      },
                      baseBarColor: Colors.white12,
                      bufferedBarColor: Colors.white38,
                      progressBarColor: Colors.white,
                      thumbColor:
                          widget.roomer ? Colors.white : Colors.transparent,
                      thumbGlowColor:
                          widget.roomer ? Colors.white38 : Colors.transparent,
                      barHeight: 15,
                      onDragStart: (duration) {
                        if (widget.roomer) {
                          startSlide = true;
                          setState(() {
                            slideDur = duration.timeStamp;
                          });
                        }
                      },
                      onDragUpdate: (duration) {
                        if (widget.roomer) {
                          setState(() {
                            slideDur = duration.timeStamp;
                          });
                        }
                      },
                      onDragEnd: () {
                        startSlide = false;
                      },
                      timeLabelLocation: TimeLabelLocation.sides,
                      timeLabelTextStyle:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  // Text(
                  //   duration,
                  //   style: const TextStyle(color: Colors.white, fontSize: 12),
                  // ),
                ],
              ),
            ),
          if (show && !lock)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Flex(
                direction: Axis.horizontal,
                children: [
                  IconButton(
                    onPressed: () {
                      var controller = widget.controller;
                      if (controller != null && mounted) {
                        setState(() {
                          controller.value.isPlaying
                              ? controller.pause()
                              : controller.play();
                          if (widget.roomer) {
                            widget.channel.sink.add(
                                "/progress ${controller.value.isPlaying ? "play" : "pause"}\n${controller.value.playbackSpeed}");
                          }
                        });
                      }
                    },
                    icon: Icon(
                      widget.controller?.value.isPlaying ?? false
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                    tooltip: widget.controller?.value.isPlaying ?? false
                        ? "暂停"
                        : "播放",
                  ),
                  IconButton(
                    onPressed: () {
                      widget.refresh();
                    },
                    icon: const Icon(
                      Remix.refresh_line,
                      size: 24,
                      color: Colors.white,
                    ),
                    tooltip: "同步进度",
                  ),
                  if (widget.roomer)
                    IconButton(
                      onPressed: () {
                        seek(const Duration(seconds: -10));
                      },
                      icon: const Icon(
                        Icons.replay_10_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                      tooltip: "后退10s",
                    ),
                  if (widget.roomer)
                    IconButton(
                      onPressed: () {
                        seek(const Duration(seconds: 10));
                      },
                      icon: const Icon(
                        Icons.forward_10_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                      tooltip: "前进10s",
                    ),
                  const Spacer(),
                  if (!widget.roomer)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "${widget.controller?.value.playbackSpeed.toStringAsFixed(1) ?? "1.0"}X",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  if (context.landscape() && widget.roomer)
                    CustomRadioButton(
                      elevation: 0,
                      height: 25,
                      width: 60,
                      absoluteZeroSpacing: true,
                      unSelectedColor: Colors.transparent,
                      buttonLables: const [
                        '0.5',
                        '0.75',
                        '1.0',
                        '1.25',
                        '1.5',
                        '2.0',
                        '3.0',
                      ],
                      buttonValues: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0],
                      buttonTextStyle: const ButtonTextStyle(
                          selectedColor: Colors.white,
                          unSelectedColor: Colors.white70,
                          textStyle: TextStyle(fontSize: 12)),
                      radioButtonValue: (value) {
                        if (widget.controller != null) {
                          widget.controller?.setPlaybackSpeed(value);
                          final speed = "/speed $value";
                          widget.channel.sink.add(speed);
                        }
                      },
                      selectedColor: Colors.transparent,
                      unSelectedBorderColor: Colors.transparent,
                      selectedBorderColor: Colors.transparent,
                      defaultSelected: min(
                          3.0,
                          widget.controller?.value.playbackSpeed
                                  .roundToDouble() ??
                              1.0),
                    ),
                  IconButton(
                    onPressed: () {
                      widget.setLandscape();
                    },
                    icon: Icon(
                      context.landscape()
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                    tooltip: context.landscape() ? "退出全屏" : "全屏",
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }
}
