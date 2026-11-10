import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Result of Supabase initialization.
class SupabaseInitResult {
  final bool isInitialized;
  final String? errorMessage;

  const SupabaseInitResult({
    required this.isInitialized,
    this.errorMessage,
  });
}

/// Central singleton manager ensuring Supabase is initialized exactly once.
///
/// Designed to fail gracefully without crashing the app, enabling seamless
/// offline or mock development modes.
class SupabaseInitializer {
  SupabaseInitializer._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Returns the active SupabaseClient if initialized, or null.
  static SupabaseClient? get client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Initializes the Supabase Flutter SDK exactly once.
  static Future<SupabaseInitResult> initialize({
    String? customUrl,
    String? customAnonKey,
  }) async {
    if (_initialized) {
      return const SupabaseInitResult(isInitialized: true);
    }

    final url = customUrl ?? SupabaseConfig.supabaseUrl;
    final anonKey = customAnonKey ?? SupabaseConfig.publishableKey;

    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint('[SupabaseInitializer] Supabase configuration missing. Cloud storage will be disabled.');
      return const SupabaseInitResult(
        isInitialized: false,
        errorMessage: 'Missing Supabase URL or Anon Key',
      );
    }

    if (anonKey.startsWith('sb_secret_') || anonKey.toLowerCase().contains('service_role')) {
      debugPrint('[SupabaseInitializer] SECURITY ERROR: Secret or service-role key rejected in client.');
      return const SupabaseInitResult(
        isInitialized: false,
        errorMessage: 'Forbidden secret or service-role key in client config',
      );
    }

    // Detect placeholder or malformed keys before sending network requests
    final isPlaceholder = anonKey.trim().isEmpty ||
        anonKey.endsWith('H9J3K3K9K3K3K9K3K3K9K3K3K9K') ||
        anonKey.contains('K3K3K9K3K3K9K') ||
        anonKey.split('.').length != 3;

    if (isPlaceholder) {
      debugPrint('[SupabaseInitializer] Supabase configuration contains a placeholder or malformed anonymous key.');
      debugPrint('[SupabaseInitializer] REQUIRED CONFIGURATION: Supply a genuine anonymous key using build flag: --dart-define=SUPABASE_ANON_KEY=your_key');
      return const SupabaseInitResult(
        isInitialized: false,
        errorMessage: 'Placeholder or malformed anonymous key. Pass --dart-define=SUPABASE_ANON_KEY=... to enable Supabase storage.',
      );
    }

    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: kDebugMode,
      );
      _initialized = true;

      final sessionPresent = Supabase.instance.client.auth.currentSession != null;
      debugPrint('[SupabaseInitializer] Supabase initialized: true');
      debugPrint('[SupabaseInitializer] Supabase project host: ${SupabaseConfig.projectHost}');
      debugPrint('[SupabaseInitializer] Supabase bucket: ${SupabaseConfig.bucketName}');
      debugPrint('[SupabaseInitializer] Supabase session present: $sessionPresent');
      debugPrint('[SupabaseInitializer] Supabase key status: ${SupabaseConfig.keyStatusDescription}');

      return const SupabaseInitResult(isInitialized: true);
    } catch (e) {
      _initialized = false;
      debugPrint('[SupabaseInitializer] Failed to initialize Supabase: $e');
      return SupabaseInitResult(
        isInitialized: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Resets the initializer state (useful for unit and widget testing).
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
  }
}
