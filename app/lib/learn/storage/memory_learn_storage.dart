import 'learn_storage.dart';

class MemoryLearnStorage implements LearnStorage {
  MemoryLearnStorage([Map<String, String>? initialData])
    : _store = Map<String, String>.from(initialData ?? {});

  final Map<String, String> _store;

  @override
  Future<String?> read(String key) async {
    return _store[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  void clear() {
    _store.clear();
  }
}
