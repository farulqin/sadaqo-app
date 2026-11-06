import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_state.dart';
import 'package:sadaqo/features/donation/presentation/pages/donation_page.dart';
import 'package:sadaqo/features/zakat/domain/usecases/zakat_calculator.dart';

/// Halaman Zakat: kalkulator Fitrah (disalurkan berupa beras) dan Maal (berupa uang).
class ZakatPage extends StatelessWidget {
  const ZakatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Zakat'),
          bottom: const TabBar(
            indicatorColor: AppColors.limeGreen,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Zakat Fitrah'), Tab(text: 'Zakat Maal')],
          ),
        ),
        body: const TabBarView(children: [_FitrahTab(), _MaalTab()]),
      ),
    );
  }
}

// ---------- helper ----------

Campaign? _findZakat(BuildContext context, String subType) {
  final state = context.watch<CampaignCubit>().state;
  if (state is! CampaignLoaded) return null;
  for (final c in state.campaigns) {
    if (c.isZakat && c.subType == subType) return c;
  }
  return null;
}

void _pay(BuildContext context, Campaign campaign, int amount) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DonationPage(campaign: campaign, fixedAmount: amount),
    ),
  );
}

int _num(TextEditingController c) => int.tryParse(c.text) ?? 0;

String _kg(double v) {
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  return s.replaceAll('.', ',');
}

// ---------- ZAKAT FITRAH ----------

class _FitrahTab extends StatefulWidget {
  const _FitrahTab();

  @override
  State<_FitrahTab> createState() => _FitrahTabState();
}

class _FitrahTabState extends State<_FitrahTab> {
  int _people = 1;
  final _priceCtrl =
      TextEditingController(text: ZakatRules.defaultRicePricePerKg.toString());

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ZakatCalculator.fitrah(
      people: _people,
      ricePricePerKg: _num(_priceCtrl),
    );
    final campaign = _findZakat(context, 'Fitrah');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ProgramImage(
          category: ProgramCategory.zakat,
          imageAsset: AppAssets.zakatFitrah,
          height: 150,
          width: double.infinity,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 12),
        const _InfoBox(
          'Zakat fitrah ditunaikan untuk setiap jiwa sebesar 2,5 kg beras '
          '(setara 3,5 liter makanan pokok). Di SADAQO, zakat fitrah disalurkan '
          'dalam bentuk BERAS kepada yang berhak.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text('Jumlah jiwa',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            _Stepper(
              value: _people,
              min: 1,
              max: 50,
              onChanged: (v) => setState(() => _people = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MoneyField(
          label: 'Harga beras per kg',
          controller: _priceCtrl,
          helper: 'Ubah sesuai harga beras yang biasa kamu beli',
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 16),
        _ResultCard(
          rows: [('Beras yang dikeluarkan', '${_kg(result.riceKg)} kg')],
          totalLabel: 'Nilai setara uang',
          totalValue: Formatter.rupiah(result.amount),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: (campaign == null || result.amount <= 0)
              ? null
              : () => _pay(context, campaign, result.amount),
          child: const Text('Bayar Zakat Fitrah  →'),
        ),
        const SizedBox(height: 10),
        const _Note(),
      ],
    );
  }
}

// ---------- ZAKAT MAAL ----------

enum _MaalType {
  income('Penghasilan'),
  wealth('Tabungan & Harta'),
  gold('Emas');

  const _MaalType(this.label);
  final String label;
}

class _MaalTab extends StatefulWidget {
  const _MaalTab();

  @override
  State<_MaalTab> createState() => _MaalTabState();
}

class _MaalTabState extends State<_MaalTab> {
  _MaalType _type = _MaalType.income;
  bool _haul = false;

  final _incomeCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  final _wealthCtrl = TextEditingController();
  final _gramCtrl = TextEditingController();
  final _goldPriceCtrl =
      TextEditingController(text: ZakatRules.defaultGoldPricePerGram.toString());

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _otherCtrl.dispose();
    _wealthCtrl.dispose();
    _gramCtrl.dispose();
    _goldPriceCtrl.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final goldPrice = _num(_goldPriceCtrl);
    final result = switch (_type) {
      _MaalType.income => ZakatCalculator.income(
          monthlyIncome: _num(_incomeCtrl),
          otherIncome: _num(_otherCtrl),
        ),
      _MaalType.wealth => ZakatCalculator.wealth(
          totalWealth: _num(_wealthCtrl),
          goldPricePerGram: goldPrice,
          haulReached: _haul,
        ),
      _MaalType.gold => ZakatCalculator.gold(
          grams: double.tryParse(_gramCtrl.text) ?? 0,
          goldPricePerGram: goldPrice,
          haulReached: _haul,
        ),
    };
    final campaign = _findZakat(context, 'Maal');

    final nisabText = _type == _MaalType.income
        ? '${Formatter.rupiah(ZakatRules.incomeNisabPerMonth)} per bulan (BAZNAS 2026)'
        : '${ZakatRules.goldNisabGram} gram emas = ${Formatter.rupiah(result.nisab)}';

    String status;
    if (result.obligated) {
      status = 'Wajib zakat';
    } else if (_type != _MaalType.income && !_haul) {
      status = 'Belum mencapai haul (1 tahun)';
    } else {
      status = 'Belum mencapai nisab';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ProgramImage(
          category: ProgramCategory.zakat,
          imageAsset: AppAssets.zakatMaal,
          height: 150,
          width: double.infinity,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 12),
        const _InfoBox(
          'Zakat maal adalah zakat atas harta dengan kadar 2,5%. Di SADAQO, '
          'zakat maal disalurkan dalam bentuk UANG kepada yang berhak.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            for (final t in _MaalType.values)
              ChoiceChip(
                label: Text(t.label),
                selected: _type == t,
                showCheckmark: false,
                onSelected: (_) => setState(() => _type = t),
                selectedColor: AppColors.forestGreen,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: _type == t ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (_type == _MaalType.income) ...[
          _MoneyField(
            label: 'Penghasilan per bulan',
            controller: _incomeCtrl,
            onChanged: _refresh,
          ),
          const SizedBox(height: 10),
          _MoneyField(
            label: 'Penghasilan lain per bulan (opsional)',
            controller: _otherCtrl,
            onChanged: _refresh,
          ),
        ],
        if (_type == _MaalType.wealth)
          _MoneyField(
            label: 'Total tabungan & harta',
            controller: _wealthCtrl,
            helper: 'Setelah dikurangi utang yang jatuh tempo',
            onChanged: _refresh,
          ),
        if (_type == _MaalType.gold)
          TextField(
            controller: _gramCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            onChanged: (_) => _refresh(),
            decoration: const InputDecoration(
              labelText: 'Berat emas yang dimiliki',
              suffixText: 'gram',
            ),
          ),
        if (_type != _MaalType.income) ...[
          const SizedBox(height: 10),
          _MoneyField(
            label: 'Harga emas per gram',
            controller: _goldPriceCtrl,
            helper: 'Perkiraan awal. Ubah sesuai harga emas hari ini',
            onChanged: _refresh,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _haul,
            onChanged: (v) => setState(() => _haul = v),
            title: const Text('Sudah dimiliki 1 tahun penuh (haul)'),
          ),
        ],
        const SizedBox(height: 8),
        _ResultCard(
          rows: [
            ('Nilai yang dihitung', Formatter.rupiah(result.base)),
            ('Nisab', nisabText),
            ('Status', status),
          ],
          totalLabel: 'Zakat yang harus dibayar',
          totalValue: Formatter.rupiah(result.zakat),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: (campaign == null || !result.obligated)
              ? null
              : () => _pay(context, campaign, result.zakat),
          child: const Text('Bayar Zakat Maal  →'),
        ),
        const SizedBox(height: 10),
        const _Note(),
      ],
    );
  }
}

// ---------- widget kecil ----------

class _InfoBox extends StatelessWidget {
  const _InfoBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sandBeige,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.forestGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Hasil perhitungan bersifat perkiraan. Ketentuan lengkap sebaiknya '
      'dikonsultasikan dengan lembaga amil zakat atau ustaz. Pembayaran pada '
      'versi demo ini hanya simulasi.',
      style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.forestGreen,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.forestGreen,
        ),
      ],
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp ',
        helperText: helper,
        helperMaxLines: 2,
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.rows,
    required this.totalLabel,
    required this.totalValue,
  });

  final List<(String, String)> rows;
  final String totalLabel;
  final String totalValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sandBeige),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(r.$1,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      r.$2,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 16),
          Text(totalLabel,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Text(
            totalValue,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.forestGreen,
            ),
          ),
        ],
      ),
    );
  }
}