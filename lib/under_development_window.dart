import 'package:flutter/material.dart';

void underDevelopment(String title, BuildContext context){
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => UnderDevelopmentWindow(title: title,)),
  );
}

class UnderDevelopmentWindow extends StatelessWidget {
  const UnderDevelopmentWindow({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.amber,
          centerTitle: true,
        ),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: <Widget>[
                  const Icon(Icons.construction, size: 90),
                  const SizedBox(height: 50),
                  const Text(
                      'This page is currently under development\nPlease come back later.',
                      textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  ElevatedButton(onPressed: () {
                    Navigator.pop(context);
                  }, child: const Text('Home'))
                ]
            )
        )
    );
  }
}