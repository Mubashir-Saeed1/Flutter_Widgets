import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_places_autocomplete/google_places_autocomplete.dart';

import '../../common/app_colors.dart';
import 'custom_loading.dart';
import 'custom_text.dart';

class PlacePredictionList extends StatelessWidget {
  final bool isLoading;
  final List<Prediction> predictions;
  final Future<void> Function({Prediction? selectedPrediction})
      handlePredictionTap;
  const PlacePredictionList({
    super.key,
    required this.isLoading,
    required this.predictions,
    required this.handlePredictionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CustomLoadingDots());
    }
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: predictions.isNotEmpty ? predictions.length * 60 : 0,
      color: kcWhiteColor.withValues(alpha: 0.8),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: predictions.length,
        itemBuilder: (context, index) {
          final prediction = predictions[index];
          if (prediction.title != null) {
            return InkWell(
              overlayColor: kOverlayColor,
              onTap: () {
                FocusScope.of(context).unfocus();
                handlePredictionTap(selectedPrediction: prediction);
              },
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.location_solid,
                    color: kcPrimaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ParagraphP1(prediction.title!),
                        if (prediction.description != null &&
                            prediction.description!.isNotEmpty)
                          ParagraphP1(prediction.title!),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
        separatorBuilder: (BuildContext context, int index) => Divider(
          thickness: 0.5,
          color: kcGreyTextColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
