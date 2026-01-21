import 'package:flutter/material.dart';
import 'package:thingsboard_app/thingsboard_client.dart';
import 'package:thingsboard_app/utils/ui/tb_text_styles.dart';
import 'package:timeago/timeago.dart' as timeago;

class SystemActivityWidget extends StatelessWidget {
  const SystemActivityWidget(this.activity, {super.key});

  final AlarmCommentInfo activity;

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(activity.createdTime),
    );

    return Container(
      color: Color(0xFF0D2743),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          timeago.format(DateTime.now().subtract(diff)),
          style: TbTextStyles.labelMedium.copyWith(
            color: Colors.white.withValues(alpha: .62),
          ),
        ),
        Text(
          activity.comment.text,
          style: TbTextStyles.bodyLarge.copyWith(
            color: Colors.white.withValues(alpha: .46),
          ),
        ),
      ],
    ),
    );
  }
}
