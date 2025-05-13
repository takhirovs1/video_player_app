import 'package:flutter/material.dart';

import '../../../../common/constants/app_colors.dart';

class ViewRichtext extends StatelessWidget {
  const ViewRichtext({required this.mainText, required this.text, super.key});

  final String mainText;
  final String text;

  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(
      style: const TextStyle(fontSize: 18),
      children: [
        TextSpan(
          text: mainText,
          style: const TextStyle(fontSize: 18, color: AppColors.red, fontWeight: FontWeight.w600),
        ),
        TextSpan(text: text),
      ],
    ),
  );
}
