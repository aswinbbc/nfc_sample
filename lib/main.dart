
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_sample/nfc_test.dart';

/// Global flag if NFC is avalible
bool isNfcAvalible = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for the line below
  isNfcAvalible = await NfcManager.instance.isAvailable();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter NFC Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'title'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool listenerRunning = false;
  bool writeCounterOnNextContact = false;
  final controller = TextEditingController();

  _listenForNFC() {
    if (isNfcAvalible) {
      if (!listenerRunning) {
        NfcManager.instance.startSession(
          onDiscovered: (NfcTag tag) async {
            print({'@#data': tag.data.toString()});
            _alert(tag.data.toString());

            setState(() {
              Map tagData = tag.data;
              Map tagNdef = tagData['ndef'];
              Map cachedMessage = tagNdef['cachedMessage'];
              Map records = cachedMessage['records'][0];
              Uint8List payload = records['payload'];
              String payloadAsString = String.fromCharCodes(payload);
              list.add(payloadAsString.substring(3));
            });
          },
        );
      } else {
// Stop Session
        NfcManager.instance.stopSession();
      }
      setState(() {
        listenerRunning = !listenerRunning;
      });
    }
  }

  final TextEditingController _controller = TextEditingController();
  final List list = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          ElevatedButton(
            onPressed: _listenForNFC,
            child: Text(!listenerRunning ? 'start listen' : 'stop'),
          ),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyHceSreen(),
                    ));
              },
              child: const Text('host')),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('NFC availability : $isNfcAvalible'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration:
                      const InputDecoration(hintText: 'Enter text here'),
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Write'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: list.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(list[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Helper method to show a quick message
  void _alert(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        duration: const Duration(
          seconds: 2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      NfcManager.instance.stopSession();
    } catch (_) {
      //We dont care
    }
    super.dispose();
  }
}
