import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:together/edit_text.dart';

class VideoConfigDialog extends StatefulWidget {
  const VideoConfigDialog({Key? key, required this.isCreate}) : super(key: key);
  final bool isCreate;

  @override
  State<VideoConfigDialog> createState() => _VideoConfigDialogState();
}

class _VideoConfigDialogState extends State<VideoConfigDialog> {
  // TextEditingController sourceCtrl = TextEditingController(text: "https://prod-streaming-video-msn-com.akamaized.net/0a0fbcc9-ba13-4756-a69c-283160377b2e/8356cb12-6847-4e37-b165-35c525b6b405.mp4");
  // TextEditingController roomCtrl = TextEditingController(text: "Room");
  // TextEditingController nameCtrl = TextEditingController(text: "1573856599");
  TextEditingController sourceCtrl = TextEditingController();
  TextEditingController roomCtrl = TextEditingController();
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController qqCtrl = TextEditingController();
  FocusNode node1 = FocusNode();
  FocusNode node2 = FocusNode();
  FocusNode node3 = FocusNode();
  FocusNode node4 = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: FractionallySizedBox(
            widthFactor: 0.8,
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Flex(
                  mainAxisSize: MainAxisSize.min,
                  direction: Axis.vertical,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.isCreate ? "创建房间" : "加入房间",
                          style: const TextStyle(
                              color: Colors.black, fontSize: 16),
                        )
                      ],
                    ),
                    if (widget.isCreate)
                      Padding(
                        padding: const EdgeInsets.all(0),
                        child: EditText(
                          controller: sourceCtrl,
                          node: node1,
                          hint: "视频源",
                          background: const Color(0xFFF6F6F6),
                          textColor: Colors.black,
                          margin: const EdgeInsets.only(top: 16),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(0),
                      child: EditText(
                        controller: roomCtrl,
                        node: node2,
                        hint: "房间名",
                        background: const Color(0xFFF6F6F6),
                        textColor: Colors.black,
                        margin: const EdgeInsets.only(top: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(.0),
                      child: EditText(
                        controller: nameCtrl,
                        node: node3,
                        hint: "昵称",
                        background: const Color(0xFFF6F6F6),
                        textColor: Colors.black,
                        margin: const EdgeInsets.only(top: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(.0),
                      child: EditText(
                        controller: qqCtrl,
                        node: node4,
                        hint: "QQ号",
                        background: const Color(0xFFF6F6F6),
                        textColor: Colors.black,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    TextButton(
                        onPressed: () async {
                          var name = nameCtrl.text;
                          if (roomCtrl.text.isEmpty) {
                            showToast("请输入房间名", context: context);
                          } else if (qqCtrl.text.isEmpty) {
                            showToast("请输入QQ号", context: context);
                          } else if (nameCtrl.text.isEmpty) {
                            showToast("请输入昵称", context: context);
                          } else {
                            final avatar =
                                "http://q1.qlogo.cn/g?b=qq&nk=${qqCtrl.text}&s=640";
                            final params = {
                              'room': roomCtrl.text,
                              'name': name,
                              'avatar': avatar,
                              'source': sourceCtrl.text
                            };
                            if (!widget.isCreate) {
                              params.remove('source');
                            }
                            context.pushNamed('watch', queryParams: params);
                          }
                        },
                        child: Text(widget.isCreate ? "创建房间" : "加入房间"))
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
