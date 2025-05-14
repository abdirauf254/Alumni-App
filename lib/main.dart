import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutterauthentication/firebase_options.dart';
import 'package:flutterauthentication/screens/admin_dashboard.dart';
import 'package:flutterauthentication/screens/login_screen.dart';
import 'package:flutterauthentication/screens/user_dashboard.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Authentication());
}

class Authentication extends StatelessWidget {
  const Authentication({super.key});

  @override
  Widget build(BuildContext context) {
   
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Authentication',
      theme:  ThemeData(useMaterial3: true),
    initialRoute: FirebaseAuth.instance.currentUser  == null ? 'login' : 'home',
    routes: {
      '/login':(context) =>  LoginScreen(),
      '/admin':(context) => const  AdminHome(),
      '/user':(context) => const UserHome(),
    },
    home:  LoginScreen(),
    );
  }
}