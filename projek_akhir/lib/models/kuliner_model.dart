class KulinerModel {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String? imageId;
  final double? latitude;
  final double? longitude;
  final double rating;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  KulinerModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.imageId,
    this.latitude,
    this.longitude,
    required this.rating,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KulinerModel.fromMap(Map<String, dynamic> map) {
    return KulinerModel(
      id: map['\$id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      imageId: map['imageId'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      userId: map['userId'] ?? '',
      createdAt: DateTime.parse(map['\$createdAt']),
      updatedAt: DateTime.parse(map['\$updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'imageId': imageId,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'userId': userId,
    };
  }

  KulinerModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? imageId,
    double? latitude,
    double? longitude,
    double? rating,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KulinerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageId: imageId ?? this.imageId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
