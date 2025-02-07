import 'package:flutter/material.dart';
import 'package:voxcity/bars/tab_navigation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:voxcity/controller/screen_index.dart';
import 'Firebase/firebase_options.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Get.put(GlobalController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: TabNavigationScreen(),
    );
  }
}