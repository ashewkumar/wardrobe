import 'dart:io';
//import 'package:http_parser/http_parser.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UploadImagePage extends StatefulWidget {
  const UploadImagePage({super.key});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {

  File? _image;
  bool _loading = false;

  final ImagePicker picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // ---------------- PICK IMAGE (Camera / Gallery) ----------------

  Future pickImage() async {

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (context) {

        return SafeArea(
          child: Wrap(
            children: [

              // CAMERA
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () async {

                  Navigator.pop(context);

                  final picked = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );

                  if (picked != null && mounted) {
                    setState(() {
                      _image = File(picked.path);
                    });
                  }
                },
              ),

              // GALLERY
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () async {

                  Navigator.pop(context);

                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );

                  if (picked != null && mounted) {
                    setState(() {
                      _image = File(picked.path);
                    });
                  }
                },
              ),

              const Divider(),

              // CANCEL
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- UPLOAD IMAGE ----------------
Future uploadImage() async {
  if (_image == null) {
    showMessage("Select image first");
    return;
  }

  if (_nameController.text.isEmpty) {
    showMessage("Enter image name");
    return;
  }

  setState(() => _loading = true);

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final uri =
      Uri.parse("http://112.196.37.203:8888/api/upload-image");

  var request = http.MultipartRequest('POST', uri);

  // ✅ Do NOT set Content-Type manually
  request.headers.addAll({
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  });

  // Fields
  request.fields.addAll({
    'image_name': _nameController.text.trim(),
    'description': _descController.text.trim(),
  });

  // ✅ Read file as bytes
  final bytes = await _image!.readAsBytes();
  final fileName = _image!.path.split('/').last;

  // ✅ Create multipart file manually
  final multipartFile = http.MultipartFile.fromBytes(
    'image',
    bytes,
    filename: fileName,
  );

  request.files.add(multipartFile);

  print("Uploading file: ${_image!.path}");
  print("File size: ${bytes.length}");

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  setState(() => _loading = false);

  print("STATUS: ${response.statusCode}");
  print("BODY: ${response.body}");

  if (response.statusCode == 200) {
    showMessage("Upload Successful ✅");

    setState(() {
      _image = null;
      _nameController.clear();
      _descController.clear();
    });
  } else {
    showMessage("Upload Failed ❌ (${response.statusCode})");
  }
}

  // ---------------- MESSAGE ----------------

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ---------------- DISPOSE ----------------

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[100],

    appBar: AppBar(
      title: const Text("Upload Image"),
      centerTitle: true,
      elevation: 0,
    ),

    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        children: [

          // IMAGE CARD
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,

            child: Container(
              width: double.infinity,
              height: 220,
              padding: const EdgeInsets.all(10),

              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [

                        Icon(
                          Icons.image,
                          size: 60,
                          color: Colors.grey,
                        ),

                        SizedBox(height: 10),

                        Text(
                          "No Image Selected",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // SELECT BUTTON
          SizedBox(
            width: double.infinity,
            height: 45,

            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_a_photo),
              label: const Text("Select Image"),
              onPressed: pickImage,

              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // FORM CARD
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [

                  // IMAGE NAME
                  TextField(
                    controller: _nameController,

                    decoration: InputDecoration(
                      labelText: "Image Name",
                      prefixIcon: const Icon(Icons.title),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // DESCRIPTION
                  TextField(
                    controller: _descController,
                    maxLines: 3,

                    decoration: InputDecoration(
                      labelText: "Description",
                      prefixIcon: const Icon(Icons.description),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          // UPLOAD BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,

            child: _loading
                ? const Center(child: CircularProgressIndicator())

                : ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text(
                      "Upload Image",
                      style: TextStyle(fontSize: 16),
                    ),

                    onPressed: uploadImage,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

}

