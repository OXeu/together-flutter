import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:random_string/random_string.dart';
import 'package:together/dialog.dart';
import 'package:together/player.dart';

final uid = randomAlpha(4);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MyHomePage(title: "一起看"),
        ),
        GoRoute(
          path: '/watch',
          name: "watch",
          builder: (context, state) {
            return VideoApp(
                source: state.queryParams['source'],
                room: state.queryParams['room'] ?? "room",
                avatar: state.queryParams['avatar'] ?? "",
                name: state.queryParams['name'] ?? "游客$uid");
          },
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
            "Together",
            style: TextStyle(color: Colors.black54, fontSize: 10),
          )
        ]),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Flex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: state == 0
            ? [
                MainButton(
                  onClick: () {
                    setState(() {
                      state = 1;
                    });
                  },
                  text: '创建房间',
                  colors: const [Color(0xff8e8eff), Color(0xff32a9ff)],
                ),
                MainButton(
                  onClick: () {
                    setState(() {
                      state = 2;
                    });
                  },
                  text: '加入房间',
                  colors: const [Color(0xffEC6F66), Color(0xffF3A183)],
                ),
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
    return Center(
      child: ClipOval(
        child: FractionallySizedBox(
          widthFactor: 0.4,
          child: InkWell(
            onTap: widget.onClick,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: widget.colors)),
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
    );
  }
}
