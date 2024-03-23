package com.zulip.flutter

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.annotation.Keep
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin

private const val TAG = "ZulipPlugin"

private class AndroidNotificationHost(val context: Context)
        : AndroidNotificationHostApi {
    @SuppressLint(
        // If permission is missing, `notify` will throw an exception.
        // Which hopefully will propagate to Dart, and then it's up to Dart code to handle it.
        "MissingPermission",
        // For `getIdentifier`.  TODO make a cleaner API.
        "DiscouragedApi")
    override fun notify(
        tag: String?,
        id: Long,
        channelId: String,
        color: Long?,
        contentIntent: PendingIntent?,
        contentText: String?,
        contentTitle: String?,
        extras: Map<String?, String?>?,
        smallIconResourceName: String?
    ) {
        val notification = NotificationCompat.Builder(context, channelId).apply {
            color?.let { setColor(it.toInt()) }
            contentIntent?.let { setContentIntent(
                android.app.PendingIntent.getActivity(context,
                    it.requestCode.toInt(),
                    Intent(context, MainActivity::class.java).apply {
                        // This action name and extra name are special to
                        // FlutterLocalNotificationsPlugin, which handles receiving the Intent.
                        // TODO take care of receiving the notification-opened Intent ourselves
                        action = "SELECT_NOTIFICATION"
                        putExtra("payload", it.intentPayload)
                    },
                    it.flags.toInt())
            ) }
            contentText?.let { setContentText(it) }
            contentTitle?.let { setContentTitle(it) }
            extras?.let { setExtras(
                Bundle().apply { it.forEach { (k, v) -> putString(k, v) } } ) }
            smallIconResourceName?.let { setSmallIcon(context.resources.getIdentifier(
                it, "drawable", context.packageName)) }
        }.build()
        NotificationManagerCompat.from(context).notify(tag, id.toInt(), notification)
    }
}

/** A Flutter plugin for the Zulip app's ad-hoc needs. */
// @Keep is needed because this class is used only
// from ZulipShimPlugin, via reflection.
@Keep
class ZulipPlugin : FlutterPlugin { // TODO ActivityAware too?
    private var notificationHost: AndroidNotificationHost? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Attaching to Flutter engine.")
        notificationHost = AndroidNotificationHost(binding.applicationContext)
        AndroidNotificationHostApi.setUp(binding.binaryMessenger, notificationHost)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (notificationHost == null) {
            Log.wtf(TAG, "Already detached from the engine.")
            return
        }
        AndroidNotificationHostApi.setUp(binding.binaryMessenger, null)
        notificationHost = null
    }
}
