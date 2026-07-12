import 'package:dart_discord_presence/dart_discord_presence.dart';

class Discord {
  static late DiscordRPC discordRPC;

  static void init() {
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
    discordRPC.initialize('YOUR_APPLICATION_ID');
  }

  static void updateStatus(String details, String state, Duration position, Duration duration, String assetUrl) async {
    final now = DateTime.now();
    final start = now.subtract(position);
    final end = now.add(duration - position);

    await discordRPC.setPresence(
      DiscordPresence(
        type: DiscordActivityType.watching,
        details: details,
        state: state,
        timestamps: DiscordTimestamps.range(start, end),
        largeAsset: DiscordAsset(url: assetUrl, text: details),
      ),
    );
  }
}
