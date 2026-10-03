import 'dart:convert';

import 'package:nthaka_eco/models/pos_cart_line.dart';

class PosSessionState {
  final List<PosCartLine> lines;
  final String? customerName;
  final String? notes;
  final double discountAmount;
  final double taxRate;

  const PosSessionState({
    this.lines = const [],
    this.customerName,
    this.notes,
    this.discountAmount = 0,
    this.taxRate = 17.5,
  });

  double get subtotal => lines.fold(0, (sum, line) => sum + line.lineTotal);

  double get taxableAmount {
    final taxableSubtotal = lines
        .where((line) => line.isTaxable)
        .fold<double>(0, (sum, line) => sum + line.lineTotal);
    if (subtotal == 0) return 0;
    final taxDiscount = discountAmount * taxableSubtotal / subtotal;
    final value = taxableSubtotal - taxDiscount;
    return value < 0 ? 0 : value;
  }

  double get taxAmount => taxableAmount * taxRate / 100;

  double get total => taxableAmount + taxAmount;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  bool get isEmpty => lines.isEmpty;

  PosSessionState copyWith({
    List<PosCartLine>? lines,
    String? customerName,
    String? notes,
    double? discountAmount,
    double? taxRate,
  }) {
    return PosSessionState(
      lines: lines ?? this.lines,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lines': lines.map((line) => line.toJson()).toList(),
      'customer_name': customerName,
      'notes': notes,
      'discount_amount': discountAmount,
      'tax_rate': taxRate,
    };
  }

  factory PosSessionState.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? [];
    return PosSessionState(
      lines: rawLines
          .map((e) => PosCartLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      customerName: json['customer_name'] as String?,
      notes: json['notes'] as String?,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 17.5,
    );
  }

  static PosSessionState fromJsonString(String raw) {
    if (raw.trim().isEmpty) {
      return const PosSessionState();
    }
    return PosSessionState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  String toJsonString() => jsonEncode(toJson());
}

class ParkedSale {
  final int id;
  final String label;
  final PosSessionState session;
  final DateTime updatedAt;

  ParkedSale({
    required this.id,
    required this.label,
    required this.session,
    required this.updatedAt,
  });
}
