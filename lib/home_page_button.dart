import 'package:flutter/material.dart';

class HomePageButton extends StatelessWidget {
  const HomePageButton({
    super.key,
    required this.name,
    required this.emoji,
    required this.onPressed,
  });

  final String name;
  final String emoji;
  final void Function()? onPressed;


  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50)
        ),
        child: Row(
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 24),
              ),
              const Spacer(),
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              )
            ]
        )
    );
  }
}
