import 'package:flutter/material.dart';
import 'package:leerlus/l10n/app_localizations.dart';
import 'package:leerlus/models/occlusion_data.dart';
import 'package:leerlus/screens/manage_content_screens/image_occlusion_selector_screen.dart';

class OcclusionSection extends StatelessWidget {
  /// Images that support occlusion for this question.
  /// Empty means the section is hidden entirely.
  final List<OcclusionImageEntry> images;

  /// Occlusion data keyed by [OcclusionImageEntry.key].
  final Map<String, OcclusionData> occlusionDataByImage;

  /// Called with the full updated map (empty map = clear all).
  final ValueChanged<Map<String, OcclusionData>> onChanged;

  const OcclusionSection({
    super.key,
    required this.images,
    required this.occlusionDataByImage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final imagesWithData = images.where((img) {
      final d = occlusionDataByImage[img.key];
      return d != null && !d.isEmpty;
    }).toList();
    final hasData = imagesWithData.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.occlusionSectionTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await Navigator.push<Map<String, OcclusionData>>(
              context,
              MaterialPageRoute(
                builder: (_) => ImageOcclusionSelectorScreen(
                  images: images,
                  initialData: occlusionDataByImage,
                ),
              ),
            );
            if (result != null) onChanged(result);
          },
          icon: const Icon(Icons.layers_outlined),
          label: Text(
            hasData ? l10n.editOcclusionAreas : l10n.defineOcclusionAreas,
          ),
        ),
        if (hasData) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                images.length == 1
                    ? l10n.occlusionSummary(
                        imagesWithData.first == images.first
                            ? (occlusionDataByImage[images.first.key]?.hiddenAreas.length ?? 0)
                            : 0,
                        imagesWithData.first == images.first
                            ? (occlusionDataByImage[images.first.key]?.highlights.length ?? 0)
                            : 0,
                      )
                    : l10n.occlusionImagesCount(imagesWithData.length, images.length),
                style: const TextStyle(color: Colors.green, fontSize: 13),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => onChanged({}),
                child: Text(
                  images.length == 1 ? l10n.occlusionClear : l10n.occlusionClearAll,
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
