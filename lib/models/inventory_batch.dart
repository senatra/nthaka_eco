class InventoryBatch {
  const InventoryBatch({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.batchCode,
    required this.quantityReceived,
    required this.quantityRemaining,
    required this.receivedAt,
    required this.createdAt,
    this.unitCost,
    this.expiresAt,
    this.notes,
  });

  final int id;
  final int itemId;
  final String itemName;
  final String batchCode;
  final int quantityReceived;
  final int quantityRemaining;
  final double? unitCost;
  final DateTime receivedAt;
  final DateTime? expiresAt;
  final String? notes;
  final DateTime createdAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get expiresSoon =>
      expiresAt != null &&
      !isExpired &&
      expiresAt!.isBefore(DateTime.now().add(const Duration(days: 30)));

  factory InventoryBatch.fromMap(Map<String, dynamic> map) => InventoryBatch(
        id: map['id'] as int,
        itemId: map['item_id'] as int,
        itemName: map['item_name'] as String,
        batchCode: map['batch_code'] as String,
        quantityReceived: map['quantity_received'] as int,
        quantityRemaining: map['quantity_remaining'] as int,
        unitCost: (map['unit_cost'] as num?)?.toDouble(),
        receivedAt: DateTime.parse(map['received_at'] as String),
        expiresAt: map['expires_at'] == null
            ? null
            : DateTime.parse(map['expires_at'] as String),
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
