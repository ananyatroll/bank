package com.telebank

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.telebank.sms.SmsObserver
import com.telebank.ussd.UssdAccessibilityService

class MainActivity : FlutterActivity() {
  private var smsObserver: SmsObserver? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    EventChannel(flutterEngine.dartExecutor.binaryMessenger, "telebank/sms_events")
      .setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
          if (events == null) return
          smsObserver = SmsObserver(this@MainActivity, events)
          smsObserver?.start()
        }

        override fun onCancel(arguments: Any?) {
          smsObserver?.stop()
          smsObserver = null
        }
      })

    EventChannel(flutterEngine.dartExecutor.binaryMessenger, "telebank/ussd_events")
      .setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
          UssdAccessibilityService.setEventSink(events)
        }

        override fun onCancel(arguments: Any?) {
          UssdAccessibilityService.setEventSink(null)
        }
      })

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "telebank/ussd_call")
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "dialUssd" -> {
            val code = call.argument<String>("code") ?: ""
            val useCall = call.argument<Boolean>("useCall") ?: false
            if (code.isBlank()) {
              result.error("BAD_ARGS", "Empty USSD code", null)
              return@setMethodCallHandler
            }
            dialUssd(code, useCall)
            result.success(true)
          }
          "sendInput" -> {
            val input = call.argument<String>("input") ?: ""
            val ok = UssdAccessibilityService.sendInput(input)
            result.success(ok)
          }
          "dismissUssd" -> {
            UssdAccessibilityService.dismissUssd()
            result.success(true)
          }
          else -> result.notImplemented()
        }
      }

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "telebank/device_security")
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "isDeviceSecure" -> {
            val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            result.success(keyguard.isDeviceSecure)
          }
          "openSecuritySettings" -> {
            val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            result.success(true)
          }
          else -> result.notImplemented()
        }
      }
  }

  private fun dialUssd(code: String, useCall: Boolean) {
    val uri = Uri.parse("tel:${Uri.encode(code)}")
    val intent = Intent(if (useCall) Intent.ACTION_CALL else Intent.ACTION_DIAL, uri)
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    startActivity(intent)
  }
}
