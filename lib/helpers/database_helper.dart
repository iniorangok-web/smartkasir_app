
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/produk.dart';
import '../models/karyawan.dart';

// Kelas pengelola koneksi dan operasi database SQLite SmartKasir
class DatabaseHelper {
  // --- 1. DESIGN PATTERN SINGLETON ---
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  // Konstruktor privat
  DatabaseHelper._init();

  // --- 2. GETTER DATABASE ASINKRON ---
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('smartkasir.db');
    return _database!;
  }

  // --- 3. INISIALISASI DATABASE ---
  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      // Mengaktifkan SQLite untuk Google Chrome
      databaseFactory = databaseFactoryFfiWeb;

      return await openDatabase(
        filePath,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgradeDB,
      );
    } else {
      // Jalur database untuk Android
      final dbPath = await getDatabasesPath();
      final pathDB = join(dbPath, filePath);

      return await openDatabase(
        pathDB,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgradeDB,
      );
    }
  }

  // --- 4. PEMBUATAN TABEL DAN DATA AWAL ---
  Future<void> _createDB(Database db, int version) async {
    // 1. Pembuatan Tabel Produk
    await db.execute('''
      CREATE TABLE produk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_produk TEXT NOT NULL UNIQUE,
        nama_produk TEXT NOT NULL,
        kategori TEXT NOT NULL,
        harga_beli REAL NOT NULL,
        harga_jual REAL NOT NULL,
        stok INTEGER NOT NULL,
        gambar_path TEXT,
        diskon_persen INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Memasukkan 6 produk awal ke database
    final batch = db.batch();

    for (final produk in produkAwalSQLite) {
      final data = produk.toMap();
      data.remove('id');

      batch.insert('produk', data);
    }

    await batch.commit(noResult: true);

    // 2. Pembuatan Tabel Karyawan
    await db.execute('''
      CREATE TABLE karyawan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_karyawan TEXT NOT NULL,
        pin TEXT NOT NULL,
        peran TEXT NOT NULL
      )
    ''');

    // 3. Memasukkan data staf awal otomatis (Seeding Data Awal Toko)
    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Ahmad Kasir', '1234', 'Kasir')
    ''');
    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Siti Supervisor', '8888', 'Manajer')
    ''');
  }

  // DDL: Migrasi Skema jika versi basis data ditingkatkan
  Future<void> _onUpgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Membuat tabel karyawan untuk database pengguna yang sudah ada
      await db.execute('''
        CREATE TABLE IF NOT EXISTS karyawan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama_karyawan TEXT NOT NULL,
          pin TEXT NOT NULL,
          peran TEXT NOT NULL
        )
      ''');

      // Memasukkan staf awal jika tabel baru dibuat
      await db.rawInsert('''
        INSERT INTO karyawan (nama_karyawan, pin, peran)
        VALUES ('Ahmad Kasir', '1234', 'Kasir')
      ''');
    }
  }

  // ==========================================
  // METODE CRUD: TABEL KARYAWAN
  // ==========================================

  // 1. CREATE: Menyimpan Karyawan Baru
  Future<int> insertKaryawan(Karyawan karyawan) async {
    final db = await instance.database;
    return await db.insert('karyawan', karyawan.toMap());
  }

  // 2. READ: Mengambil Seluruh Karyawan
  Future<List<Karyawan>> getAllKaryawan() async {
    final db = await instance.database;
    final result = await db.query('karyawan', orderBy: 'id ASC');
    return result.map((json) => Karyawan.fromMap(json)).toList();
  }

  // 3. UPDATE: Memperbarui Data Karyawan
  Future<int> updateKaryawan(Karyawan karyawan) async {
    final db = await instance.database;
    return await db.update(
      'karyawan',
      karyawan.toMap(),
      where: 'id = ?',
      whereArgs: [karyawan.id],
    );
  }

  // 4. DELETE: Menghapus Karyawan Berdasarkan ID
  Future<int> deleteKaryawan(int id) async {
    final db = await instance.database;
    return await db.delete(
      'karyawan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // METODE CRUD: TABEL PRODUK (DARI MINGGU 11)
  // ==========================================

  // --- 5. CREATE: MENAMBAHKAN PRODUK ---
  Future<int> insertProduk(Produk produk) async {
    final db = await instance.database;

    final data = produk.toMap();
    data.remove('id');

    return await db.insert(
      'produk',
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // --- 6. READ: MENGAMBIL SEMUA PRODUK ---
  Future<List<Produk>> getAllProduk() async {
    final db = await instance.database;

    final result = await db.query(
      'produk',
      orderBy: 'harga_jual ASC',
    );

    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // --- 7. READ: FILTER BERDASARKAN KATEGORI ---
  Future<List<Produk>> getProdukByKategori(String kategori) async {
    final db = await instance.database;

    if (kategori == 'Semua') {
      return await getAllProduk();
    }

    final result = await db.query(
      'produk',
      where: 'kategori = ?',
      whereArgs: [kategori],
      orderBy: 'id DESC',
    );

    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // --- 8. SEARCH: PENCARIAN DENGAN SQL LIKE ---
  Future<List<Produk>> searchProduk(String keyword) async {
    final db = await instance.database;

    final result = await db.query(
      'produk',
      where: '''
        kode_produk LIKE ?
        OR nama_produk LIKE ?
        OR kategori LIKE ?
      ''',
      whereArgs: [
        '%$keyword%',
        '%$keyword%',
        '%$keyword%',
      ],
      orderBy: 'id DESC',
    );

    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // --- 9. UPDATE: MEMPERBARUI DATA PRODUK ---
  Future<int> updateProduk(Produk produk) async {
    final db = await instance.database;

    if (produk.id == null) {
      throw ArgumentError('ID produk tidak boleh kosong saat edit.');
    }

    final data = produk.toMap();
    data.remove('id');

    return await db.update(
      'produk',
      data,
      where: 'id = ?',
      whereArgs: [produk.id],
    );
  }

  // --- 10. DELETE: MENGHAPUS DATA PRODUK ---
  Future<int> deleteProduk(int id) async {
    final db = await instance.database;

    return await db.delete(
      'produk',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- 11. MENUTUP KONEKSI DATABASE ---
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
