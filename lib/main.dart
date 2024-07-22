import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'HomeScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final storage = const FlutterSecureStorage();
  String? storedToken = await storage.read(key: 'token');

  runApp(MyApp(initialRoute: storedToken != null ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  String deviceId = 'deviceId';
  String fcmToken = '';

  @override
  void initState() {
    super.initState();
    getDeviceId();
    readStoredData();
  }

  Future<void> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    setState(() {
      deviceId = androidInfo.id;
    });
  }

  Future<void> readStoredData() async {
    String? storedToken = await storage.read(key: 'token');
    if (storedToken != null) {
      print('Token successfully retrieved from storage: $storedToken');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print('No token found in storage');
    }
  }

  Future<void> retrieveFcmToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      setState(() {
        fcmToken = token;
      });
      print('FCM token successfully retrieved: $fcmToken');
      await storage.write(key: 'fcmToken', value: fcmToken);
    } else {
      print('Failed to retrieve FCM token');
    }
  }

  void login(String username, String password) async {
    await retrieveFcmToken();
    try {
      Response response = await post(
        Uri.parse('https://devsignagebe.qcomm.co/app/login/'),
        body: {
          'username': username,
          'password': password,
          'device_id': fcmToken,
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body.toString());
        print(data);
        if (data['status']) {
          await storage.write(key: 'token', value: data['token']);
          await storage.write(key: 'username', value: username);
          print('Token and username stored');
          print(data['token']);
          print('Login successfully');
          print('Username: $username');
          nameController.clear();
          passwordController.clear();
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        print('Login failed');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(1, 115, 114, 1),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 100, 10, 0),
        child: ListView(
          children: <Widget>[
            Stack(
              alignment: Alignment.topCenter,
              children: [
                const CircleAvatar(
                  radius: 68,
                  backgroundImage: AssetImage('assets/QCommLGIcon.jpg'),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 140),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(10),
                  child: const Text(
                    'Welcome',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 25,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
              child: const Text(
                'Please Login to QCOMM!',
                style: TextStyle(fontSize: 22.5, color: Colors.white),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
              child: TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35.0),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  labelText: 'Username',
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                obscureText: true,
                controller: passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35.0),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
              ),
            ),
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 24),
              padding: const EdgeInsets.fromLTRB(20, 3, 20, 0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
                child: const Text(
                  'LOGIN',
                  style: TextStyle(color: Colors.black, fontSize: 17),
                ),
                onPressed: () {
                  login(nameController.text.toString(), passwordController.text.toString());
                },
              ),
            ),
            Container(
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Don't have an Account?",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  )
                ],
              ),
            ),
            Container(
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Contact Admin To get yourself Registered',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
