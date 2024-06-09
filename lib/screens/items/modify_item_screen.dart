import 'package:flutter/material.dart';
import 'package:nthaka_eco/api/items_api_service.dart';

class ModifyItemScreen extends StatefulWidget {
  final int itemId;

  ModifyItemScreen({required this.itemId});

  @override
  _ModifyItemScreenState createState() => _ModifyItemScreenState();
}

class _ModifyItemScreenState extends State<ModifyItemScreen> {
  final _formKey = GlobalKey<FormState>();
  String itemName = '';
  String? description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modify Item'),
      ),
      body: FutureBuilder<Item>(
        future: ItemsController().getItem(widget.itemId),
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
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: item.itemName,
                      decoration: InputDecoration(labelText: 'Item Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter item name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        itemName = value!;
                      },
                    ),
                    TextFormField(
                      initialValue: item.description,
                      decoration: InputDecoration(labelText: 'Description'),
                      onSaved: (value) {
                        description = value;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          final modifiedItem = Item(itemId: widget.itemId, itemName: itemName, description: description, userId: item.userId);
                          final request = ItemRequest(modifiedItem);
                          await ItemsController().modifyItem(widget.itemId, request);
                          Navigator.pop(context);
                        }
                      },
                      child: Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
