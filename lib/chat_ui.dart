import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:together/edit_text.dart';
import 'package:together/ext.dart';
import 'package:together/room_info.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatUI extends StatefulWidget {
  // final void Function() callback;
  final RoomInfo? roomInfo;
  final List<Message> msg;
  final Map<String, UserWithId> user;
  final String self;
  final WebSocketChannel channel;

  const ChatUI(
      {Key? key,
      required this.roomInfo,
      required this.channel,
      required this.msg,
      required this.self,
      required this.user})
      : super(key: key);

  @override
  State<ChatUI> createState() => _ChatUIState();
}

class _ChatUIState extends State<ChatUI> {
  final TextEditingController controller = TextEditingController();
  final FocusNode node = FocusNode();

  @override
  initState() {
    super.initState();
  }

  send() async {
    setState(() {
      if (controller.text.isNotEmpty) {
        widget.msg.insert(
            0, Message(type: 0, uid: widget.self, msg: controller.text));
        if (controller.text.startsWith("/login")) {
          List<String> str = controller.text.split(" ");
          if (str.length == 3) {
            widget.channel.sink.add(
                "${str[0]} ${str[1]}\nhttp://q1.qlogo.cn/g?b=qq&nk=${str[2]}&s=640");
          } else {
            widget.msg.insert(0, Message(type: 1, uid: null, msg: "格式不正确"));
          }
        } else if (controller.text.startsWith("/")) {
          widget.channel.sink.add(controller.text);
        } else {
          widget.channel.sink.add("/msg ${controller.text}");
        }
        controller.text = "";
        // FocusScope.of(context).requestFocus(node);
      }
    });
  }

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
                  strutStyle:
                      const StrutStyle(height: 1.1, forceStrutHeight: true),
                ),
                const Spacer(),
                if (widget.roomInfo != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${widget.roomInfo?.roomer.name}",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
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
                  reverse: true,
                  itemCount: widget.msg.length,
                  itemBuilder: (ctx, index) {
                    final msg = widget.msg[index];
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Flex(
                          direction: Axis.horizontal,
                          mainAxisAlignment: msg.type == 1
                              ? MainAxisAlignment.center
                              : msg.uid == widget.self
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            msg.uid != widget.self && msg.type == 0
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: widget
                                                .user[msg.uid]?.avatar ??
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
                                    ? msg.uid == widget.self
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start
                                    : CrossAxisAlignment.center,
                                children: [
                                  if (msg.type == 0)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 0.0, vertical: 4),
                                      child: Text(
                                        widget
                                            .user[msg.uid]?.name ?? "游客",
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                  Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: msg.type == 1
                                              ? Colors.white12
                                              : msg.uid == widget.self
                                                  ? Colors.blue
                                                  : Colors.white),
                                      padding: msg.type == 1
                                          ? const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4)
                                          : const EdgeInsets.all(8),
                                      child: Text(
                                        msg.msg,
                                        style: TextStyle(
                                            color: msg.type == 0 &&
                                                    msg.uid != widget.self
                                                ? Colors.black
                                                : Colors.white,
                                            fontSize: msg.type == 1 ? 10 : 14),
                                        softWrap: true,
                                      )),
                                ],
                              ),
                            ),
                            msg.uid == widget.self && msg.type == 0
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: widget
                                            .user[msg.uid]?.avatar ??
                                            "https://q.qlogo.cn/g?b=qq&nk=${10001}&s=640",
                                        height: 32,
                                        width: 32,
                                        errorWidget: (ctx, _, err) => Container(
                                          height: 32,
                                          width: 32,
                                          decoration: const BoxDecoration(
                                              gradient: LinearGradient(colors: [
                                            Color(0xFFe96443),
                                            Color(0xFF904e95)
                                          ])),
                                        ),
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
            Flex(
                direction: Axis.horizontal,
                children: (!context.landscape() || kIsWeb)
                    ? [
                        Expanded(
                          flex: 1,
                          child: EditText(controller: controller, node: node),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: TextButton(
                            onPressed: () {
                              send();
                            },
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.resolveWith(getColor),
                                shape: MaterialStatePropertyAll(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)))),
                            child: const Text(
                              "发送",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ]
                    : [
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Center(
                              child: Text(
                                "请在竖屏模式下编辑发送消息",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        )
                      ]),
          ],
        ));
  }

  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.blueAccent;
    }
    return Colors.blue;
  }
}

class Message {
  int type;
  String? uid;
  String msg;

  Message({required this.type, required this.uid, required this.msg});
}
