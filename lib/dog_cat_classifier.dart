import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Cat Classifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    classifier.loadModel();
  }

  Future getImage() async {
    setState(() {
      _isLoading = true;
    });

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      final result = await classifier.classifyImage(_image!);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dog Cat Classifier'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null
                ? Text('No image selected.')
                : Image.file(_image!, height: 300),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Text(_result, style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: getImage,
              child: Text('Pick an image'),
            ),
          ],
        ),
      ),
    );
  }
}

class DogCatClassifier {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('lib/assets/cat_dog_model.tflite');
      print('Model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  Future<String> classifyImage(File imageFile) async {
    var inputImage = img.decodeImage(imageFile.readAsBytesSync())!;
    inputImage = img.copyResize(inputImage, width: 64, height: 64);

    var input = _imageToByteListFloat32(inputImage, 64, 127.5, 127.5);
    var output = List.filled(1, 0).reshape([1, 1]);

    try {
      _interpreter.run(input, output);
      var dogProbability = output[0][0];
      var catProbability = 1 - dogProbability;
      
      String result;
      if (dogProbability > catProbability) {
        result = 'Dog';
      } else {
        result = 'Cat';
      }
      
      return '$result\nDog: ${(dogProbability * 100).toStringAsFixed(2)}%\nCat: ${(catProbability * 100).toStringAsFixed(2)}%';
    } catch (e) {
      print('Error classifying image: $e');
      return 'Error classifying image';
    }
  }

  Uint8List _imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r.toDouble() - mean) / std;
        buffer[pixelIndex++] = (pixel.g.toDouble() - mean) / std;
        buffer[pixelIndex++] = (pixel.b.toDouble() - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}