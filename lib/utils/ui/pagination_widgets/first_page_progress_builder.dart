import 'package:flutter/material.dart';

class FirstPageProgressBuilder extends StatelessWidget {
  const FirstPageProgressBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF091D30),
      child: const Stack(
      children: [
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RefreshProgressIndicator(),
            ],
          ),
        ),
      ],
    ),
    );
  }
}
