import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import FlutterSecureStorage

import 'HomeScreen.dart';
import 'WebViewApp.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key); // Corrected constructor

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  final storage = const FlutterSecureStorage(); // Create an instance of FlutterSecureStorage

  // To get token from local storage
  Future<String?> getToken() async {
    var value = await storage.read(key: 'token');
    return value; // Return the token value
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: getToken(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              final token = snapshot.data;
              final url = 'https://devapp.qcomm.co/$token'; // Modify URL as needed
              return WebView(
                initialUrl: url,
                javascriptMode: JavascriptMode.unrestricted,
                onWebViewCreated: (WebViewController webViewController) {
                  _controller.complete(webViewController);
                },
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 0,
        child: SizedBox(
          height: 35,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.dashboard, color: Color.fromRGBO(1, 135, 134, 1)), // Set icon color
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                tooltip: 'Dashboard',
              ),
              IconButton(
                icon: const Icon(Icons.account_circle, color: Color.fromRGBO(1, 135, 134, 1)), // Set icon color
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WebViewApp()),
                  );
                },
                tooltip: 'Account',
              ),
              IconButton(
                icon: const Icon(Icons.history, color: Color.fromRGBO(1, 135, 134, 1)), // Set icon color
                onPressed: () async { 
                  // Call getToken() to get the token
                  String? token = await getToken();
                  
                  print("Token: $token");
                },
                tooltip: 'History',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
