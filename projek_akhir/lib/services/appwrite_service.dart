import 'package:appwrite/appwrite.dart';
// import 'package:appwrite/models.dart';

class AppwriteService {
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  static const String projectId = 'kulinerkudb'; // Replace with your project ID
  static const String databaseId = 'kulinerku_db';
  static const String kulinerCollectionId = 'kuliner_collection';
  static const String bucketId = 'kuliner_images';

  static Client? _client;
  static Account? _account;
  static Databases? _databases;
  static Storage? _storage;

  static Client get client {
    _client ??= Client()
        .setEndpoint(endpoint)
        .setProject(projectId);
    return _client!;
  }

  static Account get account {
    _account ??= Account(client);
    return _account!;
  }

  static Databases get databases {
    _databases ??= Databases(client);
    return _databases!;
  }

  static Storage get storage {
    _storage ??= Storage(client);
    return _storage!;
  }
}
