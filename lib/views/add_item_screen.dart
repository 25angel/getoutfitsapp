import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'add_item_details_screen.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  List<AssetPathEntity> albums = [];
  List<AssetEntity> images = [];
  List<Uint8List> thumbnails = [];
  List<String> firebaseImageUrls = [];
  String currentTab = 'Recently';
  AssetEntity? selectedAsset;
  String? selectedFirebaseUrl;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return;

    final allAlbums = await PhotoManager.getAssetPathList(
      onlyAll: false,
      type: RequestType.image,
    );

    setState(() {
      albums = allAlbums;
    });

    _loadImagesByTab(currentTab);
  }

  Future<List<String>> _fetchFirebasePhotos() async {
    final storageRef = FirebaseStorage.instance.ref().child('photos');
    final result = await storageRef.listAll();
    return Future.wait(result.items.map((e) => e.getDownloadURL()));
  }

  Future<void> _loadImagesByTab(String tab) async {
    AssetPathEntity? album;

    if (tab == 'Screenshots') {
      album = albums.firstWhere(
        (a) => a.name.toLowerCase().contains('screenshot'),
        orElse: () => albums.first,
      );
    } else {
      album = albums.firstWhere(
        (a) => a.name.toLowerCase().contains('recent') || a.isAll,
        orElse: () => albums.first,
      );
    }

    final fetchedImages = await album.getAssetListPaged(page: 0, size: 100);
    final List<Uint8List> fetchedThumbnails =
        (await Future.wait(
          fetchedImages.map(
            (asset) =>
                asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
          ),
        )).whereType<Uint8List>().toList();

    final firebaseUrls = await _fetchFirebasePhotos();

    setState(() {
      currentTab = tab;
      images = fetchedImages;
      thumbnails = fetchedThumbnails;
      firebaseImageUrls = firebaseUrls;
      selectedAsset = null;
      selectedFirebaseUrl = null;
    });
  }

  Future<File> _downloadImageFromFirebase(String url) async {
    final response = await http.get(Uri.parse(url));
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(
      directory.path,
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final file = File(filePath);
    return file.writeAsBytes(response.bodyBytes);
  }

  Widget _tabButton(String label, IconData icon) {
    final selected = label == currentTab;
    return GestureDetector(
      onTap: () => _loadImagesByTab(label),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: selected ? Colors.black : Colors.grey.shade200,
            child: Icon(icon, color: selected ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.black : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOverlay(bool isSelected) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isSelected ? 1.0 : 0.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black26,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.check_circle, color: Colors.white, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Select Photos",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.black)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (selectedAsset != null) {
                final file = await selectedAsset!.originFile;
                if (file != null && context.mounted) {
                  final xFile = XFile(file.path);
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddItemDetailsScreen(imageFile: xFile),
                    ),
                  );
                }
              } else if (selectedFirebaseUrl != null) {
                final file = await _downloadImageFromFirebase(
                  selectedFirebaseUrl!,
                );
                final xFile = XFile(file.path);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddItemDetailsScreen(imageFile: xFile),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select a photo")),
                );
              }
            },
            child: const Text("Next", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _tabButton("Recently", Icons.image),
              _tabButton("Screenshots", Icons.phone_iphone),
              _tabButton("Favorites", Icons.favorite_border),
            ],
          ),
          const Divider(height: 24),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: images.length + firebaseImageUrls.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                if (index < images.length) {
                  final asset = images[index];
                  final isSelected = asset == selectedAsset;
                  final thumbData = thumbnails[index];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAsset = asset;
                        selectedFirebaseUrl = null;
                      });
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: MemoryImage(thumbData),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        _buildImageOverlay(isSelected),
                      ],
                    ),
                  );
                } else {
                  final imageUrl = firebaseImageUrls[index - images.length];
                  final isSelected = selectedFirebaseUrl == imageUrl;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAsset = null;
                        selectedFirebaseUrl = imageUrl;
                      });
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        _buildImageOverlay(isSelected),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
