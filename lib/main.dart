import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dog_cat_classifier.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ClassifierPage(),
    );
  }
}

class ClassifierPage extends StatefulWidget {
  @override
  _ClassifierPageState createState() => _ClassifierPageState();
}

class _ClassifierPageState extends State<ClassifierPage> {
  final classifier = DogCatClassifier();
  File? _image;
  String _result = '';

  @override
  void initState() {
    super.initState();
    classifier.loadModel();
  }

  Future getImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      
      final result = await classifier.classifyImage(_image!);
      setState(() {
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dog or Cat Classifier'),
      ),
      body: Column(
        children: <Widget>[
          _image == null
              ? Text('No image selected.')
              : Image.file(_image!),
          SizedBox(height: 20),
          Text(_result),
          ElevatedButton(
            onPressed: getImage,
            child: Text('Pick an image'),
          ),
        ],
      ),
    );
  }
}