import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_custom/firebase_ml_custom.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // some colors
  Color themeColor = Colors.green[900];
  Color themeColor3 = Colors.grey[400];
  // variables used to display information
  String classification = "";
  double certainty = 0.0;
  String certaintyString = "";
  // image picker variables
  File _image;
  // classification variables
  List _outputs;
  bool _loading = false;
  // flutterfire variables
  bool _firebaseInitialized = false;
  bool _firebaseError = false;
  FirebaseApp defaultApp;
  FirebaseCustomRemoteModel remoteModel = FirebaseCustomRemoteModel('TF_Lite_Model');
  FirebaseModelDownloadConditions conditions =
  FirebaseModelDownloadConditions(
      androidRequireWifi: true,
      androidRequireDeviceIdle: true,
      iosAllowCellularAccess: false,
      iosAllowBackgroundDownloading: true);
  FirebaseModelManager modelManager = FirebaseModelManager.instance;


  // Firebase functions
  void downloadModel() async {
    print('starting download');
    try {
      bool res = false;
      await modelManager.download(remoteModel, conditions);
      res = await modelManager.isModelDownloaded(remoteModel);
      if (res) {
        print('model has been successfully downloaded');
      } else {
        print('did not download');
      }
    }
    catch (e){
      print('there was an error downloading the model');
    }
  }

  void initializeFlutterFire() async {
    try {
      defaultApp = await Firebase.initializeApp();
      setState(() {
        _firebaseInitialized = true;
      });
    } catch(e) {
      print('error initializing firebase');
      setState(() {
        _firebaseError = true;
      });
    }
  }

  // member functions
  @override
  void initState() {
    initializeFlutterFire();
    downloadModel();
    super.initState();
  }

  updateVariables(){
    setState(() {
      classification = _outputs[0]['label'].toString().substring(2);
      certainty = _outputs[0]['confidence'] * 100;
      certaintyString = certainty.toString().substring(0,5);
    });
  }

  // function to pick the image from library
  pickImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    classifyImage(image);
    setState(() {
      _image = image;
    });
  }

  classifyImage(File image) async {
    print('classifying');
  }

  @override
  Widget build(BuildContext context) {
    return _loading ?
    Container(
      alignment: Alignment.center,
      child: CircularProgressIndicator(),
    ) :
    Scaffold(
      backgroundColor: themeColor3,
      appBar: AppBar(
        title: Text('Insulator Classifier'),
        centerTitle: true,
        backgroundColor: themeColor,
        actions: [
          Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              child: IconButton(
                onPressed: () {
                  // TODO proceed to contact angle measurement
                },
                icon: Icon(
                    Icons.menu
                ),
              )
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: Column(
            children: [
              // display an icon if no image present
              Container(
                height: 350,
                width: 350,
                child: _image == null ? Icon(Icons.camera_alt_outlined) : Image.file(_image),
                color: _firebaseError ? Colors.red[800] : themeColor,
              ),

              // Classify button
              Padding(
                padding: EdgeInsets.all(15.0),
                child: ElevatedButton(
                  child: Text('Classify'),
                  onPressed: () {
                    updateVariables();
                  },
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all(themeColor3),
                    backgroundColor: MaterialStateProperty.all(themeColor),
                  ),
                ),
              ),

              // Classification
              Container(
                color: themeColor,
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      'Class: $classification',
                      style: TextStyle(
                        color: themeColor3,
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),

                    Divider(
                      color: themeColor3,
                      height: 10,
                    ),

                    // Certainty
                    Text(
                      'Certainty: $certaintyString %',
                      style: TextStyle(
                        color: themeColor3,
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // take/choose photo buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(15.0),
                    child: ElevatedButton(
                      child: Icon(
                        Icons.camera_alt_outlined,
                      ),
                      onPressed: () {
                        print('take picture with camera');
                      },
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all(themeColor3),
                        backgroundColor: MaterialStateProperty.all(themeColor),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(15.0),
                    child: ElevatedButton(
                      child: Icon(
                        Icons.photo,
                      ),
                      onPressed: () {
                        pickImage();
                      },
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all(themeColor3),
                        backgroundColor: MaterialStateProperty.all(themeColor),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
