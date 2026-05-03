package com.telebank.sms

import android.content.Context
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

class SmsObserver(
  private val context: Context,
  private val sink: EventChannel.EventSink
) : ContentObserver(Handler(Looper.getMainLooper())) {

  private var lastId: String? = null

  fun start() {
    context.contentResolver.registerContentObserver(
      Uri.parse("content://sms"),
      true,
      this
    )
    emitLatest()
  }

  fun stop() {
    context.contentResolver.unregisterContentObserver(this)
  }

  override fun onChange(selfChange: Boolean) {
    super.onChange(selfChange)
    emitLatest()
  }

  private fun emitLatest() {
    val cursor = context.contentResolver.query(
      Uri.parse("content://sms/inbox"),
      arrayOf("_id", "address", "body", "date"),
      null,
      null,
      "date DESC"
    ) ?: return

    cursor.use {
      if (!it.moveToFirst()) return
      val id = it.getString(0) ?: return
      if (id == lastId) return
      lastId = id
      val sender = it.getString(1) ?: ""
      val body = it.getString(2) ?: ""
      val timestamp = it.getLong(3)
      val payload = mapOf(
        "sender" to sender,
        "body" to body,
        "timestamp" to timestamp
      )
      sink.success(payload)
    }
  }
}
