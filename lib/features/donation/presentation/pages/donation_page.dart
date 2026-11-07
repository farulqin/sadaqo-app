import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_state.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';
import 'package:sadaqo/features/donation/domain/entities/payment_options.dart';
import 'package:sadaqo/features/donation/domain/usecases/create_donation.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_form_cubit.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_form_state.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/donation/presentation/widgets/payment_sheet.dart';
import 'package:sadaqo/features/donation/presentation/widgets/program_picker_sheet.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/features/splash/presentation/pages/kindness_splash_page.dart';

/// Form donasi dengan 3 mode nominal:
/// 1) nominal bebas (minimal Rp 5.000),
/// 2) harga tetap per unit (qurban per orang / kolektif) dengan pemilih jumlah,
/// 3) [fixedAmount] terisi (zakat dari kalkulator): nominal tidak bisa diubah.
/// Jika [campaign] terisi, program tidak bisa diganti. Jika kosong (tab Donasi),
/// pengguna mencari dan memilih program (zakat tidak ikut, lewat kalkulator).
class DonationPage extends StatefulWidget {
  const DonationPage({super.key, this.campaign, this.fixedAmount});

  final Campaign? campaign;
  final int? fixedAmount;

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  static const List<int> _quickAmounts = [25000, 50000, 100000];

  final _amountController = TextEditingController();
  Campaign? _selected;
  PaymentMethod _method = PaymentMethod.qris;
  String? _provider; // nama e-wallet / bank
  bool _anonymous = false;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _selected = widget.campaign;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int _qtyFor(Campaign c) {
    final max = c.maxUnits < 1 ? 1 : c.maxUnits;
    return _qty > max ? max : _qty;
  }

  int _amountFor(Campaign? c) {
    if (widget.fixedAmount != null) return widget.fixedAmount!;
    final price = c?.unitPrice;
    if (c != null && price != null) return price * _qtyFor(c);
    return int.tryParse(_amountController.text) ?? 0;
  }

  /// Ambil versi terbaru program (kuota/dana bisa berubah setelah donasi).
  Campaign? _fresh(Campaign? c, List<Campaign> all) {
    if (c == null) return null;
    for (final x in all) {
      if (x.id == c.id) return x;
    }
    return c;
  }

  void _setMethod(PaymentMethod m) {
    setState(() {
      _method = m;
      _provider = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DonationFormCubit>(),
      child: BlocConsumer<DonationFormCubit, DonationFormState>(
        listener: _onFormState,
        builder: (context, formState) {
          final campaignState = context.watch<CampaignCubit>().state;
          final all =
              campaignState is CampaignLoaded ? campaignState.campaigns : <Campaign>[];
          final pickable = all.where((c) => !c.isZakat).toList();
          final selected = _fresh(_selected, all);

          final fixed = widget.fixedAmount != null;
          final userName = context.read<AuthCubit>().user?.name ?? 'Donatur';
          final donorName = _anonymous ? Donation.anonymousName : userName;
          final amount = _amountFor(selected);
          final submitting = formState is DonationFormSubmitting;
          final blockedByQuota = !fixed && selected != null && selected.isFull;
          final needsProvider = _method != PaymentMethod.qris;
          final canSubmit = !submitting &&
              selected != null &&
              !blockedByQuota &&
              amount > 0 &&
              (!needsProvider || _provider != null);

          return Scaffold(
            appBar: AppBar(title: Text(fixed ? 'Bayar Zakat' : 'Donasi')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: selected == null
                  ? [
                      _PickProgramCard(
                        loading: pickable.isEmpty,
                        onTap: () => _pickCampaign(context, pickable),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Cari berdasarkan nama program, lokasi, atau kategori. '
                        'Untuk zakat, gunakan menu Zakat di beranda.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ]
                  : _formChildren(
                      context,
                      selected,
                      pickable,
                      amount,
                      donorName,
                      fixed,
                      canSubmit,
                      submitting,
                    ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _formChildren(
    BuildContext context,
    Campaign selected,
    List<Campaign> pickable,
    int amount,
    String donorName,
    bool fixed,
    bool canSubmit,
    bool submitting,
  ) {
    return [
      _header(context, selected, pickable),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: AppColors.forestGreen),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Transaksi Anda aman dan transparan',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      ..._amountSection(selected, amount, fixed),
      const SizedBox(height: 20),
      const Text(
        'Metode Pembayaran (Simulasi)',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _MethodTile(
              icon: Icons.qr_code_2,
              label: PaymentMethod.qris.label,
              selected: _method == PaymentMethod.qris,
              onTap: () => _setMethod(PaymentMethod.qris),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MethodTile(
              icon: Icons.account_balance_wallet_outlined,
              label: PaymentMethod.ewallet.label,
              selected: _method == PaymentMethod.ewallet,
              onTap: () => _setMethod(PaymentMethod.ewallet),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MethodTile(
              icon: Icons.account_balance_outlined,
              label: PaymentMethod.transfer.label,
              selected: _method == PaymentMethod.transfer,
              onTap: () => _setMethod(PaymentMethod.transfer),
            ),
          ),
        ],
      ),
      if (_method == PaymentMethod.qris)
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            'Kode QR akan ditampilkan pada langkah berikutnya.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      if (_method == PaymentMethod.ewallet)
        _providerChips('Pilih e-wallet', PaymentOptions.ewallets),
      if (_method == PaymentMethod.transfer)
        _providerChips('Pilih bank', PaymentOptions.banks),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: SwitchListTile(
          value: _anonymous,
          onChanged: (v) => setState(() => _anonymous = v),
          secondary: const Icon(Icons.visibility_off_outlined, color: AppColors.forestGreen),
          title: const Text(
            'Sembunyikan nama saya',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('Nama yang tampil: $donorName'),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Ini simulasi: tidak ada uang sungguhan yang berpindah.',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: canSubmit
            ? () => _startPayment(context, selected, amount, donorName)
            : null,
        child: submitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(fixed ? 'Bayar Zakat  →' : 'Lanjutkan  →'),
      ),
    ];
  }

  Widget _providerChips(String hint, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in options)
                ChoiceChip(
                  label: Text(p),
                  selected: _provider == p,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _provider = p),
                  selectedColor: AppColors.forestGreen,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _provider == p ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _amountSection(Campaign c, int amount, bool fixed) {
    // Mode 3: nominal dari kalkulator zakat.
    if (fixed) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Zakat', style: TextStyle(color: AppColors.textMuted)),
              Text(
                Formatter.rupiah(amount),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                c.subType == 'Fitrah'
                    ? 'Disalurkan dalam bentuk beras'
                    : 'Disalurkan dalam bentuk uang',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ];
    }

    // Mode 2: harga tetap per unit.
    if (c.unitPrice != null) {
      final qty = _qtyFor(c);
      final unit = c.unitLabel ?? 'unit';
      return [
        Text('Jumlah $unit',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text('Harga per $unit')),
                  Text(
                    Formatter.rupiah(c.unitPrice!),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (c.isSlotBased)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Sisa slot')),
                      Text(
                        '${c.slotsLeft} dari ${c.slotTotal}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 24),
              Row(
                children: [
                  _QtyStepper(
                    value: qty,
                    canDecrease: qty > 1,
                    canIncrease: !c.isFull && qty < c.maxUnits,
                    onChanged: (v) => setState(() => _qty = v),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      Text(
                        Formatter.rupiah(amount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (c.isFull)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Kuota program ini sudah penuh',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ];
    }

    // Mode 1: nominal bebas.
    return [
      const Text('Nominal Donasi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Row(
        children: [
          for (final value in _quickAmounts)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: value == _quickAmounts.last ? 0 : 8),
                child: _AmountChip(
                  label: Formatter.rupiahCompact(value),
                  selected: amount == value,
                  onTap: () => setState(() => _amountController.text = value.toString()),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          prefixText: 'Rp ',
          hintText: 'Nominal lainnya',
          helperText: 'Minimal ${Formatter.rupiah(CreateDonation.minimumAmount)}',
        ),
      ),
    ];
  }

  Widget _header(BuildContext context, Campaign selected, List<Campaign> pickable) {
    final canChange = widget.campaign == null && widget.fixedAmount == null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ProgramImage(
            category: selected.category,
            imageAsset: selected.imageAsset,
            height: 72,
            width: 72,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  selected.category.label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (canChange)
            TextButton(
              onPressed: () => _pickCampaign(context, pickable),
              child: const Text('Ganti'),
            ),
        ],
      ),
    );
  }

  Future<void> _pickCampaign(BuildContext context, List<Campaign> campaigns) async {
    final picked = await showModalBottomSheet<Campaign>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProgramPickerSheet(campaigns: campaigns),
    );
    if (picked != null && mounted) {
      setState(() {
        _selected = picked;
        _qty = 1;
        _amountController.clear();
      });
    }
  }

  /// Langkah pembayaran (QRIS / e-wallet / bank), baru setelah itu donasi dicatat.
  Future<void> _startPayment(
    BuildContext context,
    Campaign campaign,
    int amount,
    String donorName,
  ) async {
    FocusScope.of(context).unfocus();
    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaymentSheet(
        method: _method,
        provider: _provider,
        amount: amount,
        title: campaign.title,
      ),
    );
    if (paid != true || !context.mounted) return;

    context.read<DonationFormCubit>().submit(
          CreateDonationParams(
            campaignId: campaign.id,
            campaignTitle: campaign.title,
            category: campaign.category,
            amount: amount,
            paymentMethod: _method,
            paymentProvider: _method == PaymentMethod.qris ? null : _provider,
            donorName: donorName,
          ),
        );
  }

  Future<void> _onFormState(BuildContext context, DonationFormState state) async {
    if (state is DonationFormError) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.message)));
      return;
    }
    if (state is DonationFormSuccess) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
          title: const Text('Pembayaran Berhasil'),
          content: Text(
            'Terima kasih! Pembayaran ${Formatter.rupiah(state.donation.amount)} '
            'untuk "${state.donation.campaignTitle}" tercatat atas nama '
            '${state.donation.donorName} (simulasi, tidak ada uang sungguhan).',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      // Splash syukur: otomatis tertutup, atau ketuk untuk melewati.
      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) => KindnessSplashPage(
            message: KindnessMessages.thanks,
            onDone: (ctx) => Navigator.of(ctx).pop(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
      if (!context.mounted) return;
      context.read<DonationHistoryCubit>().refresh();
      context.read<CampaignCubit>().refresh(); // progres dana dan kuota ikut diperbarui
      context.read<DonationFormCubit>().reset();
      if (widget.campaign != null || widget.fixedAmount != null) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _amountController.clear();
          _qty = 1;
          _provider = null;
        });
      }
    }
  }
}

class _PickProgramCard extends StatelessWidget {
  const _PickProgramCard({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.sandBeige),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.forestGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loading ? 'Memuat program...' : 'Cari dan pilih program donasi',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.value,
    required this.canDecrease,
    required this.canIncrease,
    required this.onChanged,
  });

  final int value;
  final bool canDecrease;
  final bool canIncrease;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: canDecrease ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.forestGreen,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          onPressed: canIncrease ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.forestGreen,
        ),
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.forestGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.sandBeige),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.successSoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.forestGreen : AppColors.sandBeige,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: AppColors.forestGreen),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}