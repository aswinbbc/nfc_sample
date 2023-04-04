import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_host_card_emulation/nfc_host_card_emulation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:convert' show utf8;

import 'package:nfc_manager/platform_tags.dart';
import 'package:nfc_sample/nfc_test.dart';

/// Global flag if NFC is avalible
bool isNfcAvalible = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for the line below
  isNfcAvalible = await NfcManager.instance.isAvailable();
  runApp(MyApp());
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

  void _ndefWrite() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        print('@#Tag is not ndef writable');
        NfcManager.instance.stopSession();
        return;
      }

      try {
        NdefMessage message = NdefMessage([
          // NdefRecord.createText(controller.text),
          // NdefRecord.createUri(Uri.parse('https://flutter.dev')),
          NdefRecord.createMime(
              'text/plain', Uint8List.fromList(controller.text.codeUnits)),
          // NdefRecord.createExternal(
          //   'com.example',
          //   'mytype',
          //   Uint8List.fromList('mydata'.codeUnits),
          // ),
        ]);
        await ndef.write(message);
        print({'@#success': 'Success to "Ndef Write"'});
        NfcManager.instance.stopSession();
      } catch (e) {
        print({'@#error': e});
        NfcManager.instance.stopSession(errorMessage: e.toString());
        return;
      }
    });
  }

  Future<void> _writeInNFC() {
    final completer = Completer<void>();
    NfcManager.instance.startSession(
      onDiscovered: (tag) async {
        final ndef = Ndef.from(tag);
        final formattable = NdefFormatable.from(tag);
        final message = NdefMessage([NdefRecord.createText(_controller.text)]);
        if (ndef != null) {
          await ndef.write(message);
        } else if (formattable != null) {
          await formattable.format(message);
        }
        await NfcManager.instance.stopSession();
        completer.complete();
      },
      onError: (error) async => completer.completeError(error),
    );
    return completer.future;
  }

  final TextEditingController _controller = TextEditingController();
  final List list = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [
        ElevatedButton(
            onPressed: _listenForNFC,
            child: Text(!listenerRunning ? 'start listen' : 'stop')),
        ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyHceSreen(),
                  ));
            },
            child: Text('host')),
      ]),
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('NFC availability : $isNfcAvalible'),
            // Row(
            //   children: [
            //     Expanded(
            //       child: TextField(
            //         controller: _controller,
            //         decoration: InputDecoration(hintText: 'Enter text here'),
            //       ),
            //     ),
            //     ElevatedButton(onPressed: _ndefWrite, child: Text('Write')),

            //   ],
            // ),
            ElevatedButton(
                onPressed: () {
                  NfcHce.stream.listen((command) {
                    print(command);
                  });
                },
                child: Text('hce listen')),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (context, index) =>
                    ListTile(title: Text(list[index])),
              ),
            ),
          ]),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: "Enter text here.")),
            ),
            _getNfcWidgets(),
          ],
        ),
      ),
    );
  }

  Widget _getNfcWidgets() {
    if (isNfcAvalible) {
      //For ios always false, for android true if running
      final nfcRunning = Platform.isAndroid && listenerRunning;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: nfcRunning ? null : _listenForNFCEvents,
            child: Text(Platform.isAndroid
                ? listenerRunning
                    ? 'NFC is running'
                    : 'Start NFC listener'
                : 'Read from tag'),
          ),
          TextButton(
            onPressed: _writeNfcTag,
            child: Text(writeCounterOnNextContact
                ? 'Waiting for tag to write'
                : 'Write to tag'),
          ),
        ],
      );
    } else {
      if (Platform.isIOS) {
        //Ios doesnt allow the user to turn of NFC at all,  if its not avalible it means its not build in
        return const Text("Your device doesn't support NFC");
      } else {
        //Android phones can turn of NFC in the settings
        return const Text(
            "Your device doesn't support NFC or it's turned off in the system settings");
      }
    }
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

  Future<void> _listenForNFCEvents() async {
    //Always run this for ios but only once for android
    if (Platform.isAndroid && listenerRunning == false || Platform.isIOS) {
      //Android supports reading nfc in the background, starting it one time is all we need
      if (Platform.isAndroid) {
        _alert(
          'NFC listener running in background now, approach tag(s)',
        );
        //Update button states
        setState(() {
          listenerRunning = true;
        });
      } else {
        NfcManager.instance.stopSession();
        setState(() {
          listenerRunning = false;
        });
        return;
      }

      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          bool succses = false;
          //Try to convert the raw tag data to NDEF
          final ndefTag = Ndef.from(tag);
          //If the data could be converted we will get an object
          if (ndefTag != null) {
            //Create a 1Well known tag with en as language code and 0x02 encoding for UTF8
            final ndefRecord =
                NdefRecord.createText(controller.text, languageCode: 'en');
            //Create a new ndef message with a single record
            final ndefMessage = NdefMessage([ndefRecord]);
            //Write it to the tag, tag must still be "connected" to the device
            try {
              //Any existing content will be overrwirten
              await ndefTag.write(ndefMessage);
              _alert('Counter written to tag');
              succses = true;
            } catch (e) {
              _alert("Writting failed, press 'Write to tag' again");
            }
            // If we want to write the current counter vlaue we will replace the current content on the tag
            // if (writeCounterOnNextContact) {
            //   //Ensure the write flag is off again
            //   setState(() {
            //     writeCounterOnNextContact = false;
            //   });

            // }
            // //The NDEF Message was already parsed, if any
            // else if (ndefTag.cachedMessage != null) {
            //   var ndefMessage = ndefTag.cachedMessage!;
            //   //Each NDEF message can have multiple records, we will use the first one in our example
            //   if (ndefMessage.records.isNotEmpty &&
            //       ndefMessage.records.first.typeNameFormat ==
            //           NdefTypeNameFormat.nfcWellknown) {
            //     //If the first record exists as 1:Well-Known we consider this tag as having a value for us
            //     final wellKnownRecord = ndefMessage.records.first;

            //     ///Payload for a 1:Well Known text has the following format:
            //     ///[Encoding flag 0x02 is UTF8][ISO language code like en][content]

            //     if (wellKnownRecord.payload.first == 0x02) {
            //       //Now we know the encoding is UTF8 and we can skip the first byte
            //       final languageCodeAndContentBytes =
            //           wellKnownRecord.payload.skip(1).toList();
            //       //Note that the language code can be encoded in ASCI, if you need it be carfully with the endoding
            //       final languageCodeAndContentText =
            //           utf8.decode(languageCodeAndContentBytes);
            //       //Cutting of the language code
            //       final payload = languageCodeAndContentText.substring(2);
            //       //Parsing the content to int

            //       if (payload.isNotEmpty) {
            //         succses = true;
            //         _alert('Counter restored from tag');
            //         setState(() {
            //           controller.text = payload;
            //         });
            //       }
            //     }
            //   }
            // }
          }
          //Due to the way ios handles nfc we need to stop after each tag
          if (Platform.isIOS) {
            NfcManager.instance.stopSession();
          }
          if (succses == false) {
            _alert(
              'Tag was not valid',
            );
          }
        },
        // Required for iOS to define what type of tags should be noticed
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
      );
    }
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

  void _writeNfcTag() {
    setState(() {
      writeCounterOnNextContact = true;
    });

    if (Platform.isAndroid) {
      _alert('Approach phone with tag');
    }
    //Writing a requires to read the tag first, on android this call might do nothing as the listner is already running
    _listenForNFCEvents();
  }
}
