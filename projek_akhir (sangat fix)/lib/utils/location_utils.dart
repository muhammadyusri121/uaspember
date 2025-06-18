import 'package:geocoding/geocoding.dart';

class LocationUtils {
  /// Mengkonversi koordinat latitude dan longitude menjadi alamat
  static Future<String> getAddressFromLatLng(
      double latitude, double longitude) async {
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

  /// Format alamat sesuai kebutuhan
  static String _formatAddress(Placemark place) {
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
}
