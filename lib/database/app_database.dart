import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'bym360.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Kısayollar / Favori Menü Tablosu
        await db.execute('''
          CREATE TABLE kisayol (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            icon TEXT NOT NULL,
            text TEXT NOT NULL,
            parametre TEXT NOT NULL,
            classname TEXT NOT NULL,
            durum INTEGER DEFAULT 0
          )
        ''');

        // Sunucu Ayarları Tablosu
        await db.execute('''
          CREATE TABLE tbl_ayarlar (
            a_id INTEGER PRIMARY KEY,
            a_sunucuURL TEXT,
            a_sunucu TEXT
          )
        ''');
        await db.insert('tbl_ayarlar', {'a_id': 1, 'a_sunucuURL': '', 'a_sunucu': ''});

        // Hata Log Tablosu
        await db.execute('''
          CREATE TABLE tbl_hata (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tarih TEXT,
            islem TEXT,
            hata TEXT,
            kullanici TEXT
          )
        ''');

        // Kullanıcı Parametreleri Tablosu (tbl_islem_kprm)
        await db.execute('''
          CREATE TABLE tbl_islem_kprm (
            durum INTEGER,
            user_id INTEGER,
            nesne TEXT,
            deger TEXT,
            PRIMARY KEY (user_id, nesne)
          )
        ''');

        // Modül Parametreleri Tablosu (tbl_islem_mprm)
        await db.execute('''
          CREATE TABLE tbl_islem_mprm (
            durum INTEGER,
            m_id INTEGER,
            nesne TEXT,
            deger TEXT,
            a_durum INTEGER,
            PRIMARY KEY (m_id, nesne)
          )
        ''');

        // Offline Taslak Belge Tablosu
        await db.execute('''
          CREATE TABLE tbl_taslak_belge (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            belge_no TEXT,
            belge_turu TEXT,
            cari_id INTEGER,
            cari_adi TEXT,
            tarih TEXT,
            aciklama TEXT,
            durum TEXT DEFAULT 'DRAFT'
          )
        ''');
      },
    );
  }

  // Kısayol CRUD
  Future<List<Map<String, dynamic>>> getKisayollar() async {
    final db = await database;
    return db.query('kisayol');
  }

  Future<List<Map<String, dynamic>>> getFavoriKisayollar() async {
    final db = await database;
    return db.query('kisayol', where: 'durum = ?', whereArgs: [1]);
  }

  Future<void> saveKisayol(String icon, String text, String parametre, String classname, int durum) async {
    final db = await database;
    await db.insert('kisayol', {
      'icon': icon,
      'text': text,
      'parametre': parametre,
      'classname': classname,
      'durum': durum,
    });
  }

  Future<void> updateKisayolDurum(int id, int durum) async {
    final db = await database;
    await db.update('kisayol', {'durum': durum}, where: 'id = ?', whereArgs: [id]);
  }

  // Sunucu Ayarları
  Future<Map<String, String>> getSunucuAyarlari() async {
    final db = await database;
    final result = await db.query('tbl_ayarlar', where: 'a_id = ?', whereArgs: [1]);
    if (result.isNotEmpty) {
      return {
        'sunucuURL': result.first['a_sunucuURL']?.toString() ?? '',
        'sunucu': result.first['a_sunucu']?.toString() ?? '',
      };
    }
    return {'sunucuURL': '', 'sunucu': ''};
  }

  Future<void> updateSunucu(String sunucuURL, String sunucu) async {
    final db = await database;
    await db.update('tbl_ayarlar', {'a_sunucuURL': sunucuURL, 'a_sunucu': sunucu},
        where: 'a_id = ?', whereArgs: [1]);
  }

  // Hata Log
  Future<void> insertHata(String tarih, String islem, String hata, String kullanici) async {
    final db = await database;
    await db.insert('tbl_hata', {
      'tarih': tarih,
      'islem': islem,
      'hata': hata,
      'kullanici': kullanici,
    });
  }

  Future<List<Map<String, dynamic>>> getHataLogs() async {
    final db = await database;
    return db.query('tbl_hata', orderBy: 'id DESC');
  }

  // Parametre Önbelleği (IslemKprm & IslemMprm)
  Future<void> saveIslemKprmBatch(List<Map<String, dynamic>> items) async {
    final db = await database;
    final batch = db.batch();
    for (var item in items) {
      batch.insert('tbl_islem_kprm', item, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveIslemMprmBatch(List<Map<String, dynamic>> items) async {
    final db = await database;
    final batch = db.batch();
    for (var item in items) {
      batch.insert('tbl_islem_mprm', item, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // Offline Taslak Belge İşlemleri
  Future<int> insertTaslakBelge(Map<String, dynamic> belge) async {
    final db = await database;
    return db.insert('tbl_taslak_belge', belge);
  }

  Future<List<Map<String, dynamic>>> getTaslakBelgeler() async {
    final db = await database;
    return db.query('tbl_taslak_belge', orderBy: 'id DESC');
  }
}

