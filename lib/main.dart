import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:random_string/random_string.dart';
import 'package:together/dialog.dart';
import 'package:together/ext.dart';
import 'package:together/player.dart';
import 'package:together/empty_loading.dart'
    if (dart.library.html) 'package:together/web_loading.dart';

final uid = randomAlpha(4);
final qq = randomNumeric(9);

void main() {
  if (kIsWeb) {
    removeWebLoading();
  }
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AppHomePage(title: "一起看"),
        ),
        GoRoute(
          path: '/watch',
          name: "watch",
          builder: (context, state) {
            return VideoApp(
                source: state.queryParams['source'],
                room: state.queryParams['room'] ?? "room",
                avatar: state.queryParams['avatar'] ??
                    "http://q1.qlogo.cn/g?b=qq&nk=$qq&s=640",
                name: state.queryParams['name'] ?? "游客$uid");
          },
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }
}

class AppHomePage extends StatefulWidget {
  const AppHomePage({super.key, required this.title});

  final String title;

  @override
  State<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends State<AppHomePage> {
  final TextEditingController _controller = TextEditingController();

  // Listening on the `events` stream will open a connection.
  var state = 0;
  List list = List<String>.empty(growable: true);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff1f1f1),
      appBar: AppBar(
        title: Column(children: [
          Text(
            widget.title,
            style: const TextStyle(color: Colors.black),
          ),
          const Text(
            "We Together",
            style: TextStyle(color: Colors.black54, fontSize: 10),
          )
        ]),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Flex(
          direction: MediaQuery.of(context).size.width >
                  MediaQuery.of(context).size.height
              ? Axis.horizontal
              : Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: state == 0
              ? [
                  const Spacer(),
                  MainButton(
                    onClick: () {
                      setState(() {
                        state = 1;
                      });
                    },
                    text: '创建房间',
                    colors: const [Color(0xff8e8eff), Color(0xff32a9ff)],
                  ),
                  const Spacer(),
                  MainButton(
                    onClick: () {
                      setState(() {
                        state = 2;
                      });
                    },
                    text: '加入房间',
                    colors: const [Color(0xffEC6F66), Color(0xffF3A183)],
                  ),
                  const Spacer(),
                ]
              : (state == 1
                  ? [
                      const VideoConfigDialog(
                        isCreate: true,
                      )
                    ]
                  : [
                      const VideoConfigDialog(
                        isCreate: false,
                      )
                    ]),
        ),
      ),
      floatingActionButton: state != 0
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  state = 0;
                });
              },
              tooltip: '返回主页',
              child: const Icon(Icons.arrow_back),
            )
          : null, // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  void dispose() {
    // _channel.sink.close();
    _controller.dispose();
    super.dispose();
  }
}

class MainButton extends StatefulWidget {
  const MainButton(
      {Key? key,
      required this.onClick,
      required this.text,
      required this.colors})
      : super(key: key);
  final void Function() onClick;
  final String text;
  final List<Color> colors;

  @override
  State<MainButton> createState() => _MainButtonState();
}

class _MainButtonState extends State<MainButton> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: context.landscape() ? 1 : 2,
      child: ClipOval(
        child: Material(
          child: Ink(
            decoration:
                BoxDecoration(gradient: LinearGradient(colors: widget.colors)),
            child: InkWell(
              highlightColor: Colors.black38,
              onTap: widget.onClick,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      widget.text,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
