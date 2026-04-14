class AgoraConfig {
  // App ID is loaded at runtime from Firestore remote config or environment.
  // Never hardcode this value in client source code.
  // Fetch via AgoraTokenService.getAppId() which reads from a secure backend.
  static const String appId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '',
  );
}
