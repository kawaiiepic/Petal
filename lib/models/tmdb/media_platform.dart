/// The original TV network or a regional subscription provider, not a source
/// offered by any installed playback addon.
class MediaPlatform {
  const MediaPlatform({
    required this.name,
    required this.logoUrl,
    required this.isOriginalNetwork,
  });

  final String name;
  final String logoUrl;
  final bool isOriginalNetwork;

  String get label =>
      isOriginalNetwork ? 'Original network: $name' : 'Streaming on $name';
}
