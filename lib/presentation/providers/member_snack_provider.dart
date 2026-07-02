import 'package:flutter/foundation.dart';
import '../../data/models/member_model.dart';
import '../../data/models/snack_model.dart';
import '../../data/repositories/member_snack_repository.dart';

// ════════════════════════════════════════════════════════════
//  Member Provider
// ════════════════════════════════════════════════════════════
class MemberProvider extends ChangeNotifier {
  final MemberRepository _repo = MemberRepository();

  List<MemberModel> _members = [];
  List<MemberModel> _filtered = [];
  bool _loading = false;
  String? _error;
  String _search = '';
  Map<String, dynamic> _summary = {};

  List<MemberModel> get members =>
      _filtered.isEmpty && _search.isEmpty ? _members : _filtered;
  bool get isLoading => _loading;
  String? get error => _error;
  Map<String, dynamic> get summary => _summary;

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    try {
      _members = await _repo.getAll();
      _summary = await _repo.getSummary();
      _filtered = [];
      _search = '';
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    _search = query;
    if (query.isEmpty) {
      _filtered = [];
    } else {
      _filtered = await _repo.search(query);
    }
    notifyListeners();
  }

  Future<MemberModel?> getByCode(String code) => _repo.getByCode(code);

  Future<String> generateCode() => _repo.generateCode();

  Future<bool> addMember(MemberModel member) async {
    try {
      await _repo.insert(member);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMember(MemberModel member) async {
    try {
      await _repo.update(member);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMember(int id) async {
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
}

// ════════════════════════════════════════════════════════════
//  Snack Provider
// ════════════════════════════════════════════════════════════
class SnackProvider extends ChangeNotifier {
  final SnackRepository _repo = SnackRepository();

  List<SnackModel> _snacks = [];
  List<SnackModel> _filtered = [];
  List<String> _categories = ['Semua'];
  String _selectedCat = 'Semua';
  bool _loading = false;
  String? _error;

  List<SnackModel> get snacks => _filtered.isEmpty ? _snacks : _filtered;
  List<String> get categories => _categories;
  String get selectedCat => _selectedCat;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    try {
      _snacks = await _repo.getAll();
      final cats = await _repo.getCategories();
      _categories = ['Semua', ...cats];
      _filtered = [];
      _selectedCat = 'Semua';
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> filterByCategory(String cat) async {
    _selectedCat = cat;
    if (cat == 'Semua') {
      _filtered = [];
    } else {
      _filtered = await _repo.getAll(category: cat);
    }
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _filtered = [];
    } else {
      _filtered = await _repo.search(query);
    }
    notifyListeners();
  }

  Future<String> generateCode() => _repo.generateCode();

  Future<bool> addSnack(SnackModel snack) async {
    try {
      await _repo.insert(snack);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSnack(SnackModel snack) async {
    try {
      await _repo.update(snack);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStock(int id, int delta) async {
    try {
      await _repo.updateStock(id, delta);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSnack(int id) async {
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

  Future<List<SnackModel>> getLowStock() => _repo.getLowStock();
}
