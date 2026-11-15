import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/campaign/data/datasources/campaign_manage_api.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';

/// Satu transaksi donasi. HANYA-BACA: admin tidak bisa mengubah atau menghapus.
class AdminTxn {
  const AdminTxn({
    required this.id,
    required this.donorName,
    required this.campaignId,
    required this.campaignTitle,
    required this.category,
    required this.amount,
    required this.method,
    required this.at,
    this.provider,
    this.isLive = false,
  });

  final String id;
  final String donorName;
  final String campaignId;
  final String campaignTitle;
  final ProgramCategory category;
  final int amount;
  final PaymentMethod method;
  final String? provider;
  final DateTime at;

  /// true = donasi baru (kurang dari 1 jam yang lalu).
  final bool isLive;

  String get methodLabel =>
      provider == null ? method.label : '${method.label} • $provider';
}

/// Sumber data statistik donasi untuk dashboard admin (hanya-baca),
/// bersumber dari server: GET /api/admin/transactions (365 hari terakhir).
class AdminAnalyticsStore extends ChangeNotifier {
  AdminAnalyticsStore(this._api);

  final CampaignManageApi _api;

  List<AdminTxn> _items = const [];
  bool _loading = false;
  String? _error;

  List<AdminTxn> get all => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;

  /// Muat ulang transaksi dari server. Aman dipanggil berulang.
  Future<void> sync() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _api.list('/admin/transactions');
      final now = DateTime.now();
      _items = rows.map((j) => _toTxn(j, now)).toList()
        ..sort((a, b) => b.at.compareTo(a.at));
    } on ServerException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  AdminTxn _toTxn(Map<String, dynamic> j, DateTime now) {
    final at = DateTime.tryParse('${j['created_at']}')?.toLocal() ?? now;
    final method = PaymentMethod.values.firstWhere(
      (m) => m.name == j['payment_method'],
      orElse: () => PaymentMethod.qris,
    );
    return AdminTxn(
      id: '${j['reference'] ?? j['id']}',
      donorName: (j['donor_name'] ?? Donation.anonymousName) as String,
      campaignId: '${j['campaign_id']}',
      campaignTitle: (j['campaign_title'] ?? '') as String,
      category: ProgramCategory.fromKey((j['category'] ?? 'masjid') as String),
      amount: (j['amount'] as num?)?.toInt() ?? 0,
      method: method,
      provider: j['payment_provider'] as String?,
      at: at,
      isLive: now.difference(at).inMinutes < 60,
    );
  }

  /// Total donasi per hari (periode <= 62 hari) atau per bulan (lebih panjang).
  (List<double>, List<String>) timeSeries(DateTime start, DateTime end) {
    final txns = between(start, end);
    final days = end.difference(start).inDays;
    final values = <double>[];
    final labels = <String>[];
    if (days <= 62) {
      for (var i = 0; i < days; i++) {
        final d = start.add(Duration(days: i));
        final next = d.add(const Duration(days: 1));
        var sum = 0;
        for (final t in txns) {
          if (!t.at.isBefore(d) && t.at.isBefore(next)) sum += t.amount;
        }
        values.add(sum.toDouble());
        labels.add(_dm.format(d));
      }
    } else {
      var m = DateTime(start.year, start.month);
      final last = DateTime(end.year, end.month);
      while (!m.isAfter(last)) {
        final next = DateTime(m.year, m.month + 1);
        var sum = 0;
        for (final t in txns) {
          if (!t.at.isBefore(m) && t.at.isBefore(next)) sum += t.amount;
        }
        values.add(sum.toDouble());
        labels.add(_mon.format(m));
        m = next;
      }
    }
    return (values, labels);
  }

  static final DateFormat _dm = DateFormat('d MMM', 'id_ID');
  static final DateFormat _mon = DateFormat('MMM yy', 'id_ID');

  // ===== Ringkasan =====
  int sum(Iterable<AdminTxn> txns) => txns.fold<int>(0, (a, t) => a + t.amount);

  List<AdminTxn> between(DateTime from, DateTime to) =>
      _items.where((t) => !t.at.isBefore(from) && t.at.isBefore(to)).toList();

  /// Total per kategori.
  Map<ProgramCategory, int> byCategory(Iterable<AdminTxn> txns) {
    final map = {for (final c in ProgramCategory.values) c: 0};
    for (final t in txns) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  /// Total per metode pembayaran (QRIS / E-Wallet / Transfer).
  Map<PaymentMethod, int> byMethod(Iterable<AdminTxn> txns) {
    final map = {for (final m in PaymentMethod.values) m: 0};
    for (final t in txns) {
      map[t.method] = (map[t.method] ?? 0) + t.amount;
    }
    return map;
  }

  /// Total per program, terbesar dulu.
  List<MapEntry<String, int>> byCampaign(Iterable<AdminTxn> txns) {
    final map = <String, int>{};
    for (final t in txns) {
      map[t.campaignId] = (map[t.campaignId] ?? 0) + t.amount;
    }
    final list = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  /// Donatur teratas (tanpa "Hamba Allah").
  List<MapEntry<String, int>> topDonors(Iterable<AdminTxn> txns, {int limit = 5}) {
    final map = <String, int>{};
    for (final t in txns) {
      if (t.donorName == Donation.anonymousName) continue;
      map[t.donorName] = (map[t.donorName] ?? 0) + t.amount;
    }
    final list = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }
}