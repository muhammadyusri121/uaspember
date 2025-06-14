import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:kulinerku/models/kuliner_model.dart';
import 'package:kulinerku/services/appwrite_service.dart';
import 'dart:io';

class KulinerProvider with ChangeNotifier {
  List<KulinerModel> _kuliners = [];
  List<KulinerModel> _filteredKuliners = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<KulinerModel> get kuliners => _filteredKuliners;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> fetchKuliners() async {
    _setLoading(true);
    try {
      final response = await AppwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.kulinerCollectionId,
        queries: [
          Query.orderDesc('\$createdAt'),
        ],
      );

      _kuliners = response.documents
          .map((doc) => KulinerModel.fromMap(doc.data))
          .toList();
      
      _applySearch();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> createKuliner(KulinerModel kuliner, File? imageFile) async {
    _setLoading(true);
    try {
      String? imageUrl;
      String? imageId;

      // Upload image if provided
      if (imageFile != null) {
        final file = await AppwriteService.storage.createFile(
          bucketId: AppwriteService.bucketId,
          fileId: ID.unique(),
          file: InputFile.fromPath(path: imageFile.path),
        );
        
        imageId = file.$id;
        imageUrl = '${AppwriteService.client.endPoint}/storage/buckets/${AppwriteService.bucketId}/files/$imageId/view?project=${AppwriteService.projectId}';
      }

      final kulinerData = kuliner.copyWith(
        imageUrl: imageUrl,
        imageId: imageId,
      );

      final response = await AppwriteService.databases.createDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.kulinerCollectionId,
        documentId: ID.unique(),
        data: kulinerData.toMap(),
      );

      final newKuliner = KulinerModel.fromMap(response.data);
      _kuliners.insert(0, newKuliner);
      _applySearch();
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateKuliner(KulinerModel kuliner) async {
    _setLoading(true);
    try {
      await AppwriteService.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.kulinerCollectionId,
        documentId: kuliner.id,
        data: kuliner.toMap(),
      );

      final index = _kuliners.indexWhere((k) => k.id == kuliner.id);
      if (index != -1) {
        _kuliners[index] = kuliner;
        _applySearch();
      }
      
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteKuliner(String id) async {
    _setLoading(true);
    try {
      // Find the kuliner to get image ID
      final kuliner = _kuliners.firstWhere((k) => k.id == id);
      
      // Delete image if exists
      if (kuliner.imageId != null) {
        try {
          await AppwriteService.storage.deleteFile(
            bucketId: AppwriteService.bucketId,
            fileId: kuliner.imageId!,
          );
        } catch (e) {
          // Continue even if image deletion fails
        }
      }

      await AppwriteService.databases.deleteDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.kulinerCollectionId,
        documentId: id,
      );

      _kuliners.removeWhere((k) => k.id == id);
      _applySearch();
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void searchKuliners(String query) {
    _searchQuery = query;
    _applySearch();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredKuliners = List.from(_kuliners);
    } else {
      _filteredKuliners = _kuliners
          .where((kuliner) =>
              kuliner.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              kuliner.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
