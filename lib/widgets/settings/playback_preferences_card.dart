import 'package:petal/api/playback_preferences.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PlaybackPreferencesCard extends StatefulWidget {
  const PlaybackPreferencesCard({super.key});
  @override
  State<PlaybackPreferencesCard> createState() =>
      _PlaybackPreferencesCardState();
}

class _PlaybackPreferencesCardState extends State<PlaybackPreferencesCard> {
  final _audio = TextEditingController(),
      _subtitle = TextEditingController(),
      _rate = TextEditingController(),
      _delay = TextEditingController(),
      _size = TextEditingController(),
      _outline = TextEditingController(),
      _bottom = TextEditingController();
  bool _background = true;
  bool _enabled = true, _ready = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = PlaybackPreferences.instance;
    await p.load();
    if (!mounted) return;
    _audio.text = p.audioLanguage;
    _subtitle.text = p.subtitleLanguage;
    _rate.text = '${p.speed}';
    _delay.text = '${p.subtitleDelay}';
    _size.text = '${p.subtitleSize}';
    _outline.text = '${p.subtitleOutline}';
    _bottom.text = '${p.subtitleBottom}';
    _background = p.subtitleBackground;
    setState(() {
      _enabled = p.subtitles;
      _ready = true;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _audio,
      _subtitle,
      _rate,
      _delay,
      _size,
      _outline,
      _bottom,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final rate = double.tryParse(_rate.text),
        delay = double.tryParse(_delay.text);
    final size = double.tryParse(_size.text),
        outline = double.tryParse(_outline.text),
        bottom = double.tryParse(_bottom.text);
    if (size == null ||
        !size.isFinite ||
        size < 12 ||
        size > 64 ||
        outline == null ||
        !outline.isFinite ||
        outline < 0 ||
        outline > 6 ||
        bottom == null ||
        !bottom.isFinite ||
        bottom < 0 ||
        bottom > 240 ||
        rate == null ||
        !rate.isFinite ||
        rate < .25 ||
        rate > 3 ||
        delay == null ||
        !delay.isFinite ||
        delay.abs() > 60 ||
        _audio.text.trim().isEmpty ||
        _subtitle.text.trim().isEmpty) {
      setState(
        () => _message = 'Enter language codes, speed 0.25–3, delay −60–60 seconds, subtitle size 12–64, outline 0–6, and bottom offset 0–240.',
      );
      return;
    }
    try {
      await PlaybackPreferences.instance.update(
        audio: _audio.text,
        subtitle: _subtitle.text,
        enabled: _enabled,
        rate: rate,
        delay: delay,
        size: size,
        outline: outline,
        bottom: bottom,
        background: _background,
      );
      if (mounted) setState(() => _message = 'Playback preferences saved.');
    } catch (_) {
      if (mounted) setState(() => _message = 'Could not save preferences.');
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          const Text(
            'Playback preferences',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Text(
            'Language codes such as en, ja, fr. Changes apply to internal playback, including downloads.',
          ),
          TextField(
            controller: _audio,
            placeholder: const Text('Preferred audio language'),
          ),
          TextField(
            controller: _subtitle,
            placeholder: const Text('Preferred subtitle language'),
          ),
          Row(
            children: [
              const Expanded(child: Text('Subtitles enabled')),
              Switch(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ],
          ),
          const Text('Playback speed (0.25–3×)'),
          TextField(controller: _rate),
          const Text('Subtitle delay in seconds (positive = later)'),
          TextField(controller: _delay),
          const Text('Subtitle size (12–64)'),
          TextField(controller: _size, onChanged: (_) => setState(() {})),
          const Text('Subtitle outline (0–6)'),
          TextField(controller: _outline, onChanged: (_) => setState(() {})),
          const Text('Subtitle bottom offset (0–240)'),
          TextField(controller: _bottom),
          Row(
            children: [
              const Expanded(child: Text('Subtitle background')),
              Switch(
                value: _background,
                onChanged: (v) => setState(() => _background = v),
              ),
            ],
          ),
          Text(
            'Subtitle preview',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: double.tryParse(_size.text)?.clamp(12, 64) ?? 32,
              color: Colors.white,
              shadows: [
                for (final o in [
                  const Offset(-1, -1),
                  const Offset(-1, 1),
                  const Offset(1, -1),
                  const Offset(1, 1),
                ])
                  Shadow(
                    color: const Color(0xFF000000),
                    offset:
                        o * (double.tryParse(_outline.text)?.clamp(0, 6) ?? 2),
                  ),
              ],
              backgroundColor: _background
                  ? const Color(0xAA000000)
                  : const Color(0x00000000),
            ),
          ),
          Button.primary(
            onPressed: _ready ? _save : null,
            child: const Text('Save playback preferences'),
          ),
          if (_message != null) Text(_message!),
        ],
      ),
    ),
  );
}
