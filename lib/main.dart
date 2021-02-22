import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as imglib;

void main() {
  runApp(MaterialApp(
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

  // member functions
  updateVariables(){
    setState(() {
      classification = _outputs[0]['label'].toString().substring(2);
      certainty = _outputs[0]['confidence'] * 100;
      certaintyString = certainty.toString().substring(0,5);
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",   // this model was trained using google.trainable.net (its not very good)
      //model: "assets/classifier_model.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  takePicture(){
    // TODO implement taking picture with camera
  }

  // function to pick the image from library
  pickImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    classifyImage(image);
    setState(() {
      _image = image;
    });
    updateVariables();
  }

  classifyImage(File image) async {
    print('classifying');
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      _outputs = output;
    });
  }

  @override
  void initState() {
    Tflite.close();
    super.initState();
    _loading = true;
    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
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
                color: themeColor,
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
                        takePicture();
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
