import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:kulinerku/models/kuliner_model.dart';
import 'package:kulinerku/providers/kuliner_provider.dart';
import 'package:kulinerku/providers/auth_provider.dart';
import 'package:kulinerku/screens/kuliner/edit_kuliner_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:geocoding/geocoding.dart';

class KulinerDetailScreen extends StatefulWidget {
  final KulinerModel kuliner;

  const KulinerDetailScreen({super.key, required this.kuliner});

  @override
  State<KulinerDetailScreen> createState() => _KulinerDetailScreenState();
}

class _KulinerDetailScreenState extends State<KulinerDetailScreen> {
  String? _address;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi format tanggal Indonesia
    initializeDateFormatting('id_ID', null);
    // Ambil alamat dari koordinat
    _getAddress();
  }

  // Ambil alamat dari koordinat
  Future<void> _getAddress() async {
    final kuliner = widget.kuliner;
    if (kuliner.latitude != null && kuliner.longitude != null) {
      setState(() {
        _isLoadingAddress = true;
      });

      try {
        final address = await getAddressFromLatLng(
          kuliner.latitude!,
          kuliner.longitude!,
        );

        if (mounted) {
          setState(() {
            _address = address;
            _isLoadingAddress = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _address = 'Tidak dapat memuat alamat';
            _isLoadingAddress = false;
          });
        }
      }
    }
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

  Future<void> _deleteKuliner(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kuliner'),
        content: Text('Anda yakin ingin menghapus "${widget.kuliner.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final kulinerProvider =
          Provider.of<KulinerProvider>(context, listen: false);
      final success = await kulinerProvider.deleteKuliner(widget.kuliner.id);

      if (context.mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kuliner berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(kulinerProvider.error ?? 'Gagal menghapus kuliner'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Format waktu ke format Indonesia dengan zona waktu WIB
  String formatIndonesianDateTime(DateTime dateTime) {
    // Konversi ke zona waktu Indonesia (WIB = UTC+7)
    final dateTimeWIB = dateTime.add(const Duration(hours: 7));

    // Format tanggal dan waktu dengan lokalisasi Indonesia
    final formatter = DateFormat('dd MMMM yyyy - HH:mm', 'id_ID');
    return '${formatter.format(dateTimeWIB)} WIB';
  }

  @override
  Widget build(BuildContext context) {
    final kuliner = widget.kuliner;
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.user?.$id == kuliner.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(kuliner.name),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            EditKulinerScreen(kuliner: kuliner),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteKuliner(context),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            if (kuliner.imageUrl != null)
              SizedBox(
                width: double.infinity,
                height: 300,
                child: CachedNetworkImage(
                  imageUrl: kuliner.imageUrl!,
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
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.restaurant, size: 64, color: Colors.grey),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating
                  Text(
                    kuliner.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: kuliner.rating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20.0,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${kuliner.rating.toStringAsFixed(1)} / 5.0',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  // Description
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kuliner.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  // Location Info
                  if (kuliner.latitude != null &&
                      kuliner.longitude != null) ...[
                    const Text(
                      'Lokasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _isLoadingAddress
                                    ? Row(
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Memuat alamat...'),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (_address != null) ...[
                                            Text(
                                              _address!,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          Text(
                                            'Koordinat: ${kuliner.latitude!.toStringAsFixed(6)}, ${kuliner.longitude!.toStringAsFixed(6)}',
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                  ],

                  // Timestamps dengan format Indonesia
                  const Text(
                    'Informasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      'Dibuat', formatIndonesianDateTime(kuliner.createdAt)),
                  _buildInfoRow('Diperbarui',
                      formatIndonesianDateTime(kuliner.updatedAt)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
