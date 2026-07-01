import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'app/theme.dart';
import 'data/repositories.dart';
import 'features/auth/pin_screen.dart';
import 'features/home/home_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/sortie/mouvement_screen.dart';
import 'features/stocks/stocks_screen.dart';
import 'features/admin/admin_menu_screen.dart';
import 'features/admin/ajouter_produit_screen.dart';
import 'features/admin/cockpit_screen.dart';
import 'features/admin/gerer_produits_screen.dart';
import 'features/admin/modifier_produit_screen.dart';
import 'data/models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: StockEsatApp()));
}

class StockEsatApp extends ConsumerWidget {
  const StockEsatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final connecte = ref.read(operateurCourantProvider) != null;
        final surLogin = state.matchedLocation == '/login';
        if (!connecte && !surLogin) return '/login';
        if (connecte && surLogin) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const PinScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/scan',
          builder: (_, s) =>
              ScanScreen(mode: s.uri.queryParameters['mode'] ?? 'Sortie'),
        ),
        GoRoute(
          path: '/mouvement',
          builder: (_, s) {
            final args = s.extra as MouvementArgs;
            return MouvementScreen(args: args);
          },
        ),
        GoRoute(path: '/stocks', builder: (_, __) => const StocksScreen()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminMenuScreen()),
        GoRoute(
            path: '/admin/produit',
            builder: (_, __) => const AjouterProduitScreen()),
        GoRoute(
            path: '/admin/cockpit',
            builder: (_, __) => const CockpitScreen()),
        GoRoute(
            path: '/admin/produits',
            builder: (_, __) => const GererProduitsScreen()),
        GoRoute(
            path: '/admin/modifier',
            builder: (_, s) =>
                ModifierProduitScreen(produit: s.extra as Produit)),
      ],
    );

    return MaterialApp.router(
      title: "Stock'ESAT",
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: router,
    );
  }
}
