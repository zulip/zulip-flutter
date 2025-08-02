package com.zulip.flutter

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns

class IntentListener : AndroidIntentEventsStreamHandler() {
  private var eventSink: PigeonEventSink<AndroidIntentEvent>? = null
  private val buffer = mutableListOf<AndroidIntentEvent>()

  override fun onListen(p0: Any?, sink: PigeonEventSink<AndroidIntentEvent>) {
    eventSink = sink
    buffer.forEach { eventSink!!.success(it) }
  }

  private fun onAndroidIntentEvent(event: AndroidIntentEvent) {
    if (eventSink != null) {
      eventSink?.success(event)
    } else {
      buffer.add(event)
    }
  }

  fun handleSend(context: Context, intent: Intent) {
    assert(
      intent.action == Intent.ACTION_SEND
          || intent.action == Intent.ACTION_SEND_MULTIPLE
    )

    // App can receive both an EXTRA_TEXT and EXTRA_STREAM (files)
    // in the same intent. And the documentation states that EXTRA_TEXT
    // should always be "text/plain", and it also states that it can be
    // a mime type of the file/s in EXTRA_STREAM, but while testing
    // Chrome seems to always set this as the source URL for the shared
    // image, and Firefox sets this to null when sharing an image.
    // So, we use this string as-is, assuming the documented later part
    // isn't observed in the wild.
    //
    // See: https://developer.android.com/reference/android/content/Intent#ACTION_SEND
    val extraText = intent.getStringExtra(Intent.EXTRA_TEXT)

    val event = when (intent.action) {
      Intent.ACTION_SEND -> {
        if ("text/plain" == intent.type) {
          AndroidIntentSendEvent(
            action = Intent.ACTION_SEND,
            extraText = extraText
          )
        } else {
          // TODO(android-sdk-33) Remove the use of deprecated API.
          @Suppress("DEPRECATION") val url = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            ?: throw Exception("Could not extract URL from File Intent")
          val sharedFile = getIntentSharedFile(context, url)
          AndroidIntentSendEvent(
            action = Intent.ACTION_SEND,
            extraText = extraText,
            extraStream = listOf(sharedFile)
          )
        }
      }

      Intent.ACTION_SEND_MULTIPLE -> {
        // TODO(android-sdk-33) Remove the use of deprecated API.
        @Suppress("DEPRECATION") val urls =
          intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
            ?: throw Exception("Could not extract URLs from File Intent")
        val extraStream = mutableListOf<IntentSharedFile>()
        for (url in urls) {
          val sharedFile = getIntentSharedFile(context, url)
          extraStream.add(sharedFile)
        }
        AndroidIntentSendEvent(
          action = Intent.ACTION_SEND_MULTIPLE,
          extraText = extraText,
          extraStream = extraStream
        )
      }

      else -> throw IllegalArgumentException("Unexpected value for intent.action: ${intent.action}")
    }

    onAndroidIntentEvent(event)
  }
}

// A helper function to retrieve the shared file from the `content://` URL
// from the ACTION_SEND{_MULTIPLE} intent.
fun getIntentSharedFile(context: Context, url: Uri): IntentSharedFile {
  val contentResolver = context.contentResolver
  val mimeType = contentResolver.getType(url)
  val name = contentResolver.query(url, null, null, null, null)?.use { cursor ->
    cursor.moveToFirst()
    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
    cursor.getString(nameIndex)
  } ?: ("unknown." + (mimeType?.split('/')?.last() ?: "bin"))

  class ResolverFailedException(msg: String) : RuntimeException(msg)

  val bytes = (contentResolver.openInputStream(url)
    ?: throw ResolverFailedException("resolver.open… failed"))
    .use { inputStream ->
      inputStream.readBytes()
    }

  return IntentSharedFile(
    name = name,
    mimeType = mimeType,
    bytes = bytes
  )
}
