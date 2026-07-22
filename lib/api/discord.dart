import 'package:dart_discord_presence/dart_discord_presence.dart';

class Discord {
  static late DiscordRPC discordRPC;

  static Future<void> init() async {
    if (!DiscordRPC.isAvailable) {
      print('Discord RPC not available on this platform');
      return;
    }

    discordRPC = DiscordRPC();

    // Listen for connection
    discordRPC.onReady.listen((event) {
      print('Connected as ${event.user.username}');
    });

    // Initialize with your Discord Application ID
    await connect();
  }

  static Future<void> connect() async {
    try {
      await discordRPC.initialize('1525744175272951909');
    } catch (e) {
      print("Discord nto running...");
    }
  }

  static void updateStatus(String details, String state, Duration position, Duration duration, String assetUrl, bool isPlaying) async {
    try {
      if (!discordRPC.isConnected) {
        await connect();
      }

      await discordRPC.setPresence(
        DiscordPresence(
          type: DiscordActivityType.watching,
          statusDisplayType: DiscordStatusDisplayType.details,
          details: details,
          state: state,
          timestamps: DiscordTimestamps.ending(DateTime.now().add(duration)),
          largeAsset: DiscordAsset(url: assetUrl, text: details),
        ),
      );
    } catch (e) {
      print("Still not connected");
    }
  }

  static void resetStatus() {
    if (discordRPC.isConnected) {
      discordRPC.clearPresence();
    }
  }
}
