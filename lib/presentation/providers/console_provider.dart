import 'package:flutter/foundation.dart';
import '../../data/models/console_model.dart';
import '../../data/repositories/console_repository.dart';

class ConsoleProvider extends ChangeNotifier {
  final ConsoleRepository _repo = ConsoleRepository();

  List<ConsoleModel> _consoles = [];
  bool _isLoading = false;
  String? _error;
  Map<String, int> _statusSummary = {};

  List<ConsoleModel> get consoles => _consoles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get statusSummary => _statusSummary;

  List<ConsoleModel> get available =>
      _consoles.where((c) => c.isAvailable).toList();
  List<ConsoleModel> get playing =>
      _consoles.where((c) => c.isPlaying).toList();
  List<ConsoleModel> get reserved =>
      _consoles.where((c) => c.isReserved).toList();
  List<ConsoleModel> get maintain =>
      _consoles.where((c) => c.isMaintain).toList();

  Future<void> loadAll() async {
    _setLoading(true);
    try {
      _consoles = await _repo.getAll();
      _statusSummary = await _repo.getStatusSummary();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addConsole(ConsoleModel console) async {
    try {
      await _repo.insert(console);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateConsole(ConsoleModel console) async {
    try {
      await _repo.update(console);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(int id, String status) async {
    try {
      await _repo.updateStatus(id, status);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteConsole(int id) async {
    try {
      await _repo.delete(id);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
