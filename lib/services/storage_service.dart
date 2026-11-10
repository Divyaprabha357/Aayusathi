/// Abstract service interface for persistence and key-value storage.
abstract class StorageService {
  Future<void> init();
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> remove(String key);
  Future<void> clear();
}
