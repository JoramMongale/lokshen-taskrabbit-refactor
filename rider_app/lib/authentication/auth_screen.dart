import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';



class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber ,
                    Colors.cyan,

                  ],
                  begin: FractionalOffset(0.0,0.0),
                  end: FractionalOffset(1.0, 0.0),
                  stops: [1.0,0.0],
                  tileMode: TileMode.clamp,

                )
              ),
            ),
            title: Text(
              "LokShen Delivery",
              style: TextStyle(
                fontSize: 35,
                color: Colors.white,
                fontFamily: "Signatra",
              ),
            ),
            centerTitle: true,
            bottom: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.lock, color: Colors.white,),
                  text: "Login",
                ),
                Tab(
                  icon: Icon(Icons.person, color: Colors.white,),
                  text: "Register",
                )
              ],
              indicatorColor: Colors.white38,
              indicatorWeight: 6,
            ),
              automaticallyImplyLeading: false,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.amber,
                  Colors.cyan,
                ]
              )
            ),
              child: const TabBarView(
              children: [
                LoginScreen(),
                RegisterScreen(),
              ],
          ),
          ),
        )
    );
  }
}
