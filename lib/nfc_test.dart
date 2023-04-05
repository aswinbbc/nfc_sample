import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyHceSreen extends StatefulWidget {
  const MyHceSreen({super.key});

  @override
  State<MyHceSreen> createState() => _MyHceSreenState();
}

class _MyHceSreenState extends State<MyHceSreen> {
  static const platform = MethodChannel('com.example.nfc_sample/hce');
  // Get battery level.
  String _batteryLevel = 'Unknown battery level.';

  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final bool result =
          await platform.invokeMethod('startHce', {"text": controller.text});
      batteryLevel = 'Battery level at $result % .';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }
  }

  TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: "Enter your text here..."),
        ),
      ),
      ElevatedButton(
        onPressed: () async {
          _getBatteryLevel();
        },
        child: Text('Write HCE'),
      )
    ]);
  }
}
