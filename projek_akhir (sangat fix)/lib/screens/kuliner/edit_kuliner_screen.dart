import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:kulinerku/models/kuliner_model.dart';
import 'package:kulinerku/providers/kuliner_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geocoding/geocoding.dart'; // Import geocoding package

class EditKulinerScreen extends StatefulWidget {
  final KulinerModel kuliner;

  const EditKulinerScreen({super.key, required this.kuliner});

  @override
  State<EditKulinerScreen> createState() => _EditKulinerScreenState();
}

class _EditKulinerScreenState extends State<EditKulinerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late double _rating;
  String? _locationAddress;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.kuliner.name);
    _descriptionController =
        TextEditingController(text: widget.kuliner.description);
    _rating = widget.kuliner.rating;

    // Mendapatkan alamat dari koordinat jika tersedia
    if (widget.kuliner.latitude != null && widget.kuliner.longitude != null) {
      _getAddressFromLatLng(
          widget.kuliner.latitude!, widget.kuliner.longitude!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Fungsi untuk mendapatkan alamat dari koordinat
  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        localeIdentifier: 'id_ID', // Gunakan locale Indonesia
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _locationAddress = _formatAddress(place);
            _isLoadingAddress = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _locationAddress = 'Lokasi tidak ditemukan';
            _isLoadingAddress = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationAddress = 'Gagal mendapatkan alamat: $e';
          _isLoadingAddress = false;
        });
      }
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

  Future<void> _updateKuliner() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final kulinerProvider =
        Provider.of<KulinerProvider>(context, listen: false);

    final updatedKuliner = widget.kuliner.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      rating: _rating,
      updatedAt: DateTime.now(),
    );

    final success = await kulinerProvider.updateKuliner(updatedKuliner);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kuliner berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kulinerProvider.error ?? 'Gagal memperbarui kuliner'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gunakan AppBar standar
      appBar: AppBar(
        title: const Text('Edit Kuliner'),
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
              // Current Image Display
              if (widget.kuliner.imageUrl != null) ...[
                const Text(
                  'Gambar Kuliner',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.kuliner.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.error, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Catatan: Gambar dan lokasi tidak dapat diubah setelah dibuat',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Location Info (if available)
              if (widget.kuliner.latitude != null &&
                  widget.kuliner.longitude != null) ...[
                const Text(
                  'Lokasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
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
                                if (_isLoadingAddress)
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
                                      const Text('Mendapatkan alamat...'),
                                    ],
                                  )
                                else if (_locationAddress != null)
                                  Text(
                                    _locationAddress!,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Koordinat: ${widget.kuliner.latitude!.toStringAsFixed(6)}, ${widget.kuliner.longitude!.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Name Field
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

              // Description Field
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

              // Rating Section
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

              // Update Button
              Consumer<KulinerProvider>(
                builder: (context, kulinerProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          kulinerProvider.isLoading ? null : _updateKuliner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: kulinerProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Perbarui Kuliner',
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
