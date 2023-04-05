package com.example.nfc_sample

import io.flutter.embedding.android.FlutterActivity
import kotlin.random.Random

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;
import android.widget.EditText;
import android.widget.TextView;

import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.nfc_sample/hce"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
      call, result ->
      if (call.method == "startHce") {
          val text = call.argument<String>("text")
        val hceStatus = startCardService(context,text?:"hello")

        if (hceStatus) {
          result.success(hceStatus)
        } else {
          result.error("UNAVAILABLE", "Battery level not available.", null)
        }
      } else {
        result.notImplemented()
      }
    }
  }

    fun startCardService(context: Context, text: String): Boolean {
        val pm = context.packageManager
        if (pm.hasSystemFeature(PackageManager.FEATURE_NFC_HOST_CARD_EMULATION)) {
            val intent = Intent(context, CardService::class.java).apply {
                putExtra("ndefMessage", text)
            }

            return context.startService(intent) != null
        }
        return false
    }


}
