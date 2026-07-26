import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static Future<String> getActiveAiModel() async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    try {
      // Set configuration settings
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        // ⚠️ Set to 0 during development so it updates instantly.
        // CHANGE THIS TO Duration(hours: 12) BEFORE RELEASING TO PRODUCTION!
        minimumFetchInterval: const Duration(seconds: 0),
      ));

      // Define a fallback just in case the phone has no internet
      await remoteConfig.setDefaults(const {
        "active_gemini_model": "gemini-1.5-flash",
      });

      // Fetch the newest value from your Firebase dashboard
      await remoteConfig.fetchAndActivate();

      // Return the dynamic model name!
      return remoteConfig.getString("active_gemini_model");

    } catch (e) {
      print("Remote Config fetch failed: $e");
      // Fallback if something goes wrong
      return "gemini-2.5-flash";
    }
  }
}