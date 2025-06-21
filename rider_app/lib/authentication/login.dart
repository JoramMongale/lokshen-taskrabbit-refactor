// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lokshen_delivery_riders_app/global/global.dart';
import 'package:lokshen_delivery_riders_app/mainScreens/home_screen.dart';
import 'package:lokshen_delivery_riders_app/widgets/error_dailog.dart';
import 'package:lokshen_delivery_riders_app/widgets/loading_dialog.dart';
import '../widgets/custom_text_field.dart';
import 'auth_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key ? key}): super (key:key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
{
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();


  formValidation()
  {


    if(emailcontroller.text.isNotEmpty && passwordcontroller.text.isNotEmpty)
    {

      //Login

      loginNow();

    }
    else
    {
      showDialog
        (context: context,
          builder: (c)
          {
            return ErrorDailog(message: "Please type in both email and password",);
          }

          );
    }

  }


  loginNow() async
  {
    showDialog
      (context: context,
        builder: (c)
        {
          return  LoadingDialog(message: "Checking credentials  ....",);
        }

    );

    User? currentUser;

    await firebaseAuth.signInWithEmailAndPassword
      (email: emailcontroller.text.trim(),
        password: passwordcontroller.text.trim(),
    ).then((auth){
     currentUser = auth.user!;
    }).catchError((error){
      Navigator.pop(context);
      showDialog
        (context: context,
          builder: (c)
          {
            return ErrorDailog(
              message: error.message.toString(),
            );
          }

      );

    });

    if(currentUser != null)
    {
      readDataAndSetDataLocally(currentUser!);

    }
  }
    Future readDataAndSetDataLocally(User currentUser) async {

    await FirebaseFirestore.instance.collection("riders").doc(currentUser.uid).get().then((snapshot) async{

      if(snapshot.exists)
      {
        if(snapshot.data()!["status"]=="approved")
        {

          await sharedPreferences!.setString("uid", currentUser.uid);
          await sharedPreferences!.setString("email", snapshot.data()!["riderEmail"]);
          await sharedPreferences!.setString("name", snapshot.data()!["riderName"]);
          await sharedPreferences!.setString("photoUrl", snapshot.data()!["riderAvatarUrl"]);
          Navigator.pop(context);
          Navigator.push(context,MaterialPageRoute(builder: (c) => const HomeScreen()));

        }else
        {
          firebaseAuth.signOut();
          Navigator.pop(context);
          Fluttertoast.showToast(msg: "Admin has suspended your account. \n For enquiry contact makentiholdings@gmail.com");
        }

      }
      else
      {
        firebaseAuth.signOut();
        Navigator.pop(context);
        Navigator.push(context,MaterialPageRoute(builder: (c) => const AuthScreen()));
        showDialog
          (context: context,
            builder: (c)
            {
              return ErrorDailog(
                message:"Record does not exist.  Must register as a rider.",
              );
            }

        );

      }


    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              alignment: Alignment.bottomCenter,
              child : Padding(
                padding: EdgeInsets.all(15),
                child: Image.asset(
                  "images/signup.png",
                height: 270,),
              ),
            ),
            Form (
              key: _formkey,
              child:Column(
                children: [
                  CustomTextField(
                    data: Icons.mail,
                    controller: emailcontroller,
                    hintText: "Email",
                    isObsecre: false,
                  ),
                  CustomTextField(
                    data: Icons.lock,
                    controller: passwordcontroller,
                    hintText: "Password",
                    isObsecre: true,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 50,vertical: 20),
              ),
              onPressed: (){

                formValidation();

              },
              child: const Text(
                "Login",
                style: TextStyle (color :
                Colors.white,fontWeight: FontWeight.bold,),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
          ],
      ),

    );
  }
}
