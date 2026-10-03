class PosCartLine {
  final int? catalogItemId;
  final String name;
  final double unitPrice;
  final bool isTaxable;
  int quantity;

  PosCartLine({
    this.catalogItemId,
    required this.name,
    required this.unitPrice,
    this.isTaxable = true,
    this.quantity = 1,
  });

  double get lineTotal => unitPrice * quantity;

  String get cartKey =>
      catalogItemId != null ? 'id_$catalogItemId' : 'custom_$name|$unitPrice';

  Map<String, dynamic> toJson() => {
        'catalog_item_id': catalogItemId,
        'name': name,
        'unit_price': unitPrice,
        'is_taxable': isTaxable,
        'quantity': quantity,
      };

  factory PosCartLine.fromJson(Map<String, dynamic> json) {
    return PosCartLine(
      catalogItemId: json['catalog_item_id'] as int?,
      name: json['name'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      isTaxable: json['is_taxable'] as bool? ?? true,
      quantity: json['quantity'] as int,
    );
  }

  PosCartLine copyWith({int? quantity}) {
    return PosCartLine(
      catalogItemId: catalogItemId,
      name: name,
      unitPrice: unitPrice,
      isTaxable: isTaxable,
      quantity: quantity ?? this.quantity,
    );
  }
}
