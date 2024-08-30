import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImageRecognition(),
    );
  }
}

class ImageRecognition extends StatefulWidget {
  @override
  _ImageRecognitionState createState() => _ImageRecognitionState();
}

class _ImageRecognitionState extends State<ImageRecognition> {
  File? _image;
  List<dynamic>? _recognitions;
  bool _loading = false;
  bool _errorLoadingModel = false;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    setState(() {
      _loading = true;
    });

    try {
      String? res = await Tflite.loadModel(
        model: "assets/converted_tflite/model_unquant.tflite",
        labels: "assets/converted_tflite/labels.txt",
      );
      print("Model loaded: $res");
      setState(() {});
    } catch (e) {
      print('Failed to load model. ${e.toString()}');
      setState(() {
        _errorLoadingModel = true;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    // ignore: deprecated_member_use
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _loading = true;
      });
      recognizeImage(_image!);
    }
  }

  Future<void> recognizeImage(File image) async {
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 5,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    setState(() {
      _recognitions = recognitions;
      _loading = false;
    });
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Recognition'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null ? Text("No image selected.") : Image.file(_image!),
            SizedBox(height: 16),
            _loading
                ? CircularProgressIndicator()
                : _recognitions != null
                    ? Column(
                        children: _recognitions!.map((res) {
                          return Text(
                            "${res["label"]}: ${res["confidence"].toStringAsFixed(3)}",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20.0,
                              background: Paint()..color = Colors.white,
                            ),
                          );
                        }).toList(),
                      )
                    : Container(),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: pickImage,
              child: Text("Pick Image"),
            ),
            SizedBox(height: 16),
            if (_errorLoadingModel)
              Text(
                'Failed to load model, please try again later.',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
