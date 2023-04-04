import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:nfc_host_card_emulation/nfc_host_card_emulation.dart';

class MyHceSreen extends StatefulWidget {
  const MyHceSreen({super.key});

  @override
  State<MyHceSreen> createState() => _MyHceSreenState();
}

class _MyHceSreenState extends State<MyHceSreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await NfcHce.init(
            // AID that match at least one aid-filter in apduservice.xml.
            // In my case it is A000DADADADADA.
            aid: Uint8List.fromList([0xA0, 0x02, 0xDA, 0xDA, 0xDA, 0xDA, 0xDA]),

            // next parameter determines whether APDU responses from the ports
            // on which the connection occurred will be deleted.
            // If `true`, responses will be deleted, otherwise won't.
            permanentApduResponses: true,

            // next parameter determines whether APDU commands received on ports
            // to which there are no responses will be added to the stream.
            // If `true`, command won't be added, otherwise will.
            listenOnlyConfiguredPorts: false,
          );
        },
      ),
    );
  }
}
