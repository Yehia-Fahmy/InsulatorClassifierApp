import 'dart:isolate';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:isolate';


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
  // initialization variables
  bool _initialized = false;
  bool _error = false;
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
  loadModel() async {
    String res = await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/dict.txt",
      isAsset: true
    );
    print("Result of loading the model: $res");
    if (res == 'success'){
      setState(() {
        _initialized = true;
      });
    }
  }

  updateVariables(){
    if (_outputs != null){
      setState(() {
        classification = _outputs[0]['label'].toString().substring(2);
        certainty = _outputs[0]['confidence'] * 100;
        certaintyString = certainty.toString().substring(0,5);
      });
    }else {
      print("output is empty");
    }
  }

  takePicture(){
    // TODO implement taking picture with camera
  }

  reloadModel() {
    print('reloading model...');
    Tflite.close();
    loadModel();
  }

  // function to pick the image from library
  pickImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    setState(() {
      _image = image;
    });
    updateVariables();
  }

  Uint8List imageToByteListUint8(img.Image image, int inputSize) {
    var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
    var buffer = Uint8List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = img.getRed(pixel);
        buffer[pixelIndex++] = img.getGreen(pixel);
        buffer[pixelIndex++] = img.getBlue(pixel);
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  classifyImage(File imageFile) async {
    print('classifying...');
    img.Image image = img.decodeImage(imageFile.readAsBytesSync());
    var binaryImage = imageToByteListUint8(image, 224);
    var recognitions = await Tflite.runModelOnBinary(
        binary: binaryImage,// required
        numResults: 7,    // defaults to 5
        threshold: 0.05,  // defaults to 0.1
        asynch: false      // defaults to true
    );
    print(recognitions);
  }

  @override
  void initState() {
    _loading = true;
    super.initState();
    loadModel();
    _loading = false;
  }

  @override
  void dispose() {
    super.dispose();
    Tflite.close();
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
                color: _initialized ? themeColor : Colors.red[900],
              ),

              // Classify button
              Padding(
                padding: EdgeInsets.all(15.0),
                child: ElevatedButton(
                  child: Text('Classify'),
                  onPressed: () => classifyImage(_image),
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
                        Icons.refresh_outlined,
                      ),
                      onPressed: () => reloadModel(),
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
