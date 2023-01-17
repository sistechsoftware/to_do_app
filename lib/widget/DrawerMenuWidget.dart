import 'package:flutter/material.dart';

class DrawerMenuWidget  extends StatelessWidget {
  const DrawerMenuWidget({Key? key}): super (key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
        elevation: 10,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Add a new task'),
              onTap: () {

              },
            ),

            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Exit'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
       ),
    );
  }
}