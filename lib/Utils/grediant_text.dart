import 'package:flutter/material.dart';

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const GradientText({super.key, required this.style, required this.text});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [
            Color(0xff3523B6),
            Color(0xff7A3FC6),
            Color(0xffB157D4),
            Color(0xffD65DE5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: style.copyWith(
          color: Colors.white,
          // letterSpacing: 1.5, // Add your desired spacing here
        ),
      ),
    );
  }
}
