import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lokshen_delivery_riders_app/global/global.dart';
import 'package:lokshen_delivery_riders_app/widgets/custom_text_field.dart';
import 'package:lokshen_delivery_riders_app/widgets/error_dailog.dart';
import 'package:firebase_storage/firebase_storage.dart' as fstorage;
import 'package:lokshen_delivery_riders_app/widgets/loading_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lokshen_delivery_riders_app/mainScreens/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> formkey = GlobalKey<FormState>();
  TextEditingController namecontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController confirmpasswordcontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController locationcontroller = TextEditingController();
  TextEditingController phonecontroller = TextEditingController();
  XFile? imageXFile;
  final ImagePicker _picker = ImagePicker();
  Position? position;
  List<Placemark>? placeMarks;

  String sellerImageUrl = "";
  String completeAddress = "";

  // New variables for documents
  XFile? passportImageFile;
  XFile? idImageFile;
  XFile? driversLicenseImageFile;
  XFile? proofOfBankingImageFile;
  XFile? taxNumberImageFile;

  String passportImageUrl = "";
  String idImageUrl = "";
  String driversLicenseImageUrl = "";
  String proofOfBankingImageUrl = "";
  String taxNumberImageUrl = "";

  Future<void> _getImage() async {
    imageXFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      imageXFile;
    });
  }

  Future<void> _getDocumentImage(String docType) async {
    XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      switch (docType) {
        case 'passport':
          passportImageFile = pickedFile;
          break;
        case 'id':
          idImageFile = pickedFile;
          break;
        case 'driversLicense':
          driversLicenseImageFile = pickedFile;
          break;
        case 'proofOfBanking':
          proofOfBankingImageFile = pickedFile;
          break;
        case 'taxNumber':
          taxNumberImageFile = pickedFile;
          break;
      }
    });
  }

  Future<String> _uploadDocumentImage(XFile? file, String docType) async {
    if (file == null) return "";

    String fileName = '${docType}_${DateTime.now().millisecondsSinceEpoch.toString()}.jpg';
    fstorage.Reference reference = fstorage.FirebaseStorage.instance.ref().child('documents').child(fileName);
    fstorage.UploadTask uploadTask = reference.putFile(File(file.path));
    fstorage.TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
    return await taskSnapshot.ref.getDownloadURL();
  }

  getCurrentLocation() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();
    Position newPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    position = newPosition;
    placeMarks = await placemarkFromCoordinates(position!.latitude, position!.longitude);
    Placemark pMark = placeMarks![0];

    completeAddress = '${pMark.subThoroughfare} ${pMark.thoroughfare}, ${pMark.subLocality} ${pMark.locality}, ${pMark.subAdministrativeArea}, ${pMark.administrativeArea} ${pMark.postalCode}, ${pMark.country}';
    locationcontroller.text = completeAddress;
  }

  void formValidation() async {
    if (imageXFile == null) {
      showDialog(
          context: context,
          builder: (c) {
            return ErrorDailog(
              message: "Please select an image.",
            );
          });
    } else if (formkey.currentState!.validate()) {
      showDialog(
          context: context,
          builder: (c) {
            return LoadingDialog(
              message: "Registering Account",
            );
          });

      // Upload all documents
      passportImageUrl = await _uploadDocumentImage(passportImageFile, 'passport');
      idImageUrl = await _uploadDocumentImage(idImageFile, 'id');
      driversLicenseImageUrl = await _uploadDocumentImage(driversLicenseImageFile, 'driversLicense');
      proofOfBankingImageUrl = await _uploadDocumentImage(proofOfBankingImageFile, 'proofOfBanking');
      taxNumberImageUrl = await _uploadDocumentImage(taxNumberImageFile, 'taxNumber');

      validateAndSaveUserInfo();
    }
  }

  void validateAndSaveUserInfo() async {
    User? currentUser;
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailcontroller.text.trim(),
        password: passwordcontroller.text.trim()).then((auth) {
      currentUser = auth.user;
    }).catchError((error) {
      Navigator.pop(context);
      showDialog(
          context: context,
          builder: (c) {
            return ErrorDailog(
              message: error.message.toString(),
            );
          });
    });

    if (currentUser != null) {
      saveDataToFirestore(currentUser!);
    }
  }

  Future saveDataToFirestore(User currentUser) async {
    FirebaseFirestore.instance.collection("riders").doc(currentUser.uid).set({
      "riderUID": currentUser.uid,
      "riderEmail": currentUser.email,
      "riderName": namecontroller.text.trim(),
      "riderAvatarUrl": sellerImageUrl,
      "phone": phonecontroller.text.trim(),
      "address": completeAddress,
      "status": "approved",
      "passportImageUrl": passportImageUrl,
      "idImageUrl": idImageUrl,
      "driversLicenseImageUrl": driversLicenseImageUrl,
      "proofOfBankingImageUrl": proofOfBankingImageUrl,
      "taxNumberImageUrl": taxNumberImageUrl,
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("riderUID", currentUser.uid);
    await prefs.setString("riderEmail", currentUser.email!);
    await prefs.setString("riderName", namecontroller.text.trim());
    await prefs.setString("riderAvatarUrl", sellerImageUrl);
    await prefs.setString("phone", phonecontroller.text.trim());
    await prefs.setString("address", completeAddress);

    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (c) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _getImage(),
              child: CircleAvatar(
                radius: MediaQuery.of(context).size.width * 0.20,
                backgroundColor: Colors.white,
                backgroundImage: imageXFile == null ? null : FileImage(File(imageXFile!.path)),
                child: imageXFile == null
                    ? Icon(Icons.add_photo_alternate, size: MediaQuery.of(context).size.width * 0.20, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Form(
              key: formkey,
              child: Column(
                children: [
                  CustomTextField(data: Icons.person, controller: namecontroller, hintText: "Name", isObsecre: false),
                  CustomTextField(data: Icons.email, controller: emailcontroller, hintText: "Email", isObsecre: false),
                  CustomTextField(data: Icons.lock, controller: passwordcontroller, hintText: "Password", isObsecre: true),
                  CustomTextField(data: Icons.lock, controller: confirmpasswordcontroller, hintText: "Confirm Password", isObsecre: true),
                  CustomTextField(data: Icons.phone, controller: phonecontroller, hintText: "Phone", isObsecre: false),
                  CustomTextField(data: Icons.my_location, controller: locationcontroller, hintText: "My current location", isObsecre: false, enabled: true),
                  Container(
                    width: 400,
                    height: 40,
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      label: const Text("Get my current Location", style: TextStyle(color: Colors.white)),
                      icon: const Icon(Icons.location_on, color: Colors.white),
                      onPressed: () => getCurrentLocation(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Passport
                  _documentUploadSection('Passport', passportImageFile, 'passport'),
                  // ID
                  _documentUploadSection('ID', idImageFile, 'id'),
                  // Driver's License
                  _documentUploadSection('Driver\'s License', driversLicenseImageFile, 'driversLicense'),
                  // Proof of Banking
                  _documentUploadSection('Proof of Banking', proofOfBankingImageFile, 'proofOfBanking'),
                  // Personal Income Tax Number
                  _documentUploadSection('Personal Income Tax Number', taxNumberImageFile, 'taxNumber'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              child: const Text("SignUp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              onPressed: () => formValidation(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _documentUploadSection(String title, XFile? file, String docType) {
    return Column(
      children: [
        InkWell(
          onTap: () => _getDocumentImage(docType),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: MediaQuery.of(context).size.width * 0.10,
                backgroundColor: Colors.white,
                backgroundImage: file == null ? null : FileImage(File(file.path)),
                child: file == null
                    ? Icon(Icons.add_photo_alternate, size: MediaQuery.of(context).size.width * 0.10, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 10),
              Text(title),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
