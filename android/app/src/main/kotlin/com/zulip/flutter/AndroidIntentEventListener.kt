package com.zulip.flutter

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns

class AndroidIntentEventListener : AndroidIntentEventsStreamHandler() {
  private var eventSink: PigeonEventSink<AndroidIntentEvent>? = null
  private val buffer = mutableListOf<AndroidIntentEvent>()

  override fun onListen(p0: Any?, sink: PigeonEventSink<AndroidIntentEvent>) {
    eventSink = sink
    buffer.forEach { eventSink!!.success(it) }
  }

  private fun onEvent(event: AndroidIntentEvent) {
    if (eventSink != null) {
      eventSink?.success(event)
    } else {
      buffer.add(event)
    }
  }

  fun handleSend(context: Context, intent: Intent) {
    val intentAction = intent.action
    assert(
      intentAction == Intent.ACTION_SEND
          || intentAction == Intent.ACTION_SEND_MULTIPLE
    )

    // EXTRA_TEXT and EXTRA_STREAM are the text and file components of the
    // content, respectively. The ACTION_SEND{,_MULTIPLE} docs say
    // "either" / "or" will be present:
    //   https://developer.android.com/reference/android/content/Intent#ACTION_SEND
    // But empirically both can be present, commonly, so we accept that form,
    // interpreting it as an intent to share both kinds of data.
    //
    // Empirically, sometimes EXTRA_TEXT isn't something we think needs to be
    // shared, like the URL of a file that's present in EXTRA_STREAM… but we
    // shrug and include it anyway because we don't want to second-guess other
    // apps' decisions about what to include; it's their responsibility.

    val extraText = intent.getStringExtra(Intent.EXTRA_TEXT)
    val extraStream = when (intentAction) {
      Intent.ACTION_SEND -> {
        var extraStream: List<IntentSharedFile>? = null
        // TODO(android-sdk-33) Remove the use of deprecated API.
        @Suppress("DEPRECATION") val url = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
        if (url != null) {
          extraStream = listOf(getIntentSharedFile(context, url))
        }
        extraStream
      }

      Intent.ACTION_SEND_MULTIPLE -> {
        var extraStream: MutableList<IntentSharedFile>? = null
        // TODO(android-sdk-33) Remove the use of deprecated API.
        @Suppress("DEPRECATION") val urls =
          intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
        if (urls != null) {
          extraStream = mutableListOf()
          for (url in urls) {
            val sharedFile = getIntentSharedFile(context, url)
            extraStream.add(sharedFile)
          }
        }
        extraStream
      }

      else -> throw IllegalArgumentException("Unexpected value for intent.action: $intentAction")
    }

    if (extraText == null && extraStream == null) {
      throw Exception("Got unexpected ACTION_SEND* intent, with neither EXTRA_TEXT nor EXTRA_STREAM")
    }

    onEvent(
      AndroidIntentSendEvent(
        action = intentAction,
        extraText = extraText,
        extraStream = extraStream,
      )
    )
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
