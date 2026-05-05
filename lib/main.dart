import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class SleepRecord {
  final String sleep;
  final String wake;
  final String duration;

  SleepRecord({
    required this.sleep,
    required this.wake,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {'sleep': sleep, 'wake': wake, 'duration': duration};
  }

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    return SleepRecord(
      sleep: json['sleep'],
      wake: json['wake'],
      duration: json['duration'],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TimeOfDay? sleepTime;
  TimeOfDay? wakeTime;

  List<SleepRecord> records = [];

  void saveRecord() {
    if (sleepTime == null || wakeTime == null) return;

    final sleep = sleepTime!.hour * 60 + sleepTime!.minute;
    final wake = wakeTime!.hour * 60 + wakeTime!.minute;

    int diff = wake - sleep;
    if (diff < 0) diff += 24 * 60;

    final h = diff ~/ 60;
    final m = diff % 60;

    final record = SleepRecord(
      sleep: sleepTime!.format(context),
      wake: wakeTime!.format(context),
      duration: "$h小时$m分钟",
    );

    setState(() {
      print("🔥 saveToLocal 执行了");
      records.add(record);
    });

    saveToLocal();
  }

  Future<void> saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> data = records.map((r) => jsonEncode(r.toJson())).toList();

    print("📦 准备保存: $data");

    final result = await prefs.setStringList('records', data);

    print("💾 写入结果: $result");
  }

  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList('records');

    print("📥 读取到的数据: $data");

    if (data != null) {
      setState(() {
        records = data.map((e) => SleepRecord.fromJson(jsonDecode(e))).toList();
      });
    }
  }

  Future<void> pickSleepTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        sleepTime = time;
      });
    }
  }

  Future<void> pickWakeTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        wakeTime = time;
      });
    }
  }

  String getDuration() {
    if (sleepTime == null || wakeTime == null) {
      return "请选择入睡和起床时间";
    }

    final sleep = sleepTime!.hour * 60 + sleepTime!.minute;
    final wake = wakeTime!.hour * 60 + wakeTime!.minute;

    int diff = wake - sleep;
    if (diff < 0) diff += 24 * 60;

    final h = diff ~/ 60;
    final m = diff % 60;

    return "睡了 $h 小时 $m 分钟";
  }

  @override
  void initState() {
    super.initState();
    loadFromLocal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("睡眠记录App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('欢迎使用睡眠记录App'),

            ElevatedButton(
              onPressed: pickSleepTime,
              child: Text(
                sleepTime == null
                    ? "选择入睡时间"
                    : "入睡时间：${sleepTime!.format(context)}",
              ),
            ),

            ElevatedButton(
              onPressed: pickWakeTime,
              child: Text(
                wakeTime == null
                    ? "选择起床时间"
                    : "起床时间：${wakeTime!.format(context)}",
              ),
            ),

            ElevatedButton(onPressed: saveRecord, child: Text("保存记录")),

            const SizedBox(height: 20),

            const SizedBox(height: 20),

            const Text("历史记录："),

            ...records.asMap().entries.map((entry) {
              final index = entry.key;
              final r = entry.value;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text("睡：${r.sleep}  起：${r.wake}  ${r.duration}"),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        print("🔥 saveToLocal 执行了");
                        records.removeAt(index);
                      });

                      saveToLocal();
                    },
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
