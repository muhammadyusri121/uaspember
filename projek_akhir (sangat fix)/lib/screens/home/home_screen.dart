import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kulinerku/providers/auth_provider.dart';
import 'package:kulinerku/providers/kuliner_provider.dart';
import 'package:kulinerku/providers/network_provider.dart'; // Uncomment ini
import 'package:kulinerku/screens/kuliner/add_kuliner_screen.dart';
import 'package:kulinerku/screens/kuliner/kuliner_detail_screen.dart';
import 'package:kulinerku/screens/auth/login_screen.dart';
import 'package:kulinerku/widgets/kuliner_card.dart';
import 'package:kulinerku/widgets/network_banner.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Tambahkan import ini jika belum

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Periksa koneksi internet sebelum memuat data
      final networkProvider =
          Provider.of<NetworkProvider>(context, listen: false);
      _isOnline = networkProvider.isOnline;

      if (_isOnline) {
        Provider.of<KulinerProvider>(context, listen: false).fetchKuliners();
      }
    });
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KulinerKU'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // Tambahkan ikon status koneksi
          Consumer<NetworkProvider>(
            builder: (context, networkProvider, _) {
              IconData iconData;
              Color iconColor;
              String tooltip;

              if (networkProvider.connectionType == ConnectivityResult.wifi) {
                iconData = Icons.wifi;
                iconColor = Colors.green;
                tooltip = "Terhubung ke WiFi";
              } else if (networkProvider.connectionType ==
                  ConnectivityResult.mobile) {
                iconData = Icons.signal_cellular_4_bar;
                iconColor = Colors.blue;
                tooltip = "Menggunakan Data Seluler";
              } else {
                iconData = Icons.signal_cellular_off;
                iconColor = Colors.red;
                tooltip = "Tidak Ada Koneksi Internet";
              }

              return Tooltip(
                message: tooltip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(iconData, color: iconColor),
                ),
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle),
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'profile',
                    enabled: false,
                    child: Text('Hello, ${authProvider.user?.name ?? 'User'}'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
                onSelected: (String value) {
                  if (value == 'logout') {
                    _logout();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<NetworkProvider>(
        builder: (context, networkProvider, child) {
          // Tampilkan pesan error jika tidak ada koneksi internet
          if (!networkProvider.isOnline) {
            return Column(
              children: [
                const NetworkBanner(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.signal_wifi_off,
                          size: 80,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Internet Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please check your connection and try again',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _checkConnectivity();
                            if (_isOnline && mounted) {
                              Provider.of<KulinerProvider>(context,
                                      listen: false)
                                  .fetchKuliners();
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Tampilkan konten normal jika ada koneksi internet
          return Column(
            children: [
              const NetworkBanner(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search kuliner...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              Provider.of<KulinerProvider>(context,
                                      listen: false)
                                  .searchKuliners('');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    Provider.of<KulinerProvider>(context, listen: false)
                        .searchKuliners(value);
                  },
                ),
              ),
              Expanded(
                child: Consumer<KulinerProvider>(
                  builder: (context, kulinerProvider, child) {
                    if (kulinerProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (kulinerProvider.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${kulinerProvider.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                kulinerProvider.clearError();
                                kulinerProvider.fetchKuliners();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (kulinerProvider.kuliners.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              kulinerProvider.searchQuery.isEmpty
                                  ? 'No kuliner found.\nAdd your first kuliner!'
                                  : 'No kuliner found for "${kulinerProvider.searchQuery}"',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: kulinerProvider.fetchKuliners,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: kulinerProvider.kuliners.length,
                        itemBuilder: (context, index) {
                          final kuliner = kulinerProvider.kuliners[index];
                          return KulinerCard(
                            kuliner: kuliner,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      KulinerDetailScreen(kuliner: kuliner),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<NetworkProvider>(
        builder: (context, networkProvider, child) {
          // Nonaktifkan FAB jika tidak ada koneksi internet
          return FloatingActionButton(
            onPressed: networkProvider.isOnline
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const AddKulinerScreen()),
                    );
                  }
                : null,
            backgroundColor:
                networkProvider.isOnline ? Colors.orange : Colors.grey,
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: networkProvider.isOnline
                ? 'Add New Kuliner'
                : 'Internet connection required',
          );
        },
      ),
    );
  }
}
