import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:go_router/go_router.dart';

class VideoConfigDialog extends StatefulWidget {
  const VideoConfigDialog({Key? key, required this.isCreate}) : super(key: key);
  final bool isCreate;

  @override
  State<VideoConfigDialog> createState() => _VideoConfigDialogState();
}

class _VideoConfigDialogState extends State<VideoConfigDialog> {
  TextEditingController sourceCtrl = TextEditingController();
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController roomCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.7,
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
                        style:
                            const TextStyle(color: Colors.black, fontSize: 16),
                      )
                    ],
                  ),
                  if (widget.isCreate)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: sourceCtrl,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '请输入视频源',
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: roomCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '请输入房间名',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '请输入QQ号',
                      ),
                    ),
                  ),
                  TextButton(
                      onPressed: () async {
                        var name = nameCtrl.text;
                        var avatar = "";
                        final request = Dio().get(
                            "https://v.api.aa1.cn/api/qqnicheng/index.php?qq=${nameCtrl.text}&type=json");
                        request.asStream().listen((event) {
                          final resp = event.data.replaceAll("'", '"');
                          print(resp);
                          if(resp.contains("请输入")){
                            showToast("请输入QQ号",context: context);
                          }else {
                            Map<String, dynamic> map = jsonDecode(resp);
                            if (map['qqnicheng'] != null) {
                              name = map['qqnicheng']!;
                              avatar = "http://q1.qlogo.cn/g?b=qq&nk=${nameCtrl
                                  .text}&s=640";
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
                            } else {
                              showToast("获取昵称错误", context: context);
                              return;
                            }
                          }
                        }, onError: (obj) {
                          showToast("获取昵称错误:$obj", context: context);
                          return;
                        }, cancelOnError: true);
                      },
                      child: Text(widget.isCreate ? "创建房间" : "加入房间"))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
