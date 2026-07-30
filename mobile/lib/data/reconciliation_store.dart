import 'dart:math';
import 'persistence_service.dart';
import '../models/reconciliation.dart';
import '../models/expenditure.dart';
import 'expenditure_store.dart';
import 'payment_store.dart';
import '../main.dart' as app;

class ReconciliationStore {
  static final List<BankTransaction> _transactions = [];
  static final List<ReconciliationMatch> _matches = [];
  static final List<SplitPayment> _splits = [];

  static Future<void> init() async {
    if (_transactions.isNotEmpty) return;
    final t = PersistenceService.loadList('rec_transactions', BankTransaction.fromJson);
    if (t != null && t.isNotEmpty) { _transactions.addAll(t); } else { _generateSampleData(); }
    final m = PersistenceService.loadList('rec_matches', ReconciliationMatch.fromJson);
    if (m != null) { _matches.addAll(m); }
    final s = PersistenceService.loadList('rec_splits', SplitPayment.fromJson);
    if (s != null) { _splits.addAll(s); }
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('rec_transactions', _transactions, (e) => e.toJson());
    await PersistenceService.saveList('rec_matches', _matches, (e) => e.toJson());
    await PersistenceService.saveList('rec_splits', _splits, (e) => e.toJson());
  }

  static List<BankTransaction> get transactions => List.unmodifiable(_transactions);
  static List<ReconciliationMatch> get matches => List.unmodifiable(_matches);
  static List<SplitPayment> get splits => List.unmodifiable(_splits);

  static List<BankTransaction> get unmatched =>
      _transactions.where((t) => !_matches.any((m) => m.bankTransactionId == t.id)).toList();

  static List<BankTransaction> get matchedTransactions =>
      _transactions.where((t) => _matches.any((m) => m.bankTransactionId == t.id)).toList();

  static double get totalMatchedAmount =>
      _matches.fold(0.0, (s, m) => s + m.matchedAmount);

  static double get totalUnmatchedAmount =>
      unmatched.fold(0.0, (s, t) => s + t.amount);

  static List<ReconciliationMatch> matchesForTransaction(String btId) =>
      _matches.where((m) => m.bankTransactionId == btId).toList();

  static List<BankTransaction> searchTransactions(String query) {
    final q = query.toLowerCase();
    return _transactions.where((t) =>
        t.description.toLowerCase().contains(q) ||
        (t.reference?.toLowerCase().contains(q) ?? false)).toList();
  }

  static Future<void> addTransaction(BankTransaction t) async { _transactions.add(t); await _save(); }

  static Future<void> updateTransaction(String id, BankTransaction updated) async {
    final i = _transactions.indexWhere((t) => t.id == id);
    if (i >= 0) { _transactions[i] = updated; await _save(); }
  }

  static Future<void> addTransactions(List<BankTransaction> txns) async { _transactions.addAll(txns); await _save(); }

  static Future<ReconciliationMatch> addMatch(ReconciliationMatch m) async {
    _matches.insert(0, m);
    await _save();
    return m;
  }

  static Future<void> removeMatch(String id) async { _matches.removeWhere((m) => m.id == id); await _save(); }

  static Future<void> addSplit(SplitPayment sp) async { _splits.insert(0, sp); await _save(); }

  static Future<void> updateSplit(String id, SplitPayment updated) async {
    final i = _splits.indexWhere((s) => s.id == id);
    if (i >= 0) { _splits[i] = updated; await _save(); }
  }

  static Future<void> removeSplit(String id) async { _splits.removeWhere((s) => s.id == id); await _save(); }

  static Future<void> removeTransaction(String id) async {
    _matches.removeWhere((m) => m.bankTransactionId == id);
    _transactions.removeWhere((t) => t.id == id);
    await _save();
  }

  static Future<void> updateMatch(String id, ReconciliationMatch updated) async {
    final i = _matches.indexWhere((m) => m.id == id);
    if (i >= 0) { _matches[i] = updated; await _save(); }
  }

  static Future<void> clearAll() async {
    _transactions.clear();
    _matches.clear();
    _splits.clear();
    await _save();
  }

  // ===================== MATCHING ENGINE =====================

  static List<PotentialMatch> findPotentialMatches(BankTransaction txn) {
    final suggestions = <PotentialMatch>[];
    final desc = txn.description.toLowerCase();

    for (final b in app.HOMData.bookings) {
      if (b.phone.isNotEmpty && desc.contains(b.phone)) {
        suggestions.add(PotentialMatch(
          entityType: MatchEntityType.booking, entityId: b.id,
          label: '${b.guest} — Room ${b.room}',
          amount: b.amount.toDouble(), confidence: 0.9,
          reason: 'Phone match',
        ));
      } else if (desc.contains(b.guest.toLowerCase().split(' ').first)) {
        suggestions.add(PotentialMatch(
          entityType: MatchEntityType.booking, entityId: b.id,
          label: '${b.guest} — Room ${b.room}',
          amount: b.amount.toDouble(), confidence: 0.6,
          reason: 'Name match',
        ));
      }
      if (txn.reference != null && b.id.contains(txn.reference!)) {
        suggestions.add(PotentialMatch(
          entityType: MatchEntityType.booking, entityId: b.id,
          label: '${b.guest} — Room ${b.room}',
          amount: b.amount.toDouble(), confidence: 0.95,
          reason: 'Reference match',
        ));
      }
    }

    for (final e in ExpenditureStore.all) {
      if (txn.reference != null && e.receiptRef == txn.reference) {
        suggestions.add(PotentialMatch(
          entityType: MatchEntityType.expenditure, entityId: e.id,
          label: e.description.isNotEmpty ? e.description : e.category.displayName,
          amount: e.amount, confidence: 0.95,
          reason: 'Receipt ref match',
        ));
      } else if (e.vendor.isNotEmpty && desc.contains(e.vendor.toLowerCase())) {
        suggestions.add(PotentialMatch(
          entityType: MatchEntityType.expenditure, entityId: e.id,
          label: e.description.isNotEmpty ? e.description : e.category.displayName,
          amount: e.amount, confidence: 0.7,
          reason: 'Vendor name match',
        ));
      }
    }

    suggestions.addAll(PaymentStore.findVirtualAccountMatches(txn));

    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions.take(10).toList();
  }

  static String genMatchId() =>
      'rm_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

  // ===================== SAMPLE DATA =====================

  static void _generateSampleData() {
    final rng = Random(42);
    final now = DateTime.now();

    final banks = ['GTBank', 'Access Bank', 'FirstBank'];

    for (var i = 29; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final bank = banks[i % 3];

      if (i % 2 == 0 && i < 25) {
        final booking = app.HOMData.bookings.isNotEmpty ? app.HOMData.bookings[0] : null;
        final guest = app.HOMData.bookings.isNotEmpty
            ? app.HOMData.bookings[rng.nextInt(app.HOMData.bookings.length)].guest : 'Guest';
        _transactions.add(BankTransaction(
          id: 'bt_sample_in_$i', date: d,
          description: 'POS/L3112345/$guest/Room Booking Payment/${_ref(rng)}',
          amount: (rng.nextInt(30) + 15) * 1000.0,
          reference: _ref(rng), balance: rng.nextInt(500000) + 200000 + i * 1000.0,
          source: bank, type: 'CR',
        ));

        if (booking != null && i == 0) {
          _matches.insert(0, ReconciliationMatch(
            id: genMatchId(), bankTransactionId: 'bt_sample_in_$i',
            entityType: MatchEntityType.booking, entityId: booking.id,
            entityLabel: '${booking.guest} — Room ${booking.room}',
            entityAmount: booking.amount.toDouble(),
            matchedAmount: (rng.nextInt(30) + 15) * 1000.0,
            confidence: 0.85, matchedAt: d,
          ));
        }
      }

      if (i % 3 == 1) {
        final cats = ExpenditureCategory.values;
        final cat = cats[rng.nextInt(cats.length)];
        _transactions.add(BankTransaction(
          id: 'bt_sample_out_$i', date: d,
          description: 'TRF/${_ref(rng)}/${cat.displayName}/${_vendor(rng)}',
          amount: (rng.nextInt(50) + 5) * 1000.0,
          reference: _ref(rng), balance: rng.nextInt(300000) + 100000,
          source: bank, type: 'DR',
        ));
      }
    }

    for (var i = 0; i < 3; i++) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: rng.nextInt(10)));
      _transactions.add(BankTransaction(
        id: 'bt_unmatched_$i', date: d,
        description: i == 0 ? 'ATM/WITHDRAWAL/Lagos' : i == 1 ? 'USSD/TRF/Chidi Okonkwo/Staff advance' : 'POS/Providus/Office Supplies Ltd',
        amount: [5000.0, 15000.0, 8500.0][i],
        reference: null, balance: rng.nextInt(200000) + 50000,
        source: banks[i % 3], type: 'DR',
      ));
    }
  }

  static String _ref(Random r) => 'REF${r.nextInt(999999).toString().padLeft(6, '0')}';
  static String _vendor(Random r) {
    const vs = ['MRS Petroleum', 'FreshFarm Ltd', 'CleanPro Supplies', 'LinenHouse Ltd', 'PHED', 'CaterPlus Ltd'];
    return vs[r.nextInt(vs.length)];
  }
}

class PotentialMatch {
  final MatchEntityType entityType;
  final String entityId;
  final String label;
  final double amount;
  final double confidence;
  final String reason;

  PotentialMatch({
    required this.entityType,
    required this.entityId,
    required this.label,
    required this.amount,
    required this.confidence,
    required this.reason,
  });
}
