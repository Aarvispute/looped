import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

class ImageRecognitionWidget extends StatefulWidget {
  final String? imageUrl;

  const ImageRecognitionWidget({Key? key, this.imageUrl}) : super(key: key);

  @override
  _ImageRecognitionWidgetState createState() => _ImageRecognitionWidgetState();
}

class _ImageRecognitionWidgetState extends State<ImageRecognitionWidget> {
  List<dynamic>? _recognitions;
  bool _isLoading = false;
  bool _errorLoadingModel = false;

  @override
  void initState() {
    super.initState();
    loadModel();
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      recognizeImage(File(widget.imageUrl!));
    }
  }

  Future<void> loadModel() async {
    Tflite.close();

    setState(() {
      _isLoading = true;
      _errorLoadingModel = false;
    });

    try {
      await Tflite.loadModel(
        model: "assets/converted_tflite/model_unquant.tflite",
        labels: "assets/converted_tflite/labels.txt",
      );
    } catch (e) {
      print('Failed to load model. ${e.toString()}');
      setState(() {
        _errorLoadingModel = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> recognizeImage(File image) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var recognitions = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 6,
        threshold: 0.05,
        imageMean: 127.5,
        imageStd: 127.5,
      );
      setState(() {
        _recognitions = recognitions;
      });
    } catch (e) {
      print('Failed to recognize image. ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CircularProgressIndicator(); // Loading indicator
    }

    if (_errorLoadingModel) {
      return Text(
        'Failed to load model, please try again later.',
        style: TextStyle(color: Colors.red),
      );
    }

    return Column(
      children: _recognitions != null
          ? _recognitions!.map((res) {
        return Text(
          "${res["index"]} ${res["label"]}: ${res["confidence"].toStringAsFixed(3)}",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.0,
            background: Paint()..color = Colors.white,
          ),
        );
      }).toList()
          : [],
    );
  }
}
