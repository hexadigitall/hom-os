import 'dart:math';
import 'persistence_service.dart';
import '../models/payments.dart';
import '../models/reconciliation.dart';
import 'reconciliation_store.dart';

class PaymentStore {
  // ===================== VIRTUAL ACCOUNTS =====================
  static final List<VirtualAccount> _virtualAccounts = [];

  static List<VirtualAccount> get virtualAccounts => List.unmodifiable(_virtualAccounts);
  static List<VirtualAccount> get activeVirtualAccounts => _virtualAccounts.where((v) => v.status == 'active').toList();
  static List<VirtualAccount> get matchedVirtualAccounts => _virtualAccounts.where((v) => v.status == 'matched').toList();

  // ===================== POS TERMINALS =====================
  static final List<PosTerminal> _posTerminals = [];

  static List<PosTerminal> get posTerminals => List.unmodifiable(_posTerminals);
  static List<PosTerminal> get activePosTerminals => _posTerminals.where((p) => p.status == 'active').toList();

  // ===================== POS SETTLEMENTS =====================
  static final List<PosSettlement> _posSettlements = [];

  static List<PosSettlement> get posSettlements => List.unmodifiable(_posSettlements);
  static List<PosSettlement> get pendingSettlements => _posSettlements.where((s) => s.status == 'pending').toList();

  static Future<void> init() async {
    final va = PersistenceService.loadList('pmt_virtual_accounts', VirtualAccount.fromJson);
    if (va != null) { _virtualAccounts.addAll(va); } else { _generateSampleVAs(); }
    final pt = PersistenceService.loadList('pmt_pos_terminals', PosTerminal.fromJson);
    if (pt != null) { _posTerminals.addAll(pt); } else { _generateSamplePOS(); }
    final ps = PersistenceService.loadList('pmt_pos_settlements', PosSettlement.fromJson);
    if (ps != null) { _posSettlements.addAll(ps); } else { _generateSampleSettlements(); }
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('pmt_virtual_accounts', _virtualAccounts, (e) => e.toJson());
    await PersistenceService.saveList('pmt_pos_terminals', _posTerminals, (e) => e.toJson());
    await PersistenceService.saveList('pmt_pos_settlements', _posSettlements, (e) => e.toJson());
  }

  // ===================== VIRTUAL ACCOUNT CRUD =====================

  static VirtualAccount generateVirtualAccount({
    required String bookingId,
    required String guestName,
    required int amount,
  }) {
    final id = 'va_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    final banks = ['Wema Bank', 'Providus Bank', 'Zenith Bank', 'Access Bank'];
    final bank = banks[Random().nextInt(banks.length)];
    final acctNum = (1000000000 + _virtualAccounts.length + Random().nextInt(899999999)).toString();
    final va = VirtualAccount(
      id: id,
      bookingId: bookingId,
      guestName: guestName,
      bankName: bank,
      accountNumber: acctNum,
      accountName: 'HOM Hotel / $guestName',
      amount: amount,
      status: 'active',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
    _virtualAccounts.insert(0, va);
    _save();
    return va;
  }

  static Future<void> updateVirtualAccount(String id, VirtualAccount updated) async {
    final i = _virtualAccounts.indexWhere((v) => v.id == id);
    if (i >= 0) { _virtualAccounts[i] = updated; await _save(); }
  }

  static Future<void> markVirtualAccountMatched(String id) async {
    final i = _virtualAccounts.indexWhere((v) => v.id == id);
    if (i >= 0) { _virtualAccounts[i].status = 'matched'; await _save(); }
  }

  static Future<void> removeVirtualAccount(String id) async {
    _virtualAccounts.removeWhere((v) => v.id == id);
    await _save();
  }

  // ===================== POS TERMINAL CRUD =====================

  static Future<void> addPosTerminal(PosTerminal t) async {
    _posTerminals.add(t);
    await _save();
  }

  static Future<void> updatePosTerminal(String id, PosTerminal updated) async {
    final i = _posTerminals.indexWhere((t) => t.id == id);
    if (i >= 0) { _posTerminals[i] = updated; await _save(); }
  }

  static Future<void> togglePosTerminalStatus(String id) async {
    final i = _posTerminals.indexWhere((t) => t.id == id);
    if (i >= 0) {
      _posTerminals[i].status = _posTerminals[i].status == 'active' ? 'inactive' : 'active';
      await _save();
    }
  }

  static Future<void> removePosTerminal(String id) async {
    _posTerminals.removeWhere((t) => t.id == id);
    await _save();
  }

  // ===================== POS SETTLEMENT CRUD =====================

  static Future<void> addPosSettlement(PosSettlement s) async {
    _posSettlements.insert(0, s);
    await _save();
  }

  static Future<void> updatePosSettlement(String id, PosSettlement updated) async {
    final i = _posSettlements.indexWhere((s) => s.id == id);
    if (i >= 0) { _posSettlements[i] = updated; await _save(); }
  }

  static Future<void> updateSettlementStatus(String id, String status) async {
    final i = _posSettlements.indexWhere((s) => s.id == id);
    if (i >= 0) { _posSettlements[i].status = status; await _save(); }
  }

  static Future<void> removePosSettlement(String id) async {
    _posSettlements.removeWhere((s) => s.id == id);
    await _save();
  }

  // ===================== SPLIT PAYMENT INTEGRATION =====================

  static Future<SplitPayment> createSplitPayment({
    required String bankTransactionId,
    required List<SplitAllocation> allocations,
  }) async {
    final sp = SplitPayment(
      id: 'sp_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
      bankTransactionId: bankTransactionId,
      allocations: allocations,
    );
    await ReconciliationStore.addSplit(sp);
    return sp;
  }

  // ===================== AUTO-MATCH ENHANCEMENT =====================

  static List<PotentialMatch> findVirtualAccountMatches(BankTransaction txn) {
    final suggestions = <PotentialMatch>[];
    final desc = txn.description.toLowerCase();

    for (final va in _virtualAccounts.where((v) => v.status == 'active')) {
      if (desc.contains(va.accountNumber)) {
        suggestions.add(PotentialMatch(
          entityType: MatchEntityType.booking,
          entityId: va.bookingId,
          label: '${va.guestName} — VA ${va.accountNumber}',
          amount: va.amount.toDouble(),
          confidence: 0.95,
          reason: 'Virtual account match',
        ));
      } else if ((txn.amount - va.amount).abs() < 500) {
        suggestions.add(PotentialMatch(
          entityType: MatchEntityType.booking,
          entityId: va.bookingId,
          label: '${va.guestName} — VA ${va.accountNumber}',
          amount: va.amount.toDouble(),
          confidence: 0.7,
          reason: 'Amount proximity match (₦${(txn.amount - va.amount).abs().toStringAsFixed(0)} diff)',
        ));
      }
    }
    return suggestions;
  }

  // ===================== SAMPLE DATA =====================

  static void _generateSampleVAs() {
    final rng = Random(123);
    final now = DateTime.now();
    final banks = ['Wema Bank', 'Providus Bank', 'Zenith Bank'];

    for (var i = 0; i < 4; i++) {
      final d = now.subtract(Duration(days: rng.nextInt(10)));
      _virtualAccounts.add(VirtualAccount(
        id: 'va_sample_$i',
        bookingId: 'b_sample_$i',
        guestName: ['Chidi Okonkwo', 'Amina Yusuf', 'John Okafor', 'Chioma Eze'][i],
        bankName: banks[i % 3],
        accountNumber: '123${(10000000 + i * 12345).toString()}',
        accountName: 'HOM Hotel / ${['Chidi Okonkwo', 'Amina Yusuf', 'John Okafor', 'Chioma Eze'][i]}',
        amount: [50000, 75000, 35000, 120000][i],
        status: i < 2 ? 'active' : 'matched',
        createdAt: d,
        expiresAt: d.add(const Duration(days: 7)),
      ));
    }
  }

  static void _generateSamplePOS() {
    _posTerminals.addAll([
      PosTerminal(id: 'pos_1', terminalId: 'TML-7812-A', bankName: 'FirstBank', merchantCode: 'MCH-001', status: 'active', addedAt: DateTime.now().subtract(const Duration(days: 90))),
      PosTerminal(id: 'pos_2', terminalId: 'TML-4529-B', bankName: 'GTBank', merchantCode: 'MCH-001', status: 'active', addedAt: DateTime.now().subtract(const Duration(days: 60))),
      PosTerminal(id: 'pos_3', terminalId: 'TML-1133-C', bankName: 'Access Bank', merchantCode: 'MCH-002', status: 'inactive', addedAt: DateTime.now().subtract(const Duration(days: 30))),
    ]);
  }

  static void _generateSampleSettlements() {
    final rng = Random(456);
    final now = DateTime.now();
    final statuses = ['settled', 'settled', 'pending', 'pending'];

    for (var i = 0; i < 6; i++) {
      final d = now.subtract(Duration(days: rng.nextInt(14)));
      _posSettlements.add(PosSettlement(
        id: 'pos_settle_$i',
        terminalId: ['pos_1', 'pos_2', 'pos_1', 'pos_2', 'pos_1', 'pos_3'][i],
        terminalRef: 'STL${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}$i',
        amount: (rng.nextInt(200) + 50) * 1000,
        date: d,
        status: statuses[i % statuses.length],
        note: i == 4 ? 'Delayed settlement — bank holiday' : null,
      ));
    }
  }
}
