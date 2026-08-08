import 'package:flutter/material.dart';
import 'package:summer_iub_app/utility/constant.dart';

class AppBackgroudDesignWidget extends StatelessWidget {
  final Widget? child;


  const AppBackgroudDesignWidget({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(AppConstant.homePageBackgroundImage),
            fit: BoxFit.cover,
          )
        ),
        child: Container(
          color: Colors.white.withAlpha(150),
          child: child,
        )
    );
  }
}