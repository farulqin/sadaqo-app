import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_state.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';
import 'package:sadaqo/features/donation/domain/usecases/create_donation.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_form_cubit.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_form_state.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/injection_container.dart';

/// Form donasi.
/// - Dibuka dari detail program: [campaign] terisi, program tidak bisa diganti.
/// - Dibuka dari tab "Donasi": [campaign] kosong, pengguna memilih program.
class DonationPage extends StatefulWidget {
  const DonationPage({super.key, this.campaign});

  final Campaign? campaign;

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  static const List<int> _quickAmounts = [25000, 50000, 100000];

  final _amountController = TextEditingController();
  Campaign? _selected;
  PaymentMethod _method = PaymentMethod.ewallet;

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

  int get _amount => int.tryParse(_amountController.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DonationFormCubit>(),
      child: BlocConsumer<DonationFormCubit, DonationFormState>(
        listener: _onFormState,
        builder: (context, formState) {
          final campaignState = context.watch<CampaignCubit>().state;
          final campaigns =
              campaignState is CampaignLoaded ? campaignState.campaigns : <Campaign>[];
          final selected =
              _selected ?? (campaigns.isNotEmpty ? campaigns.first : null);
          final submitting = formState is DonationFormSubmitting;

          return Scaffold(
            appBar: AppBar(title: const Text('Donasi')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _campaignHeader(context, selected, campaigns),
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
                          'Donasi Anda aman dan transparan',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nominal Donasi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final value in _quickAmounts)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: value == _quickAmounts.last ? 0 : 8,
                          ),
                          child: _AmountChip(
                            label: Formatter.rupiahCompact(value),
                            selected: _amount == value,
                            onTap: () => setState(
                              () => _amountController.text = value.toString(),
                            ),
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
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    hintText: 'Nominal lainnya',
                  ),
                ),
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
                        icon: Icons.account_balance_wallet_outlined,
                        label: PaymentMethod.ewallet.label,
                        selected: _method == PaymentMethod.ewallet,
                        onTap: () => setState(() => _method = PaymentMethod.ewallet),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MethodTile(
                        icon: Icons.account_balance_outlined,
                        label: PaymentMethod.transfer.label,
                        selected: _method == PaymentMethod.transfer,
                        onTap: () => setState(() => _method = PaymentMethod.transfer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ini simulasi: tidak ada uang sungguhan yang berpindah.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (submitting || selected == null)
                      ? null
                      : () => _submit(context, selected),
                  child: submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Lanjutkan Donasi  →'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _campaignHeader(
    BuildContext context,
    Campaign? selected,
    List<Campaign> campaigns,
  ) {
    if (selected == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppColors.forestGreen)),
      );
    }
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
          if (widget.campaign == null)
            TextButton(
              onPressed: () => _pickCampaign(context, campaigns),
              child: const Text('Ganti'),
            ),
        ],
      ),
    );
  }

  Future<void> _pickCampaign(BuildContext context, List<Campaign> campaigns) async {
    final picked = await showModalBottomSheet<Campaign>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in campaigns)
              ListTile(
                leading: Icon(c.category.icon, color: AppColors.forestGreen),
                title: Text(c.title),
                subtitle: Text(c.category.label),
                onTap: () => Navigator.pop(sheetContext, c),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _selected = picked);
  }

  void _submit(BuildContext context, Campaign campaign) {
    FocusScope.of(context).unfocus();
    context.read<DonationFormCubit>().submit(
          CreateDonationParams(
            campaignId: campaign.id,
            campaignTitle: campaign.title,
            category: campaign.category,
            amount: _amount,
            paymentMethod: _method,
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
          title: const Text('Donasi Berhasil'),
          content: Text(
            'Terima kasih! Donasi ${Formatter.rupiah(state.donation.amount)} '
            'untuk "${state.donation.campaignTitle}" tercatat '
            '(simulasi, tidak ada uang sungguhan).',
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
      context.read<DonationHistoryCubit>().refresh();
      context.read<CampaignCubit>().refresh(); // progres dana ikut diperbarui
      context.read<DonationFormCubit>().reset();
      if (widget.campaign != null) {
        Navigator.of(context).pop();
      } else {
        setState(_amountController.clear);
      }
    }
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.successSoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.forestGreen : AppColors.sandBeige,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.forestGreen),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
