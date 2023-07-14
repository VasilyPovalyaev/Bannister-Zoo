import 'package:flutter/material.dart';
import 'home_page_button.dart';
import 'under_development_window.dart';
import 'koopa_window.dart';
import 'dart:core';

class MyHomePage extends StatelessWidget{
  const MyHomePage({
    super.key,
    required this.title
  });

  final String title;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.amber,
          title: Text(title),
          centerTitle: true
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,


          children: <Widget>[
            HomePageButton(name: 'Dottie', emoji: '🐴', onPressed: () => underDevelopment('Dottie',context),),
            const SizedBox(height: 5,),
            HomePageButton(name: 'Koopa', emoji: '🐢', onPressed: () => koopa('Koopa',context),),
            const SizedBox(height: 5,),
            HomePageButton(name: 'Fish', emoji: '🐟', onPressed: () => underDevelopment('Fish',context),),
            const SizedBox(height: 5,),
            HomePageButton(name: 'Dogs', emoji: '🐕', onPressed: () => underDevelopment('Dogs',context),),
            const SizedBox(height: 5,),
          ],
        ),
      ),
    );
  }
}