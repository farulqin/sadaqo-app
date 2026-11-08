import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sadaqo/core/theme/app_theme.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/news/presentation/cubit/news_cubit.dart';
import 'package:sadaqo/features/splash/presentation/pages/pages/splash_page.dart';
import 'package:sadaqo/injection_container.dart' as di;
import 'package:sadaqo/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sadaqo/features/favorite/presentation/cubit/favorite_cubit.dart';
import 'package:sadaqo/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:sadaqo/features/profile/presentation/cubit/settings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID'); // format tanggal bahasa Indonesia
  await di.init();
  runApp(const SadaqoApp());
}

class SadaqoApp extends StatelessWidget {
  const SadaqoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: di.sl<AuthCubit>()),
        BlocProvider<CampaignCubit>.value(value: di.sl<CampaignCubit>()),
        BlocProvider<DonationHistoryCubit>.value(
          value: di.sl<DonationHistoryCubit>(),
        ),
        BlocProvider<NewsCubit>.value(value: di.sl<NewsCubit>()),
        BlocProvider<ProfileCubit>.value(value: di.sl<ProfileCubit>()..load()),
        BlocProvider<NotificationCubit>.value(value: di.sl<NotificationCubit>()),
        BlocProvider<FavoriteCubit>.value(value: di.sl<FavoriteCubit>()),
        BlocProvider<SettingsCubit>.value(value: di.sl<SettingsCubit>()),
      ],
      child: MaterialApp(
        title: 'SADAQO',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashPage(),
      ),
    );
  }
}
