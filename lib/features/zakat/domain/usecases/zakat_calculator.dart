/// Aturan zakat yang dipakai kalkulator.
/// Sumber: BAZNAS (nisab penghasilan 2026 dari SK Ketua BAZNAS No. 15 Tahun 2026),
/// nisab maal 85 gram emas, kadar 2,5%, fitrah 2,5 kg beras per jiwa.
class ZakatRules {
  ZakatRules._();

  static const double fitrahRicePerPersonKg = 2.5;
  static const int goldNisabGram = 85;
  static const double rate = 0.025;
  static const int incomeNisabPerMonth = 7640144;

  // Nilai awal yang bisa diubah pengguna (perkiraan, sesuaikan harga terkini).
  static const int defaultRicePricePerKg = 15000;
  static const int defaultGoldPricePerGram = 2400000;
}

class FitrahResult {
  const FitrahResult({required this.riceKg, required this.amount});

  final double riceKg;
  final int amount;
}

class MaalResult {
  const MaalResult({
    required this.base,
    required this.nisab,
    required this.obligated,
    required this.zakat,
  });

  final int base; // nilai yang dihitung (rupiah)
  final int nisab; // batas minimal (rupiah)
  final bool obligated;
  final int zakat;
}

class ZakatCalculator {
  const ZakatCalculator._();

  /// Zakat fitrah: 2,5 kg beras per jiwa, nilai uang = kg x harga beras.
  static FitrahResult fitrah({required int people, required int ricePricePerKg}) {
    final kg = people * ZakatRules.fitrahRicePerPersonKg;
    return FitrahResult(riceKg: kg, amount: (kg * ricePricePerKg).round());
  }

  /// Zakat penghasilan: 2,5% dari penghasilan bruto jika >= nisab bulanan BAZNAS.
  static MaalResult income({required int monthlyIncome, int otherIncome = 0}) {
    final total = monthlyIncome + otherIncome;
    final ok = total >= ZakatRules.incomeNisabPerMonth;
    return MaalResult(
      base: total,
      nisab: ZakatRules.incomeNisabPerMonth,
      obligated: ok,
      zakat: ok ? (total * ZakatRules.rate).round() : 0,
    );
  }

  /// Zakat tabungan dan harta: wajib jika >= 85 gram emas dan sudah 1 tahun (haul).
  static MaalResult wealth({
    required int totalWealth,
    required int goldPricePerGram,
    required bool haulReached,
  }) {
    final nisab = ZakatRules.goldNisabGram * goldPricePerGram;
    final ok = haulReached && totalWealth >= nisab && nisab > 0;
    return MaalResult(
      base: totalWealth,
      nisab: nisab,
      obligated: ok,
      zakat: ok ? (totalWealth * ZakatRules.rate).round() : 0,
    );
  }

  /// Zakat emas: wajib jika >= 85 gram dan sudah 1 tahun (haul).
  static MaalResult gold({
    required double grams,
    required int goldPricePerGram,
    required bool haulReached,
  }) {
    final base = (grams * goldPricePerGram).round();
    final nisab = ZakatRules.goldNisabGram * goldPricePerGram;
    final ok = haulReached && grams >= ZakatRules.goldNisabGram;
    return MaalResult(
      base: base,
      nisab: nisab,
      obligated: ok,
      zakat: ok ? (base * ZakatRules.rate).round() : 0,
    );
  }
}