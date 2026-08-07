import 'persistence_service.dart';
import 'store_sync.dart';
import '../models/subscription.dart';

class SubscriptionStore {
  static final List<Subscription> _subscriptions = [];

  // Offline-first cloud sync for the subscriptions collection.
  static final StoreSync<Subscription> sync = _initSync();

  static StoreSync<Subscription> _initSync() {
    final s = StoreSync<Subscription>(
      collection: 'hom_subscriptions', target: _subscriptions,
      fromJson: Subscription.fromJson, toJson: (e) => e.toJson(),
      cacheKey: 'sub_subscriptions',
    );
    CloudSync.register(s);
    return s;
  }

  static Future<void> load() async {
    if (_subscriptions.isNotEmpty) return;
    final s = PersistenceService.loadList('sub_subscriptions', Subscription.fromJson);
    if (s != null && s.isNotEmpty) { _subscriptions.addAll(s); } else { _seed(); }
    sync.loadMeta();
  }

  static Future<void> _save() async {
    await PersistenceService.saveList('sub_subscriptions', _subscriptions, (e) => e.toJson());
    await sync.push();
  }

  static void _seed() {
    _subscriptions.addAll([
      Subscription(
        id: 'sub1', name: 'DSTV Premium Business', provider: 'Multichoice Nigeria',
        category: 'TV & Entertainment', amount: 185000,
        billingCycle: BillingCycle.monthly,
        startDate: DateTime(2025, 1, 1),
        contactInfo: '0700-MULTICHOICE',
        notes: 'Premium bouquet — 12 rooms + lounge + bar',
      ),
      Subscription(
        id: 'sub2', name: 'Enterprise Fiber Internet', provider: 'MTN Business',
        category: 'Internet', amount: 350000,
        billingCycle: BillingCycle.monthly,
        startDate: DateTime(2025, 6, 15),
        contactInfo: 'mtnbusiness@mtn.com',
        notes: '100Mbps dedicated fiber — 2yr contract',
      ),
      Subscription(
        id: 'sub3', name: 'MCSN Music License', provider: 'MCSN',
        category: 'License & Permits', amount: 450000,
        billingCycle: BillingCycle.annual,
        startDate: DateTime(2025, 3, 1),
        status: SubscriptionStatus.expiring,
        contactInfo: 'info@mcson.org',
        notes: 'Annual copyright license for background music',
      ),
      Subscription(
        id: 'sub4', name: 'Backup LTE Internet', provider: 'Airtel Business',
        category: 'Internet', amount: 85000,
        billingCycle: BillingCycle.monthly,
        startDate: DateTime(2026, 2, 1),
        contactInfo: '0800-AIRTEL-BIZ',
        notes: '4G LTE backup — 50GB data cap',
      ),
      Subscription(
        id: 'sub5', name: 'Showmax Pro Business', provider: 'Showmax / MultiChoice',
        category: 'TV & Entertainment', amount: 45000,
        billingCycle: BillingCycle.monthly,
        startDate: DateTime(2026, 5, 1),
        contactInfo: 'business@showmax.com',
        notes: 'Sports + movies package for poolside bar',
      ),
    ]);
  }

  static List<Subscription> get all => List.unmodifiable(_subscriptions);

  static double get totalMonthlyCost =>
      _subscriptions.fold(0.0, (s, sub) => s + sub.monthlyCost);

  static List<Subscription> get active =>
      _subscriptions.where((s) => s.status == SubscriptionStatus.active).toList();

  static List<Subscription> get expiringSoon =>
      _subscriptions.where((s) => s.status == SubscriptionStatus.expiring).toList();

  static List<Subscription> get expired =>
      _subscriptions.where((s) => s.status == SubscriptionStatus.expired).toList();

  static Future<void> add(Subscription s) async { _subscriptions.insert(0, s); await _save(); }

  static Future<void> update(String id, Subscription updated) async {
    final i = _subscriptions.indexWhere((s) => s.id == id);
    if (i >= 0) { _subscriptions[i] = updated; await _save(); }
  }

  static Future<void> remove(String id) async { _subscriptions.removeWhere((s) => s.id == id); await _save(); }

  static int _counter = 0;
  static String genId() => 'sub_${DateTime.now().millisecondsSinceEpoch}_${++_counter}';
}
