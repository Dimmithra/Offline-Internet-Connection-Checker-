package com.example.network_check_app

import android.net.TrafficStats
import android.os.Handler
import android.os.Looper
import android.annotation.SuppressLint
import io.flutter.embedding.android.FlutterActivity
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Bundle
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.jar.Manifest
import android.telephony.TelephonyManager
class MainActivity: FlutterActivity() {
  private val CHANNEL = "com.example.network_check_app/connectivity"
  private val REQUEST_CODE = 101
  private var totalTxBytes: Long = 0
  private var totalRxBytes: Long = 0
  private var lastUpdateTime: Long = 0
override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
  super.configureFlutterEngine(flutterEngine)
  MethodChannel(
    flutterEngine.dartExecutor.binaryMessenger,
    CHANNEL
  ).setMethodCallHandler { call, result ->
    when (call.method) {
      "checkInternetConnection" -> {
        val isConnected = isInternetAvailable()
        result.success(isConnected)
      }
      "getNetworkInfo" -> {
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED) {
          val networkInfo = getNetworkInfo()
          result.success(networkInfo)
        } else {
          ActivityCompat.requestPermissions(this, arrayOf(android.Manifest.permission.READ_PHONE_STATE), REQUEST_CODE)
          result.error("PERMISSION_DENIED", "Permission denied to read phone state", null)
        }
      }
      "startMonitoringNetworkSpeed" -> {
        startNetworkSpeedMonitoring()
        result.success(true)
      }
      "stopMonitoringNetworkSpeed" -> {
        stopNetworkSpeedMonitoring()
        result.success(true)
      }
      else -> result.notImplemented()
    }
  }
}
  private fun isInternetAvailable(): Boolean {
    val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      val network = connectivityManager.activeNetwork ?: return false
      val activeNetwork = connectivityManager.getNetworkCapabilities(network) ?: return false
      return when {
        activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> true
        activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> true
        activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> true
        else -> false
      }
    } else {
      @Suppress("DEPRECATION")
      val networkInfo = connectivityManager.activeNetworkInfo ?: return false
      @Suppress("DEPRECATION")
      return networkInfo.isConnected
    }
  }

  //service provider
  @SuppressLint("SuspiciousIndentation")
  private fun getNetworkInfo(): String {
    val telephonyManager = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
    val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    val networkOperatorName = telephonyManager.networkOperatorName
    val simOperatorName = telephonyManager.simOperatorName
    val simCountryIso = telephonyManager.simCountryIso
    val networkCountryIso = telephonyManager.networkCountryIso
    val networkType = getNetworkType(connectivityManager)

        return "Network Operator: $networkOperatorName\n" +
               "SIM Operator: $simOperatorName\n" +
               "SIM Country ISO: $simCountryIso\n" +
               "Network Country ISO: $networkCountryIso\n" +
               "Network Type: $networkType"  }

  //network type
  private fun getNetworkType(connectivityManager: ConnectivityManager): String {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      val network = connectivityManager.activeNetwork ?: return "No Network"
      val activeNetwork = connectivityManager.getNetworkCapabilities(network) ?: return "No Network"
      return when {
        activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "WiFi"
        activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "Cellular"
        activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "Ethernet"
        else -> "Unknown"
      }
    } else {
      @Suppress("DEPRECATION")
      val networkInfo = connectivityManager.activeNetworkInfo ?: return "No Network"
      @Suppress("DEPRECATION")
      return when (networkInfo.type) {
        ConnectivityManager.TYPE_WIFI -> "WiFi"
        ConnectivityManager.TYPE_MOBILE -> "Cellular"
        ConnectivityManager.TYPE_ETHERNET -> "Ethernet"
        else -> "Unknown"
      }
    }
  }

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    if (requestCode == REQUEST_CODE && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
      // Permission granted, you can retry fetching the network info
      flutterEngine?.dartExecutor?.binaryMessenger?.let { MethodChannel(it, CHANNEL).invokeMethod("getNetworkInfo", null) }
    }
  }

  //network speed moitorking
  private fun startNetworkSpeedMonitoring() {
    totalTxBytes = TrafficStats.getTotalTxBytes()
    totalRxBytes = TrafficStats.getTotalRxBytes()
    lastUpdateTime = System.currentTimeMillis()

    val handler = Handler(Looper.getMainLooper())
    handler.postDelayed(object : Runnable {
      override fun run() {
        val currentTxBytes = TrafficStats.getTotalTxBytes()
        val currentRxBytes = TrafficStats.getTotalRxBytes()
        val currentTime = System.currentTimeMillis()

        val txSpeed = ((currentTxBytes - totalTxBytes) * 1000 / (currentTime - lastUpdateTime)).toFloat()
        val rxSpeed = ((currentRxBytes - totalRxBytes) * 1000 / (currentTime - lastUpdateTime)).toFloat()

        totalTxBytes = currentTxBytes
        totalRxBytes = currentRxBytes
        lastUpdateTime = currentTime

        flutterEngine?.dartExecutor?.binaryMessenger?.let {
          MethodChannel(it, CHANNEL).invokeMethod("updateNetworkSpeed", mapOf(
            "txSpeed" to txSpeed,
            "rxSpeed" to rxSpeed
          ))
        }

        handler.postDelayed(this, 1000) // Update speed every second
      }
    }, 1000) // Start monitoring after 1 second delay
  }

  private fun stopNetworkSpeedMonitoring() {
    // Stop any ongoing monitoring tasks
  }

}
