import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() => runApp(Home());

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String resultText = "";
  String portal;
  String orderNumber = "";
  String address = "";
  String pinCode = "";
  String name = "";
  String invoiceDate = "";

  ///Regex
  // String emailRegex =
  //     r"[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
  // String phoneRegex =
  //     r"(?:(?:\+|0{0,2})91(\s*[\ -]\s*)?|[0]?)?[789]\d{9}|(\d[ -]?){10}\d";
  String fkOIRegex = r"OD[0-9]{18}";
  String aOIRegex = r"[0-9]{3}[\-][0-9]{7}[\-][0-9]{7}";
  String shippingRegex = r"shippingaddress(.*?)([1-9]{1}[0-9]{2}[0-9]{3})";
  String amaPortalRegex = r"amazon";
  String fkPortalRegex = r"flipkart";
  String fkDateReg = r"invoicedate([0-9]{2}\-[0-9]{2}\-[0-9]{4})";
  String amaDateReg = r"invoicedate([0-9]{2}\.[0-9]{2}\.[0-9]{4})";

  String shippingIfFailsRegex = r"shipto(.*?)([1-9]{1}[0-9]{2}[0-9]{3})";
  String notfound = "NOTFOUND";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Text Example'),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(10),
        child: ListView(
          children: <Widget>[
            SizedBox(
              width: double.maxFinite,
              height: 70,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.white),
                child: Text(
                  "Select Invoice and recognized text",
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () async {
                  handleOnpressed();
                },
              ),
            ),
            Text(resultText ?? "NOPE"),
          ],
        ),
      ),
    );
  }

  handleOnpressed() async {
    FilePickerResult pickedFile = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ["pdf"]);

    if (pickedFile != null) {
      PlatformFile file = pickedFile.files.first;
      File finalFile = File(file.path);
      PdfDocument pdfDocument =
          PdfDocument(inputBytes: finalFile.readAsBytesSync());

      PdfTextExtractor extractor = PdfTextExtractor(pdfDocument);

      String text = extractor.extractText();

      text = text.replaceAll(":", "");
      text = text.replaceAll(RegExp(r"\s+"), "");
      text = text.replaceAll("\n", "");
      text = text.trim();
      // print(text.substring(0,5));
      // _showResult(text);
      setState(() {
        resultText = text;
      });
      // return;

      portal = findStringMatch(regex: amaPortalRegex, text: text) == "NOTFOUND"
          ? findStringMatch(regex: fkPortalRegex, text: text)
          : findStringMatch(regex: amaPortalRegex, text: text);

      print(portal);
      if (portal.toLowerCase() == "amazon") {
        print("amazon block");
        orderNumber = RegExp(
          aOIRegex,
          multiLine: false,
          caseSensitive: false,
        ).stringMatch(text);

        invoiceDate = RegExp(
          amaDateReg,
          multiLine: false,
          caseSensitive: false,
        ).firstMatch(text).group(1);
        print(RegExp(
          amaDateReg,
          multiLine: false,
          caseSensitive: false,
        ).stringMatch(text));
        address = RegExp(
          shippingRegex,
          multiLine: true,
          caseSensitive: false,
        ).firstMatch(text)?.group(1);
        pinCode = RegExp(
          shippingRegex,
          multiLine: true,
          caseSensitive: false,
        ).firstMatch(text)?.group(2);
        name = RegExp(
          shippingRegex,
          multiLine: true,
          caseSensitive: false,
        ).firstMatch(text)?.group(1)?.split(',')?.first;
      } else {
        orderNumber = RegExp(
          fkOIRegex,
          multiLine: false,
          caseSensitive: false,
        ).stringMatch(text);
        invoiceDate = RegExp(
          fkDateReg,
          multiLine: false,
          caseSensitive: false,
        ).firstMatch(text).group(1);
        address = address = RegExp(
          shippingRegex,
          multiLine: true,
          caseSensitive: false,
        ).firstMatch(text)?.group(1);
        if (address != null) {
          pinCode = RegExp(
            shippingRegex,
            multiLine: true,
            caseSensitive: false,
          ).firstMatch(text)?.group(2);
          name = RegExp(
            shippingRegex,
            multiLine: true,
            caseSensitive: false,
          ).firstMatch(text)?.group(1)?.split(',')?.first;
        } else {
          address = address = RegExp(
            shippingIfFailsRegex,
            multiLine: true,
            caseSensitive: false,
          ).firstMatch(text)?.group(1);
          pinCode = RegExp(
            shippingIfFailsRegex,
            multiLine: true,
            caseSensitive: false,
          ).firstMatch(text)?.group(2);
          name = RegExp(
            shippingIfFailsRegex,
            multiLine: true,
            caseSensitive: false,
          ).firstMatch(text)?.group(1)?.split(',')?.first;
        }
      }

      _showResult(
          'portals==>\n${portal ?? notfound}\n\nordernumber==>\n${orderNumber ?? notfound}\n\nivoiceDate==>\n${invoiceDate ?? notfound}\n\n pincode==>\n${pinCode ?? notfound}\n\n name==>\n${name ?? notfound}\n\naddress==>\n${address ?? notfound}\n\n');
    }
  }

  // String cleanText(String text) {
  //   String text = text;
  //   text = text.replaceAll(" ", "");
  //   text = text.replaceAll(":", "");
  //   text = text.replaceAll("\n", "");
  //   return text;
  // }

  // findAllMatches({String regex, String text}) {
  //   List result = [];
  //   RegExp(
  //     regex,
  //     multiLine: false,
  //     caseSensitive: false,
  //   ).allMatches(text).forEach((element) {
  //     result.add(element.group(0));
  //   });
  //   return result;
  // }

  findStringMatch({String regex, String text}) {
    return RegExp(
          regex,
          multiLine: false,
          caseSensitive: false,
        ).stringMatch(text) ??
        "NOTFOUND";
  }

  Future<List<int>> myReadDocumentData(File name) async {
    final ByteData data = await rootBundle.load('assets/$name');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  void _showResult(String text) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Extracted text'),
            content: Scrollbar(
              child: SingleChildScrollView(
                child: Text(text),
                physics: BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
              ),
            ),
            actions: [
              FlatButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }
}
