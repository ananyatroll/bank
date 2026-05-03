package com.telebank.ussd

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.EventChannel

class UssdAccessibilityService : AccessibilityService() {

  override fun onServiceConnected() {
    serviceInfo = serviceInfo.apply {
      eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
      feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
      notificationTimeout = 200
      flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
        AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
    }
  }

  override fun onAccessibilityEvent(event: AccessibilityEvent) {
    val root = rootInActiveWindow ?: return
    lastRoot = root
    val text = extractText(root)
    if (text.isNotBlank() && text != lastText) {
      lastText = text
      emit(text)
    }
  }

  override fun onInterrupt() {
    // No-op.
  }

  private fun extractText(node: AccessibilityNodeInfo): String {
    val sb = StringBuilder()
    collectText(node, sb)
    return sb.toString().trim()
  }

  private fun collectText(node: AccessibilityNodeInfo, sb: StringBuilder) {
    val nodeText = node.text?.toString()?.trim().orEmpty()
    if (nodeText.isNotEmpty()) {
      if (sb.isNotEmpty()) sb.append("\n")
      sb.append(nodeText)
    }
    for (i in 0 until node.childCount) {
      val child = node.getChild(i) ?: continue
      collectText(child, sb)
    }
  }

  companion object {
    private var eventSink: EventChannel.EventSink? = null
    private var lastText: String = ""
    private var lastRoot: AccessibilityNodeInfo? = null

    fun setEventSink(sink: EventChannel.EventSink?) {
      eventSink = sink
    }

    private fun emit(text: String) {
      val payload = mapOf(
        "text" to text,
        "timestamp" to System.currentTimeMillis()
      )
      eventSink?.success(payload)
    }

    fun sendInput(input: String): Boolean {
      val root = lastRoot ?: return false
      val editable = findEditable(root) ?: return false
      val args = Bundle()
      args.putCharSequence(
        AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
        input
      )
      val setOk = editable.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
      if (!setOk) return false
      val button = findButton(root, listOf("Send", "OK", "Ok", "Confirm"))
      return button?.performAction(AccessibilityNodeInfo.ACTION_CLICK) ?: true
    }

    fun dismissUssd(): Boolean {
      val root = lastRoot ?: return false
      val button = findButton(root, listOf("Cancel", "Dismiss", "Close"))
      return button?.performAction(AccessibilityNodeInfo.ACTION_CLICK) ?: false
    }

    private fun findEditable(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
      if (node.isEditable) return node
      for (i in 0 until node.childCount) {
        val child = node.getChild(i) ?: continue
        val result = findEditable(child)
        if (result != null) return result
      }
      return null
    }

    private fun findButton(
      node: AccessibilityNodeInfo,
      labels: List<String>
    ): AccessibilityNodeInfo? {
      val text = node.text?.toString() ?: ""
      if (labels.any { it.equals(text, ignoreCase = true) }) return node
      for (i in 0 until node.childCount) {
        val child = node.getChild(i) ?: continue
        val result = findButton(child, labels)
        if (result != null) return result
      }
      return null
    }
  }
}
