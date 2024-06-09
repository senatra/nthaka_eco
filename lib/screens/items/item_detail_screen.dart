import 'package:flutter/material.dart';
import 'package:nthaka_eco/api/items_api_service.dart';
import 'package:nthaka_eco/screens/items/modify_item_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final int itemId;

  ItemDetailScreen({required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModifyItemScreen(itemId: itemId),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              await ItemsController().deleteItem(itemId);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: FutureBuilder<Item>(
        future: ItemsController().getItem(itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('Item not found'));
          } else {
            final item = snapshot.data!;
            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${item.itemName}', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 10),
                  Text('Description: ${item.description ?? 'No description'}'),
                  SizedBox(height: 10),
                  Text('User ID: ${item.userId}'),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
