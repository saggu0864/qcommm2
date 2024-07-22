import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

import 'History.dart';
import 'WebViewApp.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = const FlutterSecureStorage();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  WebViewController? _controller;
  String? webViewUrl;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _firebaseMessaging.requestPermission();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        _handleNotification(response.payload);
      },
    );

    _firebaseMessaging.getToken().then((fcmtoken) async {
      print("Firebase Messaging Token: $fcmtoken");
      if (fcmtoken != null) {
        await storage.write(key: 'fcmToken', value: fcmtoken);
        print("FCM token stored in secure storage");
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      Map<String, dynamic> data = message.data;

      data.forEach((key, value) {
        print("Key: $key, Value: $value");
      });

      String? id = data['id'];
      print("Fetched ID: $id");

      if (notification != null && android != null) {
        String? token = await storage.read(key: 'token');
        if (id != null && token != null) {
          String payload = 'https://devapp.qcomm.co/$token/home/content/$id';
          print("Constructed URL: $payload");

          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'your_channel_id',
                'your_channel_name',
                channelDescription: 'your_channel_description',
                importance: Importance.max,
                priority: Priority.high,
                showWhen: false,
                icon: '@drawable/qcommremovebgpreview',
                styleInformation: BigPictureStyleInformation(
                  DrawableResourceAndroidBitmap('@drawable/notification_bg'),
                  
                ),
              ),
            ),
            payload: payload,
          );
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      _handleNotification(message.data['id']);
    });

    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) async {
      if (message != null) {
        _handleNotification(message.data['id']);
      }
    });
  }

  Future<void> _handleNotification(String? id) async {
    String? token = await storage.read(key: 'token');
    if (id != null && token != null) {
      final urlWithTokenAndId = 'https://devapp.qcomm.co/$token/home/content/$id';
      if (HomeScreen.homeScreenKey.currentState != null &&
          HomeScreen.homeScreenKey.currentState!.mounted) {
        HomeScreen.homeScreenKey.currentState!.updateWebViewUrl(urlWithTokenAndId);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        ).then((_) {
          HomeScreen.homeScreenKey.currentState!.updateWebViewUrl(urlWithTokenAndId);
        });
      }
    }
  }

  Future<void> updateWebViewUrl(String url) async {
    setState(() {
      webViewUrl = url;
    });
    if (_controller != null) {
      _controller!.loadUrl(Uri.encodeFull(webViewUrl!));
    }
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  Future<bool> _onWillPop() async {
    await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: webViewUrl == null
                    ? FutureBuilder<String?>(
                        future: getToken(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done) {
                            if (snapshot.hasData && snapshot.data != null) {
                              final token = snapshot.data!;
                              final urlWithToken =
                                  'https://devapp.qcomm.co/$token/home/content';
                              return WebView(
                                initialUrl: Uri.encodeFull(urlWithToken),
                                javascriptMode: JavascriptMode.unrestricted,
                                onWebViewCreated: (controller) {
                                  _controller = controller;
                                },
                              );
                            } else {
                              return WebView(
                                initialUrl: Uri.encodeFull('http://192.168.3.57:4201'),
                                javascriptMode: JavascriptMode.unrestricted,
                                onWebViewCreated: (controller) {
                                  _controller = controller;
                                },
                              );
                            }
                          } else {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                        },
                      )
                    : WebView(
                        initialUrl: Uri.encodeFull(webViewUrl!),
                        javascriptMode: JavascriptMode.unrestricted,
                        onWebViewCreated: (controller) {
                          _controller = controller;
                        },
                      ),
              ),
            ],
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
                  icon: const Icon(Icons.dashboard,
                      color: Color.fromRGBO(1, 135, 134, 1)),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.account_circle,
                      color: Color.fromRGBO(1, 135, 134, 1)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WebViewApp()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.history,
                      color: Color.fromRGBO(1, 135, 134, 1)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HistoryPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
