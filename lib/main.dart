// FILE: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';

/// Main entry point for Kos Bae application
///
/// Setup instructions:
/// 1. Run: flutter pub get
/// 2. Create .env file with SUPABASE_URL and SUPABASE_ANON_KEY
/// 3. Run: flutter run
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const KosBaeApp());
}

class KosBaeApp extends StatelessWidget {
  const KosBaeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kos Bae',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.INITIAL,
      getPages: AppPages.routes,
    );
  }
}
