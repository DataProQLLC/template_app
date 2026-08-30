// lib/core/config.dart
class AppConfig {
  static const env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static String get coreApiUrl {
    const override = String.fromEnvironment('CORE_API_URL');
    if (override.isNotEmpty) return override;
    switch (env) {
      case 'local':
        return 'http://localhost:8080';
      case 'dev':
        return 'https://core-dev-1035294191835.us-east4.run.app';
      case 'stage':
        return 'https://core-stage-xxxx.us-east4.run.app';
      case 'prod':
        return 'https://core-prod-xxxx.us-east4.run.app';
      default:
        return 'https://core-dev-xxxx.us-east4.run.app';
      // case 'local':
      //   return 'http://api.template.com/[env]/[version]/core';
      // case 'dev':
      //   return 'https://api.template.com/[env]/[version]/core';
      // case 'stage':
      //   return 'https://api.template.com/[env]/[version]/core';
      // case 'prod':
      //   return 'https://api.template.com/[env]/[version]/core';
      // default:
      //   return 'https://api.template.com/[env]/[version]/core';
    }
  }

  static String get supabaseUrl {
    const override = String.fromEnvironment('SUPABASE_URL');
    if (override.isNotEmpty) return override;
    switch (env) {
      case 'local':
        return 'https://xvyxnuxqseinvvspmdno.supabase.co';
      case 'dev':
        return 'https://xvyxnuxqseinvvspmdno.supabase.co';
      case 'stage':
        return 'https://yourstageref.supabase.co';
      case 'prod':
        return 'https://yourprodref.supabase.co';
      default:
        return 'https://xvyxnuxqseinvvspmdno.supabase.co';
    }
  }

  static String get supabasePublishableKey {
    const override = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    if (override.isNotEmpty) return override;
    switch (env) {
      case 'local':
        return 'sb_publishable_C5N8HQ-TNSh9RUPKM09NcA_yxem0hzS';
      case 'dev':
        return 'sb_publishable_C5N8HQ-TNSh9RUPKM09NcA_yxem0hzS';
      case 'stage':
        return 'sb_publishable_stage_xxx';
      case 'prod':
        return 'sb_publishable_prod_xxx';
      default:
        return 'sb_publishable_C5N8HQ-TNSh9RUPKM09NcA_yxem0hzS';
    }
  }

  static bool get isProd => env == 'prod';
}