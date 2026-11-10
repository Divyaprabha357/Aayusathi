import 'package:flutter/foundation.dart';

/// Central configuration for Supabase integration in AAYUSATHI.
///
/// Role in Architecture:
/// - Firebase remains the primary database (Firestore), authentication, and queue backend.
/// - Supabase Storage is utilized exclusively as the secure, private cloud file storage layer.
/// - Bucket `aayusathi-reports` is PRIVATE. Files are accessed via temporary signed URLs or authenticated streams.
class SupabaseConfig {
  SupabaseConfig._();

  /// Authoritative Supabase Project URL for AAYUSATHI.
  static const String supabaseUrl = 'https://xtgjpvejqzptjyrskuuk.supabase.co';

  /// Supabase Publishable / Anon Key.
  ///
  /// Can be overridden at build-time using `--dart-define=SUPABASE_ANON_KEY=your_key`.
  /// IMPORTANT: NEVER place service_role or secret keys in Flutter code.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0Z2pwdmVqcXpwdGp5cnNrdXVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg3MTkxMzYsImV4cCI6MjEwNDI5NTEzNn0.KT_pXoXXacEBEkMXNE0xVNwK4LEbkZ8KaHC_tGYv4T0',
  );

  /// Authoritative Private Storage Bucket for medical reports & PDFs.
  static const String bucketName = 'aayusathi-reports';
  static const bool isPrivateBucket = true;

  /// Maximum permitted file size in bytes (15 MB).
  static const int maxFileSizeBytes = 15 * 1024 * 1024;

  /// Default duration for short-lived, time-limited signed URLs (5 minutes).
  static const Duration signedUrlDuration = Duration(minutes: 5);

  /// Whitelisted MIME types for medical reports and uploads.
  static const Set<String> allowedMimeTypes = {
    'application/pdf',
    'image/jpeg',
    'image/jpg',
    'image/png',
  };

  /// Whitelisted file extensions.
  static const Set<String> allowedExtensions = {
    '.pdf',
    '.jpg',
    '.jpeg',
    '.png',
  };

  /// Extracts the project hostname for safe diagnostic logging (never logs keys).
  static String get projectHost {
    try {
      final uri = Uri.parse(supabaseUrl);
      return uri.host;
    } catch (_) {
      return 'xtgjpvejqzptjyrskuuk.supabase.co';
    }
  }

  /// Checks whether the active key is missing, empty, or has a known corrupted placeholder signature.
  static bool get isPlaceholderKey {
    if (publishableKey.trim().isEmpty) return true;
    if (publishableKey.endsWith('H9J3K3K9K3K3K9K3K3K9K3K3K9K') ||
        publishableKey.contains('K3K3K9K3K3K9K') ||
        publishableKey.split('.').length != 3) {
      return true;
    }
    return false;
  }

  /// Returns a safe descriptive status of the configured publishable key without exposing it.
  static String get keyStatusDescription {
    if (publishableKey.isEmpty) return 'Missing (empty)';
    if (publishableKey.startsWith('sb_secret_') ||
        publishableKey.toLowerCase().contains('service_role')) {
      return 'FORBIDDEN (Secret/Service-role key)';
    }
    if (isPlaceholderKey) {
      return 'Placeholder signature detected (needs valid SUPABASE_ANON_KEY)';
    }
    return 'Configured (format: JWT)';
  }

  /// Validates that the active client configuration does not contain forbidden secret keys.
  static bool get isConfigValid {
    if (publishableKey.startsWith('sb_secret_') ||
        publishableKey.toLowerCase().contains('service_role')) {
      debugPrint('[SupabaseConfig] CRITICAL SECURITY ALERT: Secret/Service-role key detected in client config!');
      return false;
    }
    return supabaseUrl.isNotEmpty && publishableKey.isNotEmpty;
  }

  /// Whether the configuration contains a verified non-placeholder publishable key ready for cloud storage.
  static bool get isLiveCloudReady {
    return isConfigValid && !isPlaceholderKey;
  }
}
