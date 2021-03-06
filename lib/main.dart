import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:firebase_ml_custom/firebase_ml_custom.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:image/image.dart';

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
  // string to hold the result of loading the model
  Future<String> _loadedMessage;

  // member functions
  void initializeFlutterFire() async {
    try {
      await Firebase.initializeApp();
      setState(() {
        _initialized = true;
      });
    }
    catch (e){
      setState(() {
        _error = true;
      });
    }
  }


  static Future<String> mlLoadModel() async {
    final modelFile = await loadModelFromFirebase();
    return await loadTFLiteModel(modelFile);
  }

  static Future<File> loadModelFromFirebase() async {
    try {
      // Create model with a name that is specified in the Firebase console
      final model = FirebaseCustomRemoteModel('TF_Lite_Model');

      // Specify conditions when the model can be downloaded.
      // If there is no wifi access when the app is started,
      // this app will continue loading until the conditions are satisfied.
      final conditions = FirebaseModelDownloadConditions(
          androidRequireWifi: true, iosAllowCellularAccess: false);

      // Create model manager associated with default Firebase App instance.
      final modelManager = FirebaseModelManager.instance;

      // Begin downloading and wait until the model is downloaded successfully.
      await modelManager.download(model, conditions);
      assert(await modelManager.isModelDownloaded(model) == true);

      // Get latest model file to use it for inference by the interpreter.
      var modelFile = await modelManager.getLatestModelFile(model);
      assert(modelFile != null);
      return modelFile;
    } catch (exception) {
      print('Failed on loading your model from Firebase: $exception');
      print('The program will not be resumed');
      rethrow;
    }
  }

  static Future<String> loadTFLiteModel(File modelFile) async {
    try {
      final appDirectory = await getApplicationDocumentsDirectory();
      final labelsData =
      await rootBundle.load("assets/labels.txt");
      final labelsFile =
      await File(appDirectory.path + "/_labels.txt")
          .writeAsBytes(labelsData.buffer.asUint8List(
          labelsData.offsetInBytes, labelsData.lengthInBytes));

      assert(await Tflite.loadModel(
        model: modelFile.path,
        labels: labelsFile.path,
        isAsset: false,
      ) ==
          "success");
      return "Model is loaded";
    } catch (exception) {
      print(
          'Failed on loading your model to the TFLite interpreter: $exception');
      print('The program will not be resumed');
      rethrow;
    }
  }

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
      //model: "assets/TF_Lite_Model.tflite",
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
    _loading = true;
    // initializeFlutterFire();
    // setState(() {
    //   _loadedMessage = mlLoadModel();
    //   _loading = false;
    // });
    // if (_initialized) {
    //   print('flutterfire has initialized succesfully');
    // }
    // else {
    //   print('we were unable to initialize');
    // }
    Tflite.close();
    super.initState();
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
