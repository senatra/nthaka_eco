class Item {
  final int itemId;
  final String itemName;
  final String? description;
  final double unitPrice;
  final String category;
  final String? sku;
  final String? barcode;
  final bool isFavorite;
  final int stockQuantity;
  final int lowStockThreshold;
  final DateTime? createdAt;

  Item({
    required this.itemId,
    required this.itemName,
    this.description,
    this.unitPrice = 0,
    this.category = 'General',
    this.sku,
    this.barcode,
    this.isFavorite = false,
    this.stockQuantity = 0,
    this.lowStockThreshold = 0,
    this.createdAt,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      itemId: map['id'] as int,
      itemName: map['item_name'] as String,
      description: map['description'] as String?,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
      category: (map['category'] as String?)?.trim().isNotEmpty == true
          ? map['category'] as String
          : 'General',
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      isFavorite: (map['is_favorite'] as num?)?.toInt() == 1,
      stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (map['low_stock_threshold'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (itemId != 0) 'id': itemId,
      'item_name': itemName,
      'description': description,
      'unit_price': unitPrice,
      'category': category,
      'sku': sku,
      'barcode': barcode,
      'is_favorite': isFavorite ? 1 : 0,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
