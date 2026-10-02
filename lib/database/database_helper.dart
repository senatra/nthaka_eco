import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:nthaka_eco/models/device_profile.dart';
import 'package:nthaka_eco/models/disease_report.dart';
import 'package:nthaka_eco/models/item.dart';
import 'package:nthaka_eco/models/paged_result.dart';
import 'package:nthaka_eco/models/pos_session_state.dart';
import 'package:nthaka_eco/models/sale.dart';
import 'package:nthaka_eco/models/sales_report.dart';
import 'package:nthaka_eco/services/local_storage_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'nthaka_eco.db';
  static const _dbVersion = 3;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    await _seedReferenceData(db);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name TEXT NOT NULL,
        description TEXT,
        unit_price REAL NOT NULL DEFAULT 0,
        category TEXT NOT NULL DEFAULT 'General',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        customer_name TEXT,
        notes TEXT,
        discount_amount REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        catalog_item_id INTEGER,
        item_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pos_active_draft (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        cart_json TEXT NOT NULL DEFAULT '[]',
        customer_name TEXT,
        notes TEXT,
        discount_amount REAL NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE parked_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL,
        cart_json TEXT NOT NULL,
        customer_name TEXT,
        notes TEXT,
        discount_amount REAL NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE device_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        first_name TEXT,
        last_name TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE disease_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        crop TEXT NOT NULL,
        disease TEXT NOT NULL,
        confidence REAL,
        image_path TEXT,
        bounding_box_json TEXT,
        detected_at TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE crops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE diseases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        crop_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        symptoms_json TEXT,
        causes_json TEXT,
        treatments_json TEXT,
        prevention_json TEXT,
        FOREIGN KEY (crop_id) REFERENCES crops(id) ON DELETE CASCADE,
        UNIQUE(crop_id, name)
      )
    ''');

    await db.insert('device_profile', {
      'id': 1,
      'first_name': 'Local',
      'last_name': 'User',
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('pos_active_draft', {
      'id': 1,
      'cart_json': '[]',
      'discount_amount': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });

    await _createSalesIndexes(db);
  }

  Future<void> _createSalesIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_catalog_item_id ON sale_items(catalog_item_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_category ON items(category)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      await _migrateToVersion(db, version);
    }
  }

  Future<void> _migrateToVersion(Database db, int version) async {
    switch (version) {
      case 1:
        break;
      case 2:
        await db.execute(
          'ALTER TABLE items ADD COLUMN unit_price REAL NOT NULL DEFAULT 0',
        );
        break;
      case 3:
        await db.execute(
          "ALTER TABLE items ADD COLUMN category TEXT NOT NULL DEFAULT 'General'",
        );
        await db.execute('ALTER TABLE sales ADD COLUMN customer_name TEXT');
        await db.execute('ALTER TABLE sales ADD COLUMN notes TEXT');
        await db.execute(
          'ALTER TABLE sales ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE sale_items ADD COLUMN catalog_item_id INTEGER',
        );
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pos_active_draft (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            cart_json TEXT NOT NULL DEFAULT '[]',
            customer_name TEXT,
            notes TEXT,
            discount_amount REAL NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS parked_sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            label TEXT NOT NULL,
            cart_json TEXT NOT NULL,
            customer_name TEXT,
            notes TEXT,
            discount_amount REAL NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL
          )
        ''');
        final draftCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM pos_active_draft'),
            ) ??
            0;
        if (draftCount == 0) {
          await db.insert('pos_active_draft', {
            'id': 1,
            'cart_json': '[]',
            'discount_amount': 0,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
        await _createSalesIndexes(db);
        break;
      default:
        break;
    }
  }

  Future<void> _seedReferenceData(Database db) async {
    final cropCount =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM crops')) ??
            0;
    if (cropCount > 0) {
      return;
    }

    const cropAssets = {
      'maize': 'assets/data/maize.json',
      'tomato': 'assets/data/tomato.json',
      'cassava': 'assets/data/cassava.json',
      'cashew': 'assets/data/cashew.json',
    };

    for (final entry in cropAssets.entries) {
      final cropId = await db.insert('crops', {'name': entry.key});
      final jsonString = await rootBundle.loadString(entry.value);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final diseases = data['diseases'] as List<dynamic>;

      for (final disease in diseases) {
        final diseaseMap = disease as Map<String, dynamic>;
        await db.insert('diseases', {
          'crop_id': cropId,
          'name': diseaseMap['name'],
          'symptoms_json': jsonEncode(diseaseMap['symptoms']),
          'causes_json': jsonEncode(diseaseMap['causes']),
          'treatments_json': jsonEncode(diseaseMap['treatments']),
          'prevention_json': jsonEncode(diseaseMap['prevention']),
        });
      }
    }
  }

  Future<List<Item>> getItems() async {
    final page = await getItemsPaged(limit: 50, offset: 0);
    return page.items;
  }

  Future<PagedResult<Item>> getItemsPaged({
    required int limit,
    required int offset,
  }) async {
    final db = await database;
    final total =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM items')) ??
            0;
    final rows = await db.query(
      'items',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return PagedResult(
      items: rows.map(Item.fromMap).toList(),
      totalCount: total,
      offset: offset,
      limit: limit,
    );
  }

  Future<Item?> getItem(int id) async {
    final db = await database;
    final rows = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Item.fromMap(rows.first);
  }

  Future<Item> createItem(Item item) async {
    final db = await database;
    final id = await db.insert('items', {
      'item_name': item.itemName,
      'description': item.description,
      'unit_price': item.unitPrice,
      'category': item.category,
      'created_at': DateTime.now().toIso8601String(),
    });
    final created = await getItem(id);
    return created!;
  }

  Future<void> updateItem(Item item) async {
    final db = await database;
    await db.update(
      'items',
      {
        'item_name': item.itemName,
        'description': item.description,
        'unit_price': item.unitPrice,
        'category': item.category,
      },
      where: 'id = ?',
      whereArgs: [item.itemId],
    );
  }

  Future<List<String>> getItemCategories() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT category FROM items
      ORDER BY category ASC
    ''');
    final categories = rows
        .map((row) => (row['category'] as String?)?.trim())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toList();
    if (!categories.contains('General')) {
      categories.insert(0, 'General');
    }
    return categories.isEmpty ? ['General'] : categories;
  }

  Future<List<Item>> searchCatalogItems({
    String query = '',
    String? category,
    int limit = 120,
  }) async {
    final db = await database;
    final trimmed = query.trim();
    final whereParts = <String>[];
    final args = <Object?>[];

    if (trimmed.isNotEmpty) {
      whereParts.add('item_name LIKE ?');
      args.add('%$trimmed%');
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      whereParts.add('category = ?');
      args.add(category);
    }

    final rows = await db.query(
      'items',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'item_name ASC',
      limit: limit,
    );
    return rows.map(Item.fromMap).toList();
  }

  Future<void> deleteItem(int id) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Sale>> getSales() async {
    final page = await getSalesPaged(limit: 50, offset: 0);
    return page.items;
  }

  Future<PagedResult<Sale>> getSalesPaged({
    required int limit,
    required int offset,
  }) async {
    final db = await database;
    final total =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sales')) ??
            0;
    final saleRows = await db.query(
      'sales',
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );
    final sales = <Sale>[];

    for (final saleRow in saleRows) {
      final saleId = saleRow['id'] as int;
      final itemRows = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      sales.add(
        Sale.fromMap(
          saleRow,
          items: itemRows.map(SaleItem.fromMap).toList(),
        ),
      );
    }

    return PagedResult(
      items: sales,
      totalCount: total,
      offset: offset,
      limit: limit,
    );
  }

  Future<double> getTotalSalesAmount() async {
    final db = await database;
    final row = await db.rawQuery('SELECT SUM(total_amount) AS total FROM sales');
    return (row.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<Sale?> getSale(int id) async {
    final db = await database;
    final saleRows = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (saleRows.isEmpty) {
      return null;
    }

    final itemRows = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [id],
    );
    return Sale.fromMap(
      saleRows.first,
      items: itemRows.map(SaleItem.fromMap).toList(),
    );
  }

  Future<Sale> createSale(Sale sale) async {
    final db = await database;
    return db.transaction((txn) async {
      final saleId = await txn.insert('sales', {
        'date': sale.date.toIso8601String(),
        'total_amount': sale.totalAmount,
        'customer_name': sale.customerName,
        'notes': sale.notes,
        'discount_amount': sale.discountAmount,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final item in sale.items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'catalog_item_id': item.catalogItemId,
          'item_name': item.itemName,
          'quantity': item.quantity,
          'price': item.price,
        });
      }

      final createdRows = await txn.query(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
        limit: 1,
      );
      final itemRows = await txn.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      return Sale.fromMap(
        createdRows.first,
        items: itemRows.map(SaleItem.fromMap).toList(),
      );
    });
  }

  Future<void> updateSale(Sale sale) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'sales',
        {
          'date': sale.date.toIso8601String(),
          'total_amount': sale.totalAmount,
          'customer_name': sale.customerName,
          'notes': sale.notes,
          'discount_amount': sale.discountAmount,
        },
        where: 'id = ?',
        whereArgs: [sale.id],
      );

      await txn.delete(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [sale.id],
      );

      for (final item in sale.items) {
        await txn.insert('sale_items', {
          'sale_id': sale.id,
          'catalog_item_id': item.catalogItemId,
          'item_name': item.itemName,
          'quantity': item.quantity,
          'price': item.price,
        });
      }
    });
  }

  Future<void> deleteSale(int id) async {
    final db = await database;
    await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }

  Future<DeviceProfile> getDeviceProfile() async {
    final db = await database;
    final rows = await db.query('device_profile', where: 'id = 1', limit: 1);
    if (rows.isEmpty) {
      return DeviceProfile(firstName: 'Local', lastName: 'User');
    }
    return DeviceProfile.fromMap(rows.first);
  }

  Future<void> updateDeviceProfile(DeviceProfile profile) async {
    final db = await database;
    await db.insert(
      'device_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DiseaseReport>> getDiseaseReports() async {
    final page = await getDiseaseReportsPaged(limit: 50, offset: 0);
    return page.items;
  }

  Future<PagedResult<DiseaseReport>> getDiseaseReportsPaged({
    required int limit,
    required int offset,
  }) async {
    final db = await database;
    final total = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM disease_reports'),
        ) ??
        0;
    final rows = await db.query(
      'disease_reports',
      orderBy: 'detected_at DESC',
      limit: limit,
      offset: offset,
    );
    return PagedResult(
      items: rows.map(DiseaseReport.fromMap).toList(),
      totalCount: total,
      offset: offset,
      limit: limit,
    );
  }

  Future<List<String>> getCropNames() async {
    final db = await database;
    final rows = await db.query('crops', orderBy: 'name ASC');
    return rows.map((row) => row['name'] as String).toList();
  }

  Future<({int itemCount, int saleCount, int reportCount, double salesTotal})>
      getDashboardStats() async {
    final db = await database;
    final itemCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM items'),
        ) ??
        0;
    final saleCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sales'),
        ) ??
        0;
    final reportCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM disease_reports'),
        ) ??
        0;
    final salesTotal = await getTotalSalesAmount();
    return (
      itemCount: itemCount,
      saleCount: saleCount,
      reportCount: reportCount,
      salesTotal: salesTotal,
    );
  }

  Future<DiseaseReport> createDiseaseReport(DiseaseReport report) async {
    final db = await database;
    final id = await db.insert('disease_reports', {
      'crop': report.crop,
      'disease': report.disease,
      'confidence': report.confidence,
      'image_path': report.imagePath,
      'bounding_box_json': report.boundingBoxJson,
      'detected_at': report.detectedAt.toIso8601String(),
      'notes': report.notes,
    });

    final rows = await db.query(
      'disease_reports',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return DiseaseReport.fromMap(rows.first);
  }

  Future<void> deleteDiseaseReport(int id) async {
    final db = await database;
    final rows = await db.query(
      'disease_reports',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await LocalStorageService.deleteImageFile(
        rows.first['image_path'] as String?,
      );
    }
    await db.delete('disease_reports', where: 'id = ?', whereArgs: [id]);
  }

  Future<PosSessionState> loadActivePosDraft() async {
    final db = await database;
    final rows = await db.query('pos_active_draft', where: 'id = 1', limit: 1);
    if (rows.isEmpty) {
      return const PosSessionState();
    }
    return PosSessionState.fromJsonString(
      rows.first['cart_json'] as String? ?? '[]',
    );
  }

  Future<void> saveActivePosDraft(PosSessionState session) async {
    final db = await database;
    await db.insert(
      'pos_active_draft',
      {
        'id': 1,
        'cart_json': session.toJsonString(),
        'customer_name': session.customerName,
        'notes': session.notes,
        'discount_amount': session.discountAmount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearActivePosDraft() async {
    await saveActivePosDraft(const PosSessionState());
  }

  Future<int> parkSale(String label, PosSessionState session) async {
    final db = await database;
    return db.insert('parked_sales', {
      'label': label,
      'cart_json': session.toJsonString(),
      'customer_name': session.customerName,
      'notes': session.notes,
      'discount_amount': session.discountAmount,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<ParkedSale>> listParkedSales() async {
    final db = await database;
    final rows = await db.query('parked_sales', orderBy: 'updated_at DESC');
    return rows.map((row) {
      final session = PosSessionState.fromJsonString(
        row['cart_json'] as String? ?? '[]',
      );
      return ParkedSale(
        id: row['id'] as int,
        label: row['label'] as String,
        session: session,
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );
    }).toList();
  }

  Future<void> deleteParkedSale(int id) async {
    final db = await database;
    await db.delete('parked_sales', where: 'id = ?', whereArgs: [id]);
  }

  Future<SalesReportBundle> getSalesReport({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final db = await database;
    final startIso = start.toIso8601String();
    final endIso = endExclusive.toIso8601String();

    final summaryRow = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(total_amount), 0) AS revenue,
        COUNT(*) AS sale_count
      FROM sales
      WHERE date >= ? AND date < ?
      ''',
      [startIso, endIso],
    );

    final revenue = (summaryRow.first['revenue'] as num?)?.toDouble() ?? 0;
    final saleCount = (summaryRow.first['sale_count'] as num?)?.toInt() ?? 0;
    final average = saleCount == 0 ? 0.0 : revenue / saleCount;

    final dayRows = await db.rawQuery(
      '''
      SELECT substr(date, 1, 10) AS day_key, COALESCE(SUM(total_amount), 0) AS total
      FROM sales
      WHERE date >= ? AND date < ?
      GROUP BY day_key
      ORDER BY day_key ASC
      ''',
      [startIso, endIso],
    );

    final topRows = await db.rawQuery(
      '''
      SELECT
        COALESCE(si.item_name, 'Unknown') AS name,
        COALESCE(SUM(si.quantity), 0) AS qty,
        COALESCE(SUM(si.quantity * si.price), 0) AS revenue
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      WHERE s.date >= ? AND s.date < ?
      GROUP BY si.item_name
      ORDER BY qty DESC, revenue DESC
      LIMIT 10
      ''',
      [startIso, endIso],
    );

    final saleRows = await db.query(
      'sales',
      where: 'date >= ? AND date < ?',
      whereArgs: [startIso, endIso],
      orderBy: 'date DESC',
      limit: 500,
    );

    final transactions = <Sale>[];
    for (final saleRow in saleRows) {
      final saleId = saleRow['id'] as int;
      final itemRows = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      transactions.add(
        Sale.fromMap(
          saleRow,
          items: itemRows.map(SaleItem.fromMap).toList(),
        ),
      );
    }

    return SalesReportBundle(
      summary: SalesReportSummary(
        totalRevenue: revenue,
        saleCount: saleCount,
        averageSale: average,
      ),
      salesByDay: dayRows
          .map(
            (row) => SalesDayTotal(
              dayKey: row['day_key'] as String? ?? '',
              total: (row['total'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList(),
      topItems: topRows
          .map(
            (row) => TopSellingItem(
              name: row['name'] as String? ?? 'Unknown',
              quantity: (row['qty'] as num?)?.toInt() ?? 0,
              revenue: (row['revenue'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList(),
      transactions: transactions,
    );
  }

  Future<DiseaseAnalytics> getDiseaseAnalytics() async {
    final db = await database;
    final totalReports =
        Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM disease_reports'),
            ) ??
            0;

    if (totalReports == 0) {
      return DiseaseAnalytics(
        totalReports: 0,
        mostCommonDisease: 'None',
        mostCommonCrop: 'None',
      );
    }

    final diseaseRows = await db.rawQuery('''
      SELECT disease, COUNT(*) as count
      FROM disease_reports
      GROUP BY disease
      ORDER BY count DESC
      LIMIT 1
    ''');

    final cropRows = await db.rawQuery('''
      SELECT crop, COUNT(*) as count
      FROM disease_reports
      GROUP BY crop
      ORDER BY count DESC
      LIMIT 1
    ''');

    return DiseaseAnalytics(
      totalReports: totalReports,
      mostCommonDisease: diseaseRows.first['disease'] as String? ?? 'None',
      mostCommonCrop: cropRows.first['crop'] as String? ?? 'None',
    );
  }
}
