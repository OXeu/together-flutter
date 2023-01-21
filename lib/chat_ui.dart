import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:together/room_info.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatUI extends StatefulWidget {
  // final void Function() callback;
  final RoomInfo? roomInfo;
  final List<Message> msg;
  final String selfName;
  final WebSocketChannel channel;

  const ChatUI(
      {Key? key,
      required this.roomInfo,
      required this.channel,
      required this.msg,
      required this.selfName})
      : super(key: key);

  @override
  State<ChatUI> createState() => _ChatUIState();
}

class _ChatUIState extends State<ChatUI> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff333333),
      padding: const EdgeInsets.only(top: 16),
      child: Flex(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flex(
            direction: Axis.horizontal,
            children: [
              const SizedBox(
                width: 8,
              ),
              ...widget.roomInfo?.members.take(3).map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: ClipOval(
                          child: SizedBox(
                              width: 32,
                              height: 32,
                              child: Image.network(e.avatar))),
                    );
                  }).toList() ??
                  [],
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 2),
                child: Container(
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.green),
                  child: const SizedBox(
                    height: 8,
                    width: 8,
                  ),
                ),
              ),
              Text(
                "${widget.roomInfo?.members.length ?? 0} 在线",
                style: const TextStyle(color: Colors.white, fontSize: 10),
                strutStyle: const StrutStyle(height: 1.1,forceStrutHeight: true),
              ),
              const Spacer(),
              if (widget.roomInfo != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${widget.roomInfo?.roomer.name}",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Text(
                      "房主",
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              if (widget.roomInfo != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, left: 8),
                  child: ClipOval(
                      child: SizedBox(
                          width: 32,
                          height: 32,
                          child:
                              Image.network(widget.roomInfo!.roomer.avatar))),
                ),
            ],
          ), // 用户头像列表
          const SizedBox(
            height: 8,
          ),
          Expanded(
            child: ListView.builder(
                itemCount: widget.msg.length,
                itemBuilder: (ctx, index) {
                  final msg = widget.msg[index];
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: msg.type == 1
                            ? MainAxisAlignment.center
                            : msg.name == widget.selfName
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          msg.name != widget.selfName && msg.type == 0
                              ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: msg.avatar ??
                                          "https://q.qlogo.cn/g?b=qq&nk=${10001}&s=640",
                                      height: 32,
                                      width: 32,
                                    ),
                                  ),
                              )
                              : const Spacer(
                                  flex: 1,
                                ),
                          Flexible(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: msg.type == 0
                                  ? msg.name == widget.selfName
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start
                                  : CrossAxisAlignment.center,
                              children: [
                                if (msg.type == 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 0.0),
                                    child: Text(
                                      msg.name ?? "游客",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: msg.type == 1
                                            ? Colors.white12
                                            : Colors.blue),
                                    padding: msg.type == 1
                                        ? const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4)
                                        : const EdgeInsets.all(8),
                                    margin: msg.type == 1
                                        ? EdgeInsets.zero
                                        : const EdgeInsets.only(right: 8),
                                    child: Text(
                                      msg.msg,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: msg.type == 1 ? 10 : 14),
                                      softWrap: true,
                                    )),
                              ],
                            ),
                          ),
                          msg.name == widget.selfName && msg.type == 0
                              ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: msg.avatar ??
                                          "https://q.qlogo.cn/g?b=qq&nk=${10001}&s=640",
                                      height: 32,
                                      width: 32,
                                    ),
                                  ),
                              )
                              : const Spacer(
                                  flex: 1,
                                ),
                        ]),
                  );
                }),
          ),

        ],
      ),
    );
  }
}

class User {
  String name;
  String avatar;

  User(this.name, this.avatar);
}

class Message {
  int type;
  String msg;
  String? name;
  String? avatar;

  Message(
      {required this.type,
      required this.name,
      required this.avatar,
      required this.msg});
}
