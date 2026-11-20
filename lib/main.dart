import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sadaqo/core/navigation/session_guard.dart';
import 'package:sadaqo/core/theme/theme_controller.dart';
import 'package:sadaqo/core/theme/theme_scope.dart';
import 'package:sadaqo/pengelola/core/pengelola_config.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_state.dart';
import 'package:sadaqo/features/auth/presentation/pages/login_page.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/news/presentation/cubit/news_cubit.dart';
import 'package:sadaqo/features/splash/presentation/pages/pages/splash_page.dart';
import 'package:sadaqo/injection_container.dart' as di;
import 'package:sadaqo/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sadaqo/features/favorite/presentation/cubit/favorite_cubit.dart';
import 'package:sadaqo/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:sadaqo/features/profile/presentation/cubit/settings_cubit.dart';
import 'package:flutter/gestures.dart';
import 'package:sadaqo/features/community_feed/presentation/cubit/community_feed_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID'); // format tanggal bahasa Indonesia
  await di.init();

  // Tampilan tersimpan (Terang/Gelap/Liquid Glass). Admin dan pengelola dikunci Terang.
  await ThemeController.instance.load();
  _syncThemeLock(di.sl<AuthCubit>());

  // Server membalas 401 (token kedaluwarsa/tidak valid): keluar dan ke halaman login.
  SessionGuard.onExpired = () {
    final auth = di.sl<AuthCubit>();
    if (auth.state is! AuthAuthenticated) return;
    auth.markLoggedOut();
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
    appMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Sesi berakhir, silakan masuk kembali.')),
    );
  };

  // Server tidak terjangkau: beri tahu sekali per 6 detik.
  DateTime? lastOfflineNotice;
  SessionGuard.onOffline = () {
    final now = DateTime.now();
    if (lastOfflineNotice != null &&
        now.difference(lastOfflineNotice!) < const Duration(seconds: 6)) {
      return;
    }
    lastOfflineNotice = now;
    appMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Tidak dapat terhubung ke server. Periksa koneksi atau coba lagi.')),
    );
  };

  runApp(const SadaqoApp());
}

/// Admin dan pengelola selalu memakai tampilan Terang. Pilihan donatur tidak berubah.
void _syncThemeLock(AuthCubit auth) {
  void apply(AuthState state) {
    final user = state is AuthAuthenticated ? state.user : null;
    final staff = user != null &&
        (user.isAdmin || user.isManager || PengelolaConfig.isPengelolaEmail(user.email));
    ThemeController.instance.setLockedLight(staff);
  }

  apply(auth.state);
  auth.stream.listen(apply);
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
        BlocProvider<CommunityFeedCubit>.value(value: di.sl<CommunityFeedCubit>()),
      ],
      child: ThemeScope(
        builder: (context, theme) => MaterialApp(
          title: 'SADAQO',
          debugShowCheckedModeBanner: false,
          theme: theme,
          scrollBehavior: const AppScrollBehavior(),
          navigatorKey: appNavigatorKey,
          scaffoldMessengerKey: appMessengerKey,
          home: const SplashPage(),
        ),
      ),
    );
  }
}

/// Mengizinkan menggeser daftar dengan sentuhan, mouse, stylus, dan trackpad.
/// Tanpa ini, daftar horizontal hanya bisa diseret dengan jari.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}