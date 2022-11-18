import 'dart:convert';

import 'dart:io';
import 'dart:io' as Io;
import 'dart:typed_data';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recognise/apikey.dart';
import 'package:recognise/utils.dart';
import 'package:http/http.dart' as http;

class RecognitionScreen extends StatefulWidget {
  RecognitionScreen({Key? key}) : super(key: key);

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  late File pickedimage;

  bool scanning = false;
  String scannedText = '';

  optionsdialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          children: [
            SimpleDialogOption(
              onPressed: () => pickimage(ImageSource.gallery),
              child: Text(
                "Gallary",
                style: textStyle(20, Colors.black, FontWeight.w800),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => pickimage(ImageSource.camera),
              child: Text(
                "Camera",
                style: textStyle(20, Colors.black, FontWeight.w800),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: textStyle(20, Colors.black, FontWeight.w800),
              ),
            )
          ],
        );
      },
    );
  }

  pickimage(ImageSource source) async {
    final image = await ImagePicker().getImage(source: source);
    setState(() {
      scanning = true;
      pickedimage = File(image!.path);
    });
    Navigator.pop(context);

    // prepare the image
    Uint8List bytes = Io.File(pickedimage.path).readAsBytesSync();
    String img64 = base64Encode(bytes);

    //send to api
    String url = "https://api.ocr.space/parse/image";
    var data = {"base64Image": "data:image/jpg;base64,$img64"};
    var header = {"apikey": apikey};
    // ignore: unused_local_variable
    http.Response response = await http.post(url, body: data, headers: header);

    //get data back
    Map result = jsonDecode(response.body);
    print(result['ParsedResults'][0]['ParsedText']);
    setState(() {
      scanning = false;
      scannedText = result['ParsedResults'][0]['ParsedText'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF8F9FB),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min, 
      children: [
        FloatingActionButton(
          heroTag: null,
         onPressed: ()=>Share.text('FCR',scannedText,"text/plain"),
          child: Icon(
            Icons.copy,
            size: 28,
          ),
        ),
        SizedBox(
          width: 10,
        ),
        FloatingActionButton(
          backgroundColor: Color(0xffEC360E),
          heroTag: null,
          onPressed: () {
            FlutterClipboard.copy(scannedText).then((value) {
              SnackBar snackBar = SnackBar(
                content: Text(
                  "Copied to clipboard",
                  style: textStyle(18, Colors.white, FontWeight.w700),
                ),
                duration: Duration(seconds: 1),
              );

              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            });
          },
          child: Icon(
            Icons.reply,
            size: 34,
          ),
        )
      ]),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          child: Column(
            children: [
              SizedBox(
                height: 55 + MediaQuery.of(context).viewInsets.top,
              ),
              Text("Text Recognition",
                  style: textStyle(
                      30, Color(0xff1738EB).withOpacity(0.6), FontWeight.w800)),
              SizedBox(
                height: 30,
              ),
              InkWell(
                onTap: () => optionsdialog(context),
                child: Image(
                  width: 240,
                  height: 240,



                  image: pickedimage == null? AssetImage('images/314764_document_add_icon.png'): FileImage(pickedimage),




                  fit: BoxFit.fill,
                ),
              ),
              SizedBox(
                height: 30,
              ),
              scanning
                  ? Text(
                      "Scanning.....",
                      style: textStyle(30, Colors.black, FontWeight.w700),
                    )
                  : Text(
                      scannedText,
                      style: textStyle(25, Color(0xff1738EB).withOpacity(0.6),
                          FontWeight.w600),
                      textAlign: TextAlign.center,
                    )
            ],
          ),
        ),
      ),
    );
  }
}
