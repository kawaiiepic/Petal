package com.example.petal

import android.os.StatFs
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "petal/network").setMethodCallHandler { call, result ->
            if (call.method != "wifi") result.notImplemented()
            else {
                val manager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                val capabilities = manager.getNetworkCapabilities(manager.activeNetwork)
                result.success(capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true)
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "petal/storage").setMethodCallHandler { call, result ->
            if (call.method != "freeBytes") { result.notImplemented() }
            else {
                try {
                    val path = call.argument<String>("path") ?: filesDir.path
                    result.success(StatFs(path).availableBytes)
                } catch (error: Exception) { result.error("storage", error.message, null) }
            }
        }
    }
}
