import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:kulinerku/providers/kuliner_provider.dart';
import 'package:kulinerku/providers/auth_provider.dart';
import 'package:kulinerku/providers/network_provider.dart';
import 'package:kulinerku/models/kuliner_model.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';

class AddKulinerScreen extends StatefulWidget {
  const AddKulinerScreen({super.key});

  @override
  State<AddKulinerScreen> createState() => _AddKulinerScreenState();
}

class _AddKulinerScreenState extends State<AddKulinerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _imageFile;
  double _rating = 3.0;
  double? _latitude;
  double? _longitude;
  String? _locationAddress;
  bool _isLoadingLocation = false;

  final ImagePicker _picker = ImagePicker();
  final loc.Location _location = loc.Location();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Fungsi untuk mendapatkan alamat dari koordinat
  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        localeIdentifier: 'id_ID', // Gunakan locale Indonesia
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return _formatAddress(place);
      }
      return 'Lokasi tidak ditemukan';
    } catch (e) {
      return 'Gagal mendapatkan alamat: $e';
    }
  }

  // Format alamat sesuai kebutuhan
  String _formatAddress(Placemark place) {
    List<String> addressParts = [];

    if (place.street != null && place.street!.isNotEmpty)
      addressParts.add(place.street!);

    if (place.subLocality != null && place.subLocality!.isNotEmpty)
      addressParts.add(place.subLocality!);

    if (place.locality != null && place.locality!.isNotEmpty)
      addressParts.add(place.locality!);

    if (place.subAdministrativeArea != null &&
        place.subAdministrativeArea!.isNotEmpty)
      addressParts.add(place.subAdministrativeArea!);

    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty)
      addressParts.add(place.administrativeArea!);

    return addressParts.join(', ');
  }

  Future<void> _pickImageFromCamera() async {
    final networkProvider =
        Provider.of<NetworkProvider>(context, listen: false);

    if (!networkProvider.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Camera capture requires internet connection for upload'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Request camera permission
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });

        // Get location when taking photo from camera
        await _getCurrentLocation();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    final networkProvider =
        Provider.of<NetworkProvider>(context, listen: false);

    if (!networkProvider.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Gallery selection requires internet connection for upload'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationAddress = null; // Reset alamat saat mengambil lokasi baru
    });

    try {
      // Check location permission using Permission Handler
      final locationStatus = await Permission.location.request();
      if (locationStatus != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Location permission is required for camera capture')),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Check if location services are enabled using Location package
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      // Double-check permissions with location package
      loc.PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required')),
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      // Set accuracy to high
      await _location.changeSettings(accuracy: loc.LocationAccuracy.high);

      // Get current position using Location package
      loc.LocationData locationData = await _location.getLocation();

      setState(() {
        _latitude = locationData.latitude;
        _longitude = locationData.longitude;
      });

      // Mendapatkan alamat dari koordinat
      if (_latitude != null && _longitude != null) {
        final address = await getAddressFromLatLng(_latitude!, _longitude!);

        if (mounted) {
          setState(() {
            _locationAddress = address;
            _isLoadingLocation = false;
          });
        }
      } else {
        setState(() {
          _isLoadingLocation = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi berhasil ditangkap'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mendapatkan lokasi: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                subtitle: const Text('Ambil dengan lokasi'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveKuliner() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final kulinerProvider =
        Provider.of<KulinerProvider>(context, listen: false);
    final networkProvider =
        Provider.of<NetworkProvider>(context, listen: false);

    if (_imageFile != null && !networkProvider.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Internet connection required to upload image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Membuat objek KulinerModel (Perbarui model Anda untuk menyimpan alamat jika diperlukan)
    final kuliner = KulinerModel(
      id: '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      rating: _rating,
      latitude: _latitude,
      longitude: _longitude,
      // address: _locationAddress, // Tambahkan field ini di model jika ingin menyimpan alamat
      userId: authProvider.user!.$id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await kulinerProvider.createKuliner(kuliner, _imageFile);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kuliner berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kulinerProvider.error ?? 'Gagal menambahkan kuliner'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Kuliner'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : InkWell(
                        onTap: _showImageSourceDialog,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Ketuk untuk menambahkan gambar',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
              if (_imageFile != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: const Icon(Icons.edit),
                      label: const Text('Ubah Gambar'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _imageFile = null;
                          _latitude = null;
                          _longitude = null;
                          _locationAddress = null;
                        });
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Hapus Gambar'),
                    ),
                  ],
                ),
              ],

              // Location Info
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_locationAddress != null)
                                  Text(
                                    _locationAddress!,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Koordinat: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                  style: TextStyle(
                                      color: Colors.grey[700], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              if (_isLoadingLocation) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Mendapatkan lokasi dan alamat...'),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Form fields and button
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kuliner *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Silakan masukkan nama kuliner';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Silakan masukkan deskripsi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              const Text(
                'Rating',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Rating: ${_rating.toStringAsFixed(1)} / 5.0',
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 32),

              Consumer<KulinerProvider>(
                builder: (context, kulinerProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          kulinerProvider.isLoading ? null : _saveKuliner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: kulinerProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Simpan Kuliner',
                              style: TextStyle(fontSize: 16)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
