class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://uewrslcvajwqcndfcjxr.supabase.co',
  );
  static const clePublishable = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_yYWGS9xyti9cv4EERCTI2w_Ivvos6f8',
  );
}
