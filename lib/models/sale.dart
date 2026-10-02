class Sale {
  final int id;
  final DateTime date;
  final double totalAmount;
  final String? customerName;
  final String? notes;
  final double discountAmount;
  final List<SaleItem> items;

  Sale({
    required this.id,
    required this.date,
    required this.totalAmount,
    this.customerName,
    this.notes,
    this.discountAmount = 0,
    required this.items,
  });

  factory Sale.fromMap(Map<String, dynamic> map, {List<SaleItem>? items}) {
    return Sale(
      id: map['id'] as int,
      date: DateTime.parse(map['date'] as String),
      totalAmount: (map['total_amount'] as num).toDouble(),
      customerName: map['customer_name'] as String?,
      notes: map['notes'] as String?,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      items: items ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'customer_name': customerName,
      'notes': notes,
      'discount_amount': discountAmount,
    };
  }
}

class SaleItem {
  final int id;
  final int saleId;
  final int? catalogItemId;
  final String itemName;
  final int quantity;
  final double price;

  SaleItem({
    required this.id,
    required this.saleId,
    this.catalogItemId,
    required this.itemName,
    required this.quantity,
    required this.price,
  });

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int,
      saleId: map['sale_id'] as int,
      catalogItemId: map['catalog_item_id'] as int?,
      itemName: map['item_name'] as String,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'sale_id': saleId,
      'catalog_item_id': catalogItemId,
      'item_name': itemName,
      'quantity': quantity,
      'price': price,
    };
  }
}
