class StockAdjustment {
  const StockAdjustment({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.previousQuantity,
    required this.newQuantity,
    required this.changeQuantity,
    required this.reason,
    required this.createdAt,
    this.notes,
  });

  final int id;
  final int itemId;
  final String itemName;
  final int previousQuantity;
  final int newQuantity;
  final int changeQuantity;
  final String reason;
  final String? notes;
  final DateTime createdAt;

  factory StockAdjustment.fromMap(Map<String, dynamic> map) => StockAdjustment(
        id: map['id'] as int,
        itemId: map['item_id'] as int,
        itemName: map['item_name'] as String,
        previousQuantity: map['previous_quantity'] as int,
        newQuantity: map['new_quantity'] as int,
        changeQuantity: map['change_quantity'] as int,
        reason: map['reason'] as String,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
