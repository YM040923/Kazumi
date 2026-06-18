import 'package:flutter/material.dart';
import 'package:kazumi/bean/settings/color_type.dart';

class PaletteCard extends StatefulWidget {
  final KazumiThemePreset preset;
  final bool selected;

  const PaletteCard({
    super.key,
    required this.preset,
    required this.selected,
  });

  @override
  State<StatefulWidget> createState() => _PaletteCardState();
}

class _PaletteCardState extends State<PaletteCard> {
  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        children: [
          Card(
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: preset.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.selected
                      ? preset.primary
                      : scheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: ClipOval(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        color: preset.primary,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              color: preset.secondary,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              color: preset.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.selected)
            Center(
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: preset.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: ThemeData.estimateBrightnessForColor(preset.primary) ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
