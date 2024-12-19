package com.zulip.flutter

import android.media.MediaScannerConnection
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// MainActivity extends FlutterActivity and sets up communication between Flutter and native Android
class MainActivity : FlutterActivity() {

    // Define a channel name for communication between Flutter and native Android
    private val CHANNEL = "gallery_saver"

    // Override the configureFlutterEngine method to set up the MethodChannel and handle method calls
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up a method channel for communication between Flutter and native Android code
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->

            // Handle the method call when the "scanFile" method is invoked from Flutter
            if (call.method == "scanFile") {
                // Get the file path passed from Flutter
                val filePath = call.argument<String>("path")

                // Check if the file path is not null
                if (filePath != null) {
                    // If the file path is valid, trigger the scanning of the file
                    scanFile(filePath)
                    // Return a success result back to Flutter indicating the file was scanned
                    result.success("MediaScanner invoked for $filePath")
                } else {
                    // If the file path is null, return an error to Flutter
                    result.error("INVALID_ARGUMENT", "File path is null", null)
                }
            } else {
                // If the method called is not recognized, return not implemented error
                result.notImplemented()
            }
        }
    }

    // This function triggers the Android MediaScanner to refresh the media library
    // so that the file is visible in the gallery or other media apps.
    private fun scanFile(filePath: String) {
        // Use the MediaScannerConnection to scan the file and add it to the device's media library
        MediaScannerConnection.scanFile(
            applicationContext,
            arrayOf(filePath),  // File to be scanned
            null,  // File MIME types can be specified here, or null if it's unknown
            // Callback function when the scanning is complete (empty in this case)
        ) { _, _ ->
            // Intentionally left empty, but could be used to log success or handle errors
        }
    }
}
