import 'dart:convert';
import 'package:http/http.dart' as http;

class SalesApiService {
  final String _baseUrl = 'http://10.0.2.2:5130/api'; 

  Future<List<Sale>> getSales() async {
    final response = await http.get(Uri.parse('$_baseUrl/Sale')); // Adjust endpoint if necessary

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Sale.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load sales');
    }
  }

  Future<Sale> getSale(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/Sale/$id')); // Adjust endpoint if necessary

    if (response.statusCode == 200) {
      return Sale.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load sale');
    }
  }

  Future<void> createSale(Sale sale) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/Sale'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(sale.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create sale');
    }
  }

  Future<void> updateSale(int id, Sale sale) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/Sale/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(sale.toJson()),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to update sale');
    }
  }
}

class Sale {
  final int id;
  final DateTime date;
  final double totalAmount;
  final List<SaleItem> items;

  Sale({required this.id, required this.date, required this.totalAmount, required this.items});

  factory Sale.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List;
    List<SaleItem> itemsList = list.map((i) => SaleItem.fromJson(i)).toList();

    return Sale(
      id: json['id'],
      date: DateTime.parse(json['date']),
      totalAmount: json['totalAmount'],
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    List<Map> itemsList = items.map((i) => i.toJson()).toList();

    return {
      'id': id,
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'items': itemsList,
    };
  }
}

class SaleItem {
  final int id;
  final String itemName;
  final int quantity;
  final double price;

  SaleItem({required this.id, required this.itemName, required this.quantity, required this.price});

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'],
      itemName: json['itemName'],
      quantity: json['quantity'],
      price: json['price'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'quantity': quantity,
      'price': price,
    };
  }
}
