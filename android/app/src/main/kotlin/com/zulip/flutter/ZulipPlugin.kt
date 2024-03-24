package com.zulip.flutter

import android.util.Log
import androidx.annotation.Keep
import io.flutter.embedding.engine.plugins.FlutterPlugin

private const val TAG = "ZulipPlugin"

/** A Flutter plugin for the Zulip app's ad-hoc needs. */
// @Keep is needed because this class is used only
// from ZulipShimPlugin, via reflection.
@Keep
class ZulipPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Attaching to Flutter engine.")
        // For the moment, this is a vacuous placeholder plugin.
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }
}
