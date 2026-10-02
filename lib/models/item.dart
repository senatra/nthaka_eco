class Item {
  final int itemId;
  final String itemName;
  final String? description;
  final double unitPrice;
  final String category;
  final DateTime? createdAt;

  Item({
    required this.itemId,
    required this.itemName,
    this.description,
    this.unitPrice = 0,
    this.category = 'General',
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
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
