import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;

class NetworkResultScreen extends StatefulWidget {
  const NetworkResultScreen({super.key});

  @override
  State<NetworkResultScreen> createState() => _NetworkResultScreenState();
}

class _NetworkResultScreenState extends State<NetworkResultScreen> {
  static const platform =
      MethodChannel('com.example.network_check_app/connectivity');
  String _networkInfo = 'Unknown network info.';
  String _connectionStatus = 'Unknown';
  double _txSpeed = 0.0;
  double _rxSpeed = 0.0;
  @override
  void initState() {
    super.initState();
    loadData();
    _startMonitoringNetworkSpeed();
  }

  Future<void> _checkInternetConnection() async {
    String connectionStatus;
    try {
      final bool result =
          await platform.invokeMethod('checkInternetConnection');
      connectionStatus = result ? 'Connected' : 'Disconnected';
    } on PlatformException catch (e) {
      connectionStatus = "Failed to get connectivity: '${e.message}'.";
    }

    if (!mounted) return;

    setState(() {
      _connectionStatus = connectionStatus;
    });
  }

  Future<void> _getNetworkInfo() async {
    String networkInfo;
    try {
      dev.log("Status: $_connectionStatus");
      final String result = await platform.invokeMethod('getNetworkInfo');
      networkInfo = result;
    } on PlatformException catch (e) {
      networkInfo = "Failed to get network info: '${e.message}'.";
    }

    setState(() {
      _networkInfo = networkInfo;
    });
  }

  Future<void> _getNetworkType() async {
    String networkInfo;
    try {
      dev.log("Status: $_connectionStatus");
      final String result = await platform.invokeMethod('getNetworkType');
      networkInfo = result;
    } on PlatformException catch (e) {
      networkInfo = "Failed to get network info: '${e.message}'.";
    }

    setState(() {
      _networkInfo = networkInfo;
    });
  }

  void _startMonitoringNetworkSpeed() async {
    try {
      await platform.invokeMethod('startMonitoringNetworkSpeed');
      platform.setMethodCallHandler((call) async {
        // Make the callback async
        if (call.method == 'updateNetworkSpeed') {
          setState(() {
            _txSpeed = call.arguments['txSpeed'];
            _rxSpeed = call.arguments['rxSpeed'];
          });
        }
        return null; // Return a Future<dynamic> explicitly
      });
    } on PlatformException catch (e) {
      print('Failed to start monitoring network speed: ${e.message}');
    }
  }

  void _stopMonitoringNetworkSpeed() async {
    try {
      await platform.invokeMethod('stopMonitoringNetworkSpeed');
    } on PlatformException catch (e) {
      print('Failed to stop monitoring network speed: ${e.message}');
    }
  }

  Future<void> loadData() async {
    _checkInternetConnection();
    _getNetworkInfo();
    _getNetworkType();
    // _startMonitoringNetworkSpeed();
  }

  @override
  void dispose() {
    _stopMonitoringNetworkSpeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.greenAccent,
        title: Text(
          'Internet Connection Check',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Network Status",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  _connectionStatus == "Connected"
                      ? Text(
                          ' $_connectionStatus',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold),
                        )
                      : Text(
                          ' $_connectionStatus',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                "$_networkInfo",
                textAlign: TextAlign.start,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text('Transmit Speed: $_txSpeed bytes/s'),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text('Receive Speed: $_rxSpeed bytes/s'),
            ),
          ],
        ),
      ),
    );
  }
}
