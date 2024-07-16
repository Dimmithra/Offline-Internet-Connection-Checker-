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

  @override
  void initState() {
    super.initState();
    loadData();
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
      final String result = await  platform.invokeMethod('getNetworkType');
      networkInfo = result;
    } on PlatformException catch (e) {
      networkInfo = "Failed to get network info: '${e.message}'.";
    }

    setState(() {
      _networkInfo = networkInfo;
    });
  }

  Future<void> loadData() async {
    _checkInternetConnection();
    _getNetworkInfo();
    _getNetworkType();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Internet Connection Check'),
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
                    style: TextStyle(fontSize: 18),
                  ),
                  _connectionStatus == "Connected"
                      ? Text(
                          ' $_connectionStatus',
                          style: TextStyle(fontSize: 18, color: Colors.blue),
                        )
                      : Text(
                          ' $_connectionStatus',
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () {
            //     setState(() {
            //       dev.log("data $_networkInfo");
            //     });
            //   },
            //   // child: Text("Log Data"),
            // ),
            SizedBox(height: 20),
            Text(
              "Data: $_networkInfo",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
