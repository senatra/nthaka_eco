import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class Item {
  final int itemId;
  final String itemName;
  final String? description;
  final int userId;

  Item({
    required this.itemId,
    required this.itemName,
    this.description,
    required this.userId,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemId: json['itemId'],
      itemName: json['itemName'],
      description: json['description'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'description': description,
      'userId': userId,
    };
  }
}

class ItemRequest {
  final Item item;

  ItemRequest(this.item);

  Map<String, dynamic> toJson() => {
        'item': item.toJson(),
      };
}

class ItemsController {
  static const String baseUrl = 'http://10.0.2.2:5270/api/items';

  final User? user;
  final String? loggedInUserId;

  ItemsController()
      : user = FirebaseAuth.instance.currentUser,
        loggedInUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> checkLoggedIn() async {
    if (loggedInUserId == null) {
      throw Exception('User not logged in');
    }
  }

  Future<List<Item>> getItems() async {
    await checkLoggedIn();
    final response = await http.get(Uri.parse('$baseUrl/GetItems'));
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return List<Item>.from(list.map((model) => Item.fromJson(model)));
    } else {
      throw Exception('Failed to load items');
    }
  }

  Future<Item> getItem(int id) async {
    await checkLoggedIn();
    final response = await http.get(Uri.parse('$baseUrl/GetItemById/$id'));
    if (response.statusCode == 200) {
      return Item.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load item');
    }
  }

  Future<Item> createItem(ItemRequest createRequest) async {
    await checkLoggedIn();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(createRequest.toJson()),
    );
    if (response.statusCode == 201) {
      return Item.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create item');
    }
  }

  Future<void> modifyItem(int id, ItemRequest modifyRequest) async {
    await checkLoggedIn();
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(modifyRequest.toJson()),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to modify item');
    }
  }

  Future<void> deleteItem(int id) async {
    await checkLoggedIn();
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete item');
    }
  }
}
