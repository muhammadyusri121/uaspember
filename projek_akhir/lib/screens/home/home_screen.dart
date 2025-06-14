import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kulinerku/providers/auth_provider.dart';
import 'package:kulinerku/providers/kuliner_provider.dart';
// import 'package:kulinerku/providers/network_provider.dart';
import 'package:kulinerku/screens/kuliner/add_kuliner_screen.dart';
import 'package:kulinerku/screens/kuliner/kuliner_detail_screen.dart';
import 'package:kulinerku/screens/auth/login_screen.dart';
import 'package:kulinerku/widgets/kuliner_card.dart';
import 'package:kulinerku/widgets/network_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KulinerProvider>(context, listen: false).fetchKuliners();
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
      body: Column(
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
                    Provider.of<KulinerProvider>(context, listen: false)
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
                        const Icon(Icons.error, size: 64, color: Colors.red),
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
                        Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
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
                              builder: (context) => KulinerDetailScreen(kuliner: kuliner),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddKulinerScreen()),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
