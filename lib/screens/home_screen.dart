

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget{
  @override
  Widget build(BuildContext context, WidgetRef ref) {
   return Scaffold(
     body: Center(
       child: Text("Home Page"),
     ),
   );
  }

}