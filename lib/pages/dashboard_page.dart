
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/produk.dart';
import '../helpers/database_helper.dart';
import 'form_produk_page.dart';

// ==========================================
// HALAMAN DASHBOARD SMARTKASIR
// ==========================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // TEMA WARNA BABY PINK
  static const Color pinkUtama = Color(0xFFF48FB1);
  static const Color pinkTua = Color(0xFFEC407A);
  static const Color pinkMuda = Color(0xFFF8BBD0);
  static const Color backgroundPink = Color(0xFFFFF5F8);

  // KATEGORI PRODUK
  int _kategoriTerpilih = 0;

  final List<String> _kategoriList = [
    'Semua',
    'Makanan',
    'Minuman',
    'Snack',
    'Dessert',
    'Lainnya',
  ];

  // FUTURE DATABASE
  late Future<List<Produk>> _produkFuture;

  // SEARCH CONTROLLER
  final TextEditingController _searchController =
      TextEditingController();

  String _keywordPencarian = '';

  // FORMAT RUPIAH
  String _formatRupiah(double nominal) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return formatCurrency.format(nominal);
  }

  @override
  void initState() {
    super.initState();
    _muatDataProduk();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // MEMUAT DATA PRODUK DARI SQLITE
  // ==========================================

  void _muatDataProduk() {
    final keyword = _keywordPencarian.trim();

    setState(() {
      if (keyword.isNotEmpty) {
        _produkFuture =
            DatabaseHelper.instance.searchProduk(keyword);
      } else {
        _produkFuture =
            DatabaseHelper.instance.getProdukByKategori(
          _kategoriList[_kategoriTerpilih],
        );
      }
    });
  }

  // ==========================================
  // DIALOG KONFIRMASI HAPUS PRODUK
  // ==========================================

  Future<void> _konfirmasiHapusProduk(
    BuildContext context,
    Produk item,
  ) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: pinkTua,
            ),
            SizedBox(width: 8),
            Text('Hapus Produk?'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus '
          '"${item.nama}" dari database SQLite?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: pinkTua,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi == true && item.id != null) {
      try {
        await DatabaseHelper.instance.deleteProduk(item.id!);

        if (!mounted) return;

        _muatDataProduk();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Produk "${item.nama}" berhasil dihapus!',
            ),
            backgroundColor: pinkTua,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus produk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==========================================
  // BADGE STATUS STOK
  // ==========================================

  Widget _buildBadgeStok(int stok) {
    Color warnaLatar;
    Color warnaTeks;
    String label;

    if (stok == 0) {
      warnaLatar = Colors.red.shade100;
      warnaTeks = Colors.red.shade900;
      label = 'Habis';
    } else if (stok <= 5) {
      warnaLatar = Colors.amber.shade100;
      warnaTeks = Colors.amber.shade900;
      label = 'Sisa $stok';
    } else {
      warnaLatar = Colors.green.shade100;
      warnaTeks = Colors.green.shade900;
      label = 'Stok $stok';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: warnaLatar,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: warnaTeks,
        ),
      ),
    );
  }

  // ==========================================
  // KARTU PRODUK
  // ==========================================

  Widget _buildProductCard(Produk item) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pinkMuda.withValues(alpha: 0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: pinkUtama.withValues(alpha: 0.12),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FOTO PRODUK
          Stack(
            children: [
              Image.network(
                item.gambarUrl,
                height: 105,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 105,
                    width: double.infinity,
                    color: backgroundPink,
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 38,
                      color: pinkUtama,
                    ),
                  );
                },
              ),

              // BADGE PROMO
              if (item.diskonPersen > 0)
                Positioned(
                  top: 7,
                  left: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: pinkTua,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'PROMO ${item.diskonPersen}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // INFORMASI PRODUK
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF444444),
                    ),
                  ),

                  const SizedBox(height: 4),

                  _buildBadgeStok(item.stok),

                  const Spacer(),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatRupiah(item.hargaJual),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: pinkTua,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // TOMBOL EDIT
                      IconButton(
                        tooltip: 'Edit Produk',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: pinkTua,
                          size: 18,
                        ),
                        onPressed: () async {
                          final refresh = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FormProdukPage(produk: item),
                            ),
                          );

                          if (refresh == true && mounted) {
                            _muatDataProduk();
                          }
                        },
                      ),

                      // TOMBOL HAPUS
                      IconButton(
                        tooltip: 'Hapus Produk',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () {
                          _konfirmasiHapusProduk(context, item);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // NAVIGASI TAMBAH PRODUK
  // ==========================================

  Future<void> _tambahProduk() async {
    final refresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormProdukPage(),
      ),
    );

    if (refresh == true && mounted) {
      _muatDataProduk();
    }
  }

  // ==========================================
  // TAMPILAN UTAMA DASHBOARD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink,

      // APP BAR
      appBar: AppBar(
        backgroundColor: pinkUtama,
        elevation: 0,
        title: const Row(
          children: [
            Icon(
              Icons.point_of_sale,
              color: Colors.white,
              size: 25,
            ),
            SizedBox(width: 8),
            Text(
              'SmartKasir',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 19,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tambah Produk',
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.white,
            ),
            onPressed: _tambahProduk,
          ),
        ],
      ),

      body: Column(
        children: [
          // ==================================
          // 1. BANNER PENJUALAN
          // ==================================

          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF48FB1),
                  Color(0xFFF8BBD0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: pinkUtama.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Penjualan Hari Ini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Rp 845.000',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '34 Transaksi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==================================
          // 2. SEARCH BAR SQL LIKE
          // ==================================

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                _keywordPencarian = val;
                _muatDataProduk();
              },
              decoration: InputDecoration(
                hintText: 'Cari nama produk kasir ...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: pinkTua,
                ),
                suffixIcon: _keywordPencarian.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _keywordPencarian = '';
                          _muatDataProduk();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: pinkMuda,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: pinkMuda,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: pinkTua,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ==================================
          // 3. FILTER KATEGORI
          // ==================================

          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              itemCount: _kategoriList.length,
              itemBuilder: (context, index) {
                final isSelected =
                    _kategoriTerpilih == index;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_kategoriList[index]),
                    selected: isSelected,
                    selectedColor: pinkUtama,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: pinkMuda,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _kategoriTerpilih = index;
                          _searchController.clear();
                          _keywordPencarian = '';
                        });

                        _muatDataProduk();
                      }
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ==================================
          // 4. KATALOG FUTUREBUILDER SQLITE
          // ==================================

          Expanded(
            child: FutureBuilder<List<Produk>>(
              future: _produkFuture,
              builder: (context, snapshot) {
                // LOADING STATE
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: pinkTua,
                    ),
                  );
                }

                // ERROR STATE
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Terjadi kesalahan memuat database: '
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // EMPTY STATE
                final daftarProduk = snapshot.data ?? [];

                if (daftarProduk.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 60,
                          color: pinkUtama.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _keywordPencarian.isNotEmpty
                              ? 'Produk "$_keywordPencarian" tidak ditemukan.'
                              : 'Belum ada produk pada kategori ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // SUCCESS STATE
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    80,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 220,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: daftarProduk.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(
                      daftarProduk[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ==================================
      // 5. FLOATING ACTION BUTTON
      // ==================================

      floatingActionButton: FloatingActionButton(
        onPressed: _tambahProduk,
        backgroundColor: pinkTua,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
