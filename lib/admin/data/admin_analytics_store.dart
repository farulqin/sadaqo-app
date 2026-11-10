import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/donation/data/datasources/donation_remote_datasource.dart';
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

  /// true = donasi yang benar-benar dibuat di aplikasi pada sesi ini.
  final bool isLive;

  String get methodLabel =>
      provider == null ? method.label : '${method.label} • $provider';
}

/// Sumber data statistik donasi untuk dashboard admin (hanya-baca).
///
/// Selama backend belum ada, riwayat transaksi lama DIBANGKITKAN dari total dana
/// terkumpul tiap program (hasil jumlahnya sama persis dengan progres program),
/// lalu donasi baru dari aplikasi ikut masuk lewat [sync]. Setelah API Laravel
/// siap, ganti isi [sync] dengan GET /api/admin/transactions.
class AdminAnalyticsStore extends ChangeNotifier {
  AdminAnalyticsStore(this._campaigns, this._donations) {
    _seedHistory();
  }

  final MockCampaignStore _campaigns;
  final DonationRemoteDataSource _donations;

  final List<AdminTxn> _items = [];
  final Set<String> _liveIds = {};
  late final DateTime _seededAt;

  List<AdminTxn> get all => List.unmodifiable(_items);

  static const List<String> _names = [
    'Ahmad Fauzi', 'Siti Rahma', 'Budi Santoso', 'Nur Aini', 'Rizki Ramadhan',
    'Dewi Lestari', 'Aisyah Putri', 'Fajar Nugroho', 'Laila Hidayati',
    'Yusuf Hakim', 'Maya Anggraini', 'Hendra Wijaya', 'Putri Amelia',
    'Imam Syafi\'i', 'Rina Marlina', 'Dimas Pratama', 'Khadijah Azzahra',
    'Wahyu Hidayat', 'Siska Permata', 'Teguh Prasetyo', 'Zahra Salsabila',
    'Agus Salim', 'Fitri Handayani', 'Bagus Kurniawan', 'Nadia Rahmawati',
  ];
  static const List<String> _wallets = ['DANA', 'GoPay', 'OVO', 'ShopeePay', 'LinkAja'];
  static const List<String> _banks = ['BCA', 'Mandiri', 'BRI', 'BNI', 'BSI', 'CIMB Niaga', 'Permata', 'BTN'];

  void _seedHistory() {
    _seededAt = DateTime.now();
    final rnd = Random(2026);
    var n = 1;
    for (final c in _campaigns.all) {
      var left = c.collectedAmount;
      if (left <= 0) continue;

      // Jumlah transaksi kira-kira 1 per Rp 450 ribu (program harga tetap: per unit).
      final fixed = c.unitPrice;
      final count = fixed != null
          ? max(1, left ~/ fixed)
          : max(3, (left / 450000).round());

      final amounts = <int>[];
      if (fixed != null) {
        for (var i = 0; i < count; i++) {
          amounts.add(fixed);
        }
        amounts[count - 1] += left - fixed * count; // sisa pembulatan
      } else {
        final weights = List<double>.generate(count, (_) => 0.3 + rnd.nextDouble() * 1.7);
        final sum = weights.fold<double>(0, (a, b) => a + b);
        var used = 0;
        for (var i = 0; i < count - 1; i++) {
          var a = (left * weights[i] / sum / 5000).round() * 5000;
          if (a < 5000) a = 5000;
          amounts.add(a);
          used += a;
        }
        final last = left - used;
        amounts.add(last < 5000 ? 5000 : last);
      }
      left = 0;

      for (final a in amounts) {
        // Lebih banyak transaksi di hari-hari terakhir.
        final days = (pow(rnd.nextDouble(), 1.8) * 364).floor();
        final at = _seededAt
            .subtract(Duration(days: days, hours: rnd.nextInt(24), minutes: rnd.nextInt(60)));
        final r = rnd.nextDouble();
        final PaymentMethod m = r < 0.3
            ? PaymentMethod.qris
            : (r < 0.7 ? PaymentMethod.ewallet : PaymentMethod.transfer);
        final String? provider = m == PaymentMethod.ewallet
            ? _wallets[rnd.nextInt(_wallets.length)]
            : (m == PaymentMethod.transfer ? _banks[rnd.nextInt(_banks.length)] : null);
        _items.add(
          AdminTxn(
            id: 'T${(n++).toString().padLeft(5, '0')}',
            donorName: rnd.nextDouble() < 0.22
                ? Donation.anonymousName
                : _names[rnd.nextInt(_names.length)],
            campaignId: c.id,
            campaignTitle: c.title,
            category: c.category,
            amount: a,
            method: m,
            provider: provider,
            at: at,
          ),
        );
      }
    }
    _items.sort((a, b) => b.at.compareTo(a.at));
  }

  /// Ambil donasi baru dari aplikasi (setelah dashboard dibuka). Aman dipanggil berulang.
  Future<void> sync() async {
    final history = await _donations.getHistory();
    var changed = false;
    for (final d in history) {
      if (!d.createdAt.isAfter(_seededAt)) continue; // sudah masuk hitungan seed
      if (_liveIds.contains(d.id)) continue;
      _liveIds.add(d.id);
      _items.insert(
        0,
        AdminTxn(
          id: 'L-${d.id}',
          donorName: d.donorName,
          campaignId: d.campaignId,
          campaignTitle: d.campaignTitle,
          category: d.category,
          amount: d.amount,
          method: d.paymentMethod,
          provider: d.paymentProvider,
          at: d.createdAt,
          isLive: true,
        ),
      );
      changed = true;
    }
    if (changed) {
      _items.sort((a, b) => b.at.compareTo(a.at));
      notifyListeners();
    }
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
