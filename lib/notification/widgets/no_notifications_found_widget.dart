import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/messages.dart';


class NoNotificationsFoundWidget extends StatelessWidget {
  const NoNotificationsFoundWidget({super.key});


  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No se han encontrado notificaciones',
            //'No notifications found',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
