import 'package:flutter/material.dart';
import 'package:thingsboard_app/utils/ui/tb_text_styles.dart';

class AlarmDetailsContentWidget extends StatelessWidget {
  const AlarmDetailsContentWidget({
    required this.title,
    required this.details,
    this.detailsStyle,
    this.showDivider = true,
    super.key,
  });

  final String title;
  final String details;
  final TextStyle? detailsStyle;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TbTextStyles.bodyLarge.copyWith(
                color: Colors.white.withValues(alpha: .6),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: Text(
                details,
                textAlign: TextAlign.end,
                style: detailsStyle ??
                    TbTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Visibility(
          visible: showDivider,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: Colors.white.withValues(alpha: .95),
              thickness: 1,
              height: 0,
            ),
          ),
        ),
      ],
    );
  }
}
