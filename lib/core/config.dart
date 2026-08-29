// lib/core/config.dart
class AppConfig {
  static const env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static String get coreApiUrl {
    const override = String.fromEnvironment('CORE_API_URL');
    if (override.isNotEmpty) return override;
    switch (env) {
      case 'local':
        return 'http://localhost:8080';
      case 'stage':
        return 'https://core-stage-xxxx.us-east4.run.app';
      case 'prod':
        return 'https://core-prod-xxxx.us-east4.run.app';
      default:
        return 'https://core-1063797601262.us-east4.run.app';
    }
  }

  static String get supabaseUrl {
    const override = String.fromEnvironment('SUPABASE_URL');
    if (override.isNotEmpty) return override;
    switch (env) {
      case 'stage':
        return 'https://yourstageref.supabase.co';
      case 'prod':
        return 'https://yourprodref.supabase.co';
      default:
        return 'https://ztijewwlbkoujpgykrks.supabase.co';
    }
  }

  static String get supabasePublishableKey {
    const override = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    if (override.isNotEmpty) return override;
    switch (env) {
      case 'stage':
        return 'sb_publishable_stage_xxx';
      case 'prod':
        return 'sb_publishable_prod_xxx';
      default:
        return 'sb_publishable_VfvkHVI0JZTvep0Lt72gJQ_vt11EhZk';
    }
  }

  static bool get isProd => env == 'prod';
}