import 'package:flutter/widgets.dart';

enum LitlyMood { greeting, pointing, amazed, cheering, frustrated, excited }

extension LitlyMoodAsset on LitlyMood {
  String get assetPath => switch (this) {
    LitlyMood.greeting => 'assets/images/mascots/mascot_haii.png',
    LitlyMood.pointing => 'assets/images/mascots/mascot_asekk.png',
    LitlyMood.amazed => 'assets/images/mascots/mascot_wow.png',
    LitlyMood.cheering => 'assets/images/mascots/mascot_good.png',
    LitlyMood.frustrated => 'assets/images/mascots/mascot_marah.png',
    LitlyMood.excited => 'assets/images/mascots/mascot_wahh.png',
  };
}

class LitlyMascot extends StatelessWidget {
  const LitlyMascot({
    super.key,
    required this.mood,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final LitlyMood mood;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.asset(
    mood.assetPath,
    width: width,
    height: height,
    fit: fit,
    excludeFromSemantics: true,
  );
}
