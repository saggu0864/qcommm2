import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qcommm2/main.dart';
import 'History.dart';
import 'HomeScreen.dart';

void main() {
  runApp(
    const MaterialApp(
      home: WebViewApp(),
    ),
  );
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({Key? key}) : super(key: key);

  @override
  _WebViewAppState createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  final storage = const FlutterSecureStorage();
  bool _isUnobtrusiveMode = false;
  bool _isNotificationSoundOn = true;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUsername();
  }

  Future<void> _loadSettings() async {
    String? unobtrusiveMode = await storage.read(key: 'unobtrusive_mode');
    String? notificationSound = await storage.read(key: 'notification_sound');
    setState(() {
      _isUnobtrusiveMode = unobtrusiveMode == 'true';
      _isNotificationSoundOn = notificationSound != 'false';
    });
  }

  Future<void> _loadUsername() async {
    String? username = await storage.read(key: 'username');
    setState(() {
      _username = username ?? '';
    });
  }

  Future<void> _toggleUnobtrusiveMode() async {
    const url = 'https://devsignagebe.qcomm.co/app/client_profile/';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'clientVersion': '1.0',
        'playSound': _isNotificationSoundOn,
        'unobtrusive_mode': !_isUnobtrusiveMode,
      }),
    );

    if (response.statusCode == 200) {
      print('Unobstructive mode updated successfully.');
      await storage.write(key: 'unobtrusive_mode', value: (!_isUnobtrusiveMode).toString());
      setState(() {
        _isUnobtrusiveMode = !_isUnobtrusiveMode;
      });
      print('API call made: $_isUnobtrusiveMode');
    } else {
      print('Failed to update unobstructive mode.');
    }
  }

  Future<void> _toggleNotificationSound() async {
    const url = 'https://devsignagebe.qcomm.co/app/client_profile/';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'clientVersion': '1.0',
        'playSound': !_isNotificationSoundOn,
        'unobtrusive_mode': _isUnobtrusiveMode,
      }),
    );

    if (response.statusCode == 200) {
      print('Notification sound updated successfully.');
      await storage.write(key: 'notification_sound', value: (!_isNotificationSoundOn).toString());
      setState(() {
        _isNotificationSoundOn = !_isNotificationSoundOn;
      });
    } else {
      print('Failed to update notification sound.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 280,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(1, 115, 114, 1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(230),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Profile                                                v1.0',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 1.0, bottom: 28.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Username: $_username',
                          style: const TextStyle(
                            color: Color.fromRGBO(1, 115, 114, 1),
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.normal,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _toggleNotificationSound,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(300, 50),
                      ),
                      icon: Icon(
                        _isNotificationSoundOn ? Icons.volume_up : Icons.volume_off,
                        color: const Color.fromRGBO(1, 115, 114, 1),
                      ),
                      label: Text(
                        _isNotificationSoundOn ? 'Notification Sound On' : 'Notification Sound Off',
                        style: const TextStyle(
                          color: Color.fromRGBO(1, 115, 114, 1),
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _toggleUnobtrusiveMode,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(300, 50),
                      ),
                      icon: Icon(
                        _isUnobtrusiveMode ? Icons.check_box : Icons.check_box_outline_blank,
                        color: const Color.fromRGBO(1, 115, 114, 1),
                      ),
                      label: const Text(
                        'Unobtrusive Mode',
                        style: TextStyle(
                          color: Color.fromRGBO(1, 115, 114, 1),
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 50,
                      width: 300,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await storage.delete(key: 'token');
                          await storage.delete(key: 'fcmToken');
                          await storage.delete(key: 'username');
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const MyApp(initialRoute: '/login')),
                            (route) => false,
                          );
                        },
                        icon: const Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: Color.fromRGBO(1, 115, 114, 1),
                            ),
                            SizedBox(width: 20),
                          ],
                        ),
                        label: const Text(
                          'Logout or Exit',
                          style: TextStyle(
                            color: Color.fromRGBO(1, 115, 114, 1),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 128,
            left: (MediaQuery.of(context).size.width - 270) / 2,
            child: Container(
              height: 210,
              width: 270,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: const Color.fromRGBO(1, 115, 114, 1),
                  width: 2,
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/QCommLGIcon.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
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
                icon: const Icon(Icons.dashboard, color: Color(0xFF018786)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.account_circle, color: Color.fromRGBO(1, 135, 134, 1)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.history, color: Color.fromRGBO(1, 135, 134, 1)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
