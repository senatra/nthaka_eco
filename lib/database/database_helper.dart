import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:nthaka_eco/models/device_profile.dart';
import 'package:nthaka_eco/models/disease_report.dart';
import 'package:nthaka_eco/models/item.dart';
import 'package:nthaka_eco/models/inventory_batch.dart';
import 'package:nthaka_eco/models/paged_result.dart';
import 'package:nthaka_eco/models/pos_session_state.dart';
import 'package:nthaka_eco/models/sale.dart';
import 'package:nthaka_eco/models/sales_report.dart';
import 'package:nthaka_eco/models/stock_adjustment.dart';
import 'package:nthaka_eco/services/local_storage_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'nthaka_eco.db';
  static const _dbVersion = 12;

  static const _settingWelcomeCompleted = 'welcome_completed';
  static const _settingAuthMode = 'auth_mode';
  static const _settingBusinessName = 'business_name';

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
        sku TEXT,
        barcode TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_taxable INTEGER NOT NULL DEFAULT 1,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        low_stock_threshold INTEGER NOT NULL DEFAULT 0,
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
        tax_rate REAL NOT NULL DEFAULT 0,
        tax_amount REAL NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL DEFAULT 'Cash',
        amount_paid REAL,
        change_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'completed',
        correction_note TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_adjustments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        previous_quantity INTEGER NOT NULL,
        new_quantity INTEGER NOT NULL,
        change_quantity INTEGER NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
      )
    ''');

    await _createBatchTables(db);

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
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
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
        ,severity TEXT
        ,location TEXT
        ,follow_up_at TEXT
        ,follow_up_done INTEGER NOT NULL DEFAULT 0
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

    await db.insert('app_settings', {
      'key': _settingWelcomeCompleted,
      'value': 'false',
    });
    await db.insert('app_settings', {
      'key': _settingAuthMode,
      'value': 'guest',
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
      case 5:
        await db.execute('''
          CREATE TABLE IF NOT EXISTS app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.insert(
            'app_settings',
            {
              'key': _settingWelcomeCompleted,
              'value': 'false',
            },
            conflictAlgorithm: ConflictAlgorithm.ignore);
        await db.insert(
            'app_settings',
            {
              'key': _settingAuthMode,
              'value': 'guest',
            },
            conflictAlgorithm: ConflictAlgorithm.ignore);
        break;
      case 6:
        await db.execute('ALTER TABLE items ADD COLUMN sku TEXT');
        await db.execute('ALTER TABLE items ADD COLUMN barcode TEXT');
        await db.execute(
          'ALTER TABLE items ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          "ALTER TABLE sales ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'Cash'",
        );
        await db.execute('ALTER TABLE sales ADD COLUMN amount_paid REAL');
        await db.execute(
          'ALTER TABLE sales ADD COLUMN change_amount REAL NOT NULL DEFAULT 0',
        );
        await db.execute(
          "ALTER TABLE sales ADD COLUMN status TEXT NOT NULL DEFAULT 'completed'",
        );
        await db.execute('ALTER TABLE sales ADD COLUMN correction_note TEXT');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_items_barcode ON items(barcode)',
        );
        break;
      case 7:
        await db
            .execute('ALTER TABLE disease_reports ADD COLUMN severity TEXT');
        await db
            .execute('ALTER TABLE disease_reports ADD COLUMN location TEXT');
        await db.execute(
            'ALTER TABLE disease_reports ADD COLUMN follow_up_at TEXT');
        await db.execute(
            'ALTER TABLE disease_reports ADD COLUMN follow_up_done INTEGER NOT NULL DEFAULT 0');
        break;
      case 8:
        await db.execute(
            'ALTER TABLE items ADD COLUMN stock_quantity INTEGER NOT NULL DEFAULT 0');
        await db.execute(
            'ALTER TABLE items ADD COLUMN low_stock_threshold INTEGER NOT NULL DEFAULT 0');
        break;
      case 9:
        await db.execute(
          'ALTER TABLE sales ADD COLUMN tax_rate REAL NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE sales ADD COLUMN tax_amount REAL NOT NULL DEFAULT 0',
        );
        break;
      case 10:
        await db.execute(
          'ALTER TABLE items ADD COLUMN is_taxable INTEGER NOT NULL DEFAULT 1',
        );
        break;
      case 11:
        await db.execute('''
          CREATE TABLE stock_adjustments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_id INTEGER NOT NULL,
            previous_quantity INTEGER NOT NULL,
            new_quantity INTEGER NOT NULL,
            change_quantity INTEGER NOT NULL,
            reason TEXT NOT NULL,
            notes TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
          )
        ''');
        break;
      case 12:
        await _createBatchTables(db);
        break;
      default:
        break;
    }
  }

  Future<void> _createBatchTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        batch_code TEXT NOT NULL,
        quantity_received INTEGER NOT NULL,
        quantity_remaining INTEGER NOT NULL,
        unit_cost REAL,
        received_at TEXT NOT NULL,
        expires_at TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_item_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_item_id INTEGER NOT NULL,
        batch_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (sale_item_id) REFERENCES sale_items(id) ON DELETE CASCADE,
        FOREIGN KEY (batch_id) REFERENCES inventory_batches(id) ON DELETE RESTRICT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_batches_item_fifo ON inventory_batches(item_id, expires_at, received_at)',
    );
  }

  Future<void> _seedReferenceData(Database db) async {
    final cropCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM crops')) ??
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

  Future<bool> isWelcomeCompleted() async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_settingWelcomeCompleted],
      limit: 1,
    );
    return rows.firstOrNull?['value'] == 'true';
  }

  Future<void> continueAsGuest() async {
    final db = await database;
    final batch = db.batch();
    batch.insert(
        'app_settings',
        {
          'key': _settingWelcomeCompleted,
          'value': 'true',
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert(
        'app_settings',
        {
          'key': _settingAuthMode,
          'value': 'guest',
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
    await batch.commit(noResult: true);
  }

  Future<String> getBusinessName() async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_settingBusinessName],
      limit: 1,
    );
    final value = rows.firstOrNull?['value'] as String?;
    return value == null || value.trim().isEmpty ? 'Nthaka.Eco' : value;
  }

  Future<void> updateBusinessName(String name) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': _settingBusinessName, 'value': name.trim()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> getSetting(String key, {required String fallback}) async {
    final db = await database;
    final rows = await db.query('app_settings',
        columns: ['value'], where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? fallback : rows.first['value'] as String;
  }

  Future<void> updateSetting(String key, String value) async {
    final db = await database;
    await db.insert('app_settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
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
    final total = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM items')) ??
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

  Future<Item?> getItemByBarcode(
    String barcode, {
    int? excludingItemId,
  }) async {
    final db = await database;
    final where =
        excludingItemId == null ? 'barcode = ?' : 'barcode = ? AND id != ?';
    final args = excludingItemId == null
        ? <Object>[barcode]
        : <Object>[barcode, excludingItemId];
    final rows = await db.query(
      'items',
      where: where,
      whereArgs: args,
      limit: 1,
    );
    return rows.isEmpty ? null : Item.fromMap(rows.first);
  }

  Future<Item> createItem(Item item) async {
    final db = await database;
    final id = await db.insert('items', {
      'item_name': item.itemName,
      'description': item.description,
      'unit_price': item.unitPrice,
      'category': item.category,
      'sku': item.sku,
      'barcode': item.barcode,
      'is_favorite': item.isFavorite ? 1 : 0,
      'is_taxable': item.isTaxable ? 1 : 0,
      'stock_quantity': item.stockQuantity,
      'low_stock_threshold': item.lowStockThreshold,
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
        'sku': item.sku,
        'barcode': item.barcode,
        'is_favorite': item.isFavorite ? 1 : 0,
        'is_taxable': item.isTaxable ? 1 : 0,
        'stock_quantity': item.stockQuantity,
        'low_stock_threshold': item.lowStockThreshold,
      },
      where: 'id = ?',
      whereArgs: [item.itemId],
    );
  }

  Future<void> adjustItemStock({
    required int itemId,
    required int changeQuantity,
    required String reason,
    String? notes,
  }) async {
    await _recordStockChange(
      itemId: itemId,
      changeQuantity: changeQuantity,
      reason: reason,
      notes: notes,
    );
  }

  Future<void> setItemStockCount({
    required int itemId,
    required int actualQuantity,
    String? notes,
  }) async {
    final db = await database;
    final rows = await db.query(
      'items',
      columns: ['stock_quantity'],
      where: 'id = ?',
      whereArgs: [itemId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final current = rows.first['stock_quantity'] as int;
    await _recordStockChange(
      itemId: itemId,
      changeQuantity: actualQuantity - current,
      reason: 'Stock count',
      notes: notes,
      reconcileBatches: true,
    );
  }

  Future<void> _recordStockChange({
    required int itemId,
    required int changeQuantity,
    required String reason,
    String? notes,
    bool reconcileBatches = false,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'items',
        columns: ['stock_quantity'],
        where: 'id = ?',
        whereArgs: [itemId],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final previous = rows.first['stock_quantity'] as int;
      final next = (previous + changeQuantity).clamp(0, 2147483647);
      await txn.update(
        'items',
        {'stock_quantity': next},
        where: 'id = ?',
        whereArgs: [itemId],
      );
      if (reconcileBatches && next < previous) {
        await _reduceBatchQuantities(
          txn,
          itemId: itemId,
          quantity: previous - next,
        );
      }
      await txn.insert('stock_adjustments', {
        'item_id': itemId,
        'previous_quantity': previous,
        'new_quantity': next,
        'change_quantity': next - previous,
        'reason': reason,
        'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> _reduceBatchQuantities(
    Transaction txn, {
    required int itemId,
    required int quantity,
  }) async {
    final batches = await txn.rawQuery('''
      SELECT id, quantity_remaining FROM inventory_batches
      WHERE item_id = ? AND quantity_remaining > 0
      ORDER BY CASE WHEN expires_at IS NULL THEN 1 ELSE 0 END DESC,
               expires_at DESC, received_at DESC
    ''', [itemId]);
    var remaining = quantity;
    for (final batch in batches) {
      if (remaining == 0) break;
      final available = batch['quantity_remaining'] as int;
      final removed = available < remaining ? available : remaining;
      await txn.update(
        'inventory_batches',
        {'quantity_remaining': available - removed},
        where: 'id = ?',
        whereArgs: [batch['id']],
      );
      remaining -= removed;
    }
  }

  Future<List<StockAdjustment>> getStockAdjustments({int limit = 50}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT sa.*, i.item_name
      FROM stock_adjustments sa
      INNER JOIN items i ON i.id = sa.item_id
      ORDER BY sa.created_at DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(StockAdjustment.fromMap).toList();
  }

  Future<InventoryBatch> createInventoryBatch({
    required int itemId,
    required String batchCode,
    required int quantity,
    double? unitCost,
    required DateTime receivedAt,
    DateTime? expiresAt,
    String? notes,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final itemRows = await txn.query(
        'items',
        columns: ['stock_quantity'],
        where: 'id = ?',
        whereArgs: [itemId],
        limit: 1,
      );
      if (itemRows.isEmpty) throw StateError('Item no longer exists');
      final previous = itemRows.first['stock_quantity'] as int;
      final now = DateTime.now();
      final batchId = await txn.insert('inventory_batches', {
        'item_id': itemId,
        'batch_code': batchCode.trim(),
        'quantity_received': quantity,
        'quantity_remaining': quantity,
        'unit_cost': unitCost,
        'received_at': receivedAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
        'created_at': now.toIso8601String(),
      });
      final next = previous + quantity;
      await txn.update('items', {'stock_quantity': next},
          where: 'id = ?', whereArgs: [itemId]);
      await txn.insert('stock_adjustments', {
        'item_id': itemId,
        'previous_quantity': previous,
        'new_quantity': next,
        'change_quantity': quantity,
        'reason': 'Batch received',
        'notes':
            'Batch ${batchCode.trim()}${notes?.trim().isNotEmpty == true ? ' · ${notes!.trim()}' : ''}',
        'created_at': now.toIso8601String(),
      });
      final rows = await txn.rawQuery('''
        SELECT b.*, i.item_name FROM inventory_batches b
        INNER JOIN items i ON i.id = b.item_id WHERE b.id = ?
      ''', [batchId]);
      return InventoryBatch.fromMap(rows.single);
    });
  }

  Future<List<InventoryBatch>> getInventoryBatches({
    int limit = 100,
    bool includeEmpty = false,
  }) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT b.*, i.item_name FROM inventory_batches b
      INNER JOIN items i ON i.id = b.item_id
      ${includeEmpty ? '' : 'WHERE b.quantity_remaining > 0'}
      ORDER BY CASE WHEN b.expires_at IS NULL THEN 1 ELSE 0 END,
               b.expires_at ASC, b.received_at ASC
      LIMIT ?
    ''', [limit]);
    return rows.map(InventoryBatch.fromMap).toList();
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
      whereParts.add('(item_name LIKE ? OR sku LIKE ? OR barcode LIKE ?)');
      args.addAll(['%$trimmed%', '%$trimmed%', '%$trimmed%']);
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      whereParts.add('category = ?');
      args.add(category);
    }

    final rows = await db.query(
      'items',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'is_favorite DESC, item_name ASC',
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
    final total = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM sales')) ??
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
    final row = await db.rawQuery(
      "SELECT SUM(total_amount) AS total FROM sales WHERE status != 'refunded'",
    );
    return (row.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<({double cashExpected, double totalSales, int saleCount})> getCashUp(
    DateTime day,
  ) async {
    final db = await database;
    final start = DateTime(day.year, day.month, day.day).toIso8601String();
    final end = DateTime(day.year, day.month, day.day + 1).toIso8601String();
    final rows = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN payment_method = 'Cash' THEN total_amount ELSE 0 END), 0) AS cash_expected,
        COALESCE(SUM(total_amount), 0) AS total_sales,
        COUNT(*) AS sale_count
      FROM sales
      WHERE date >= ? AND date < ? AND status != 'refunded'
      ''',
      [start, end],
    );
    final row = rows.first;
    return (
      cashExpected: (row['cash_expected'] as num?)?.toDouble() ?? 0,
      totalSales: (row['total_sales'] as num?)?.toDouble() ?? 0,
      saleCount: (row['sale_count'] as num?)?.toInt() ?? 0,
    );
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
        'tax_rate': sale.taxRate,
        'tax_amount': sale.taxAmount,
        'payment_method': sale.paymentMethod,
        'amount_paid': sale.amountPaid,
        'change_amount': sale.changeAmount,
        'status': sale.status,
        'correction_note': sale.correctionNote,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final item in sale.items) {
        final saleItemId = await txn.insert('sale_items', {
          'sale_id': saleId,
          'catalog_item_id': item.catalogItemId,
          'item_name': item.itemName,
          'quantity': item.quantity,
          'price': item.price,
        });
        if (item.catalogItemId != null) {
          await _allocateBatchesForSaleItem(
            txn,
            saleItemId: saleItemId,
            itemId: item.catalogItemId!,
            quantity: item.quantity,
          );
        }
      }

      for (final item in sale.items) {
        if (item.catalogItemId != null) {
          await txn.rawUpdate(
              'UPDATE items SET stock_quantity = MAX(0, stock_quantity - ?) WHERE id = ?',
              [item.quantity, item.catalogItemId]);
        }
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

  Future<void> _allocateBatchesForSaleItem(
    Transaction txn, {
    required int saleItemId,
    required int itemId,
    required int quantity,
  }) async {
    final batches = await txn.rawQuery('''
      SELECT id, quantity_remaining FROM inventory_batches
      WHERE item_id = ? AND quantity_remaining > 0
      ORDER BY CASE WHEN expires_at IS NULL THEN 1 ELSE 0 END,
               expires_at ASC, received_at ASC
    ''', [itemId]);
    var remainingToAllocate = quantity;
    for (final batch in batches) {
      if (remainingToAllocate == 0) break;
      final available = batch['quantity_remaining'] as int;
      final used =
          available < remainingToAllocate ? available : remainingToAllocate;
      await txn.update(
        'inventory_batches',
        {'quantity_remaining': available - used},
        where: 'id = ?',
        whereArgs: [batch['id']],
      );
      await txn.insert('sale_item_batches', {
        'sale_item_id': saleItemId,
        'batch_id': batch['id'],
        'quantity': used,
      });
      remainingToAllocate -= used;
    }
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
          'tax_rate': sale.taxRate,
          'tax_amount': sale.taxAmount,
          'payment_method': sale.paymentMethod,
          'amount_paid': sale.amountPaid,
          'change_amount': sale.changeAmount,
          'status': sale.status,
          'correction_note': sale.correctionNote,
        },
        where: 'id = ?',
        whereArgs: [sale.id],
      );
    });
  }

  Future<void> deleteSale(int id) async {
    final db = await database;
    await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> refundSale(int id, {String? note}) async {
    final db = await database;
    final sale = await getSale(id);
    if (sale == null || sale.status == 'refunded') return;

    await db.transaction((txn) async {
      await txn.update(
        'sales',
        {'status': 'refunded', 'correction_note': note},
        where: 'id = ?',
        whereArgs: [id],
      );
      for (final item in sale.items) {
        if (item.catalogItemId != null) {
          await txn.rawUpdate(
            'UPDATE items SET stock_quantity = stock_quantity + ? WHERE id = ?',
            [item.quantity, item.catalogItemId],
          );
        }
      }
      final allocations = await txn.rawQuery('''
        SELECT sib.batch_id, sib.quantity FROM sale_item_batches sib
        INNER JOIN sale_items si ON si.id = sib.sale_item_id
        WHERE si.sale_id = ?
      ''', [id]);
      for (final allocation in allocations) {
        await txn.rawUpdate(
          'UPDATE inventory_batches SET quantity_remaining = quantity_remaining + ? WHERE id = ?',
          [allocation['quantity'], allocation['batch_id']],
        );
      }
    });
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

  Future<List<DiseaseReport>> getDueFollowUps() async {
    final db = await database;
    final rows = await db.query('disease_reports',
        where:
            'follow_up_at IS NOT NULL AND follow_up_done = 0 AND follow_up_at <= ?',
        whereArgs: [DateTime.now().toIso8601String()],
        orderBy: 'follow_up_at ASC');
    return rows.map(DiseaseReport.fromMap).toList();
  }

  Future<void> markFollowUpDone(int id) async {
    final db = await database;
    await db.update('disease_reports', {'follow_up_done': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Item>> getLowStockItems() async {
    final db = await database;
    final rows = await db.query('items',
        where:
            'low_stock_threshold > 0 AND stock_quantity <= low_stock_threshold',
        orderBy: 'stock_quantity ASC');
    return rows.map(Item.fromMap).toList();
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
      'severity': report.severity,
      'location': report.location,
      'follow_up_at': report.followUpAt?.toIso8601String(),
      'follow_up_done': report.followUpDone ? 1 : 0,
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
      WHERE date >= ? AND date < ? AND status != 'refunded'
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
      WHERE date >= ? AND date < ? AND status != 'refunded'
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
      WHERE s.date >= ? AND s.date < ? AND s.status != 'refunded'
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
    final totalReports = Sqflite.firstIntValue(
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
