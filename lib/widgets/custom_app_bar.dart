import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/theme_provider.dart';
import '../models/product.dart';
import '../screens/reports_screen.dart';
import '../screens/login_screen.dart';
import '../screens/admin_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.role == 'admin';
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final avatarUrl = authProvider.avatarUrl;
    final userName = authProvider.profile?['full_name'] ?? 'Usuário';

    final lowStockProducts = salesProvider.products
        .where((p) => p.stock <= p.lowStockThreshold)
        .toList();

    return AppBar(
      backgroundColor: Colors.teal.shade600,
      elevation: 4,
      title: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NextLynx Print',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                ),
                Text(
                  'Olá, $userName! Bem-vindo de volta!',
                  style: TextStyle(
                    color: Colors.yellow.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // AVATAR NO APPBAR
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => _showProfileDialog(context, authProvider),
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
          ),
        ),

        // NOTIFICAÇÃO ESTOQUE
        if (lowStockProducts.isNotEmpty)
          Stack(
            children: [
              Tooltip(
                message: 'Estoque baixo: ${lowStockProducts.map((p) => p.name).join(', ')}',
                child: IconButton(
                  icon: const Icon(Icons.notifications_active, color: Colors.white),
                  onPressed: () => _showStockDialog(context, lowStockProducts),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Center(
                    child: Text('${lowStockProducts.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          )
        else
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: null),

        // MENU 3 PONTINHOS
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            debugPrint('Menu selecionado: $value');
            switch (value) {
              case 'profile':
                _showProfileDialog(context, authProvider);
                break;
              case 'theme':
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                break;
              case 'reports':
                if (isAdmin) Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                break;
              case 'admin':
                if (isAdmin) Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                break;
              case 'logout':
                _logout(context, authProvider);
                break;
            }
          },
          itemBuilder: (context) {
            final items = [
              const PopupMenuItem(
                value: 'profile',
                child: Row(children: [Icon(Icons.person), SizedBox(width: 8), Text('Perfil')]),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Provider.of<ThemeProvider>(context).isDark ? Icons.light_mode : Icons.dark_mode),
                    const SizedBox(width: 8),
                    Text(Provider.of<ThemeProvider>(context).isDark ? 'Tema Claro' : 'Tema Escuro'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text('Sair')]),
              ),
            ];

            if (isAdmin) {
              items.insert(0, const PopupMenuItem(value: 'reports', child: Row(children: [Icon(Icons.bar_chart), SizedBox(width: 8), Text('Relatórios')])));
              items.insert(1, const PopupMenuItem(value: 'admin', child: Row(children: [Icon(Icons.admin_panel_settings), SizedBox(width: 8), Text('Painel Admin')])));
            }

            return items;
          },
        ),
      ],
    );
  }

  void _showStockDialog(BuildContext context, List<Product> products) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Estoque Baixo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: products.length,
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: Text(products[i].name),
              subtitle: Text('Estoque: ${products[i].stock}'),
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _logout(BuildContext context, AuthProvider authProvider) async {
    await Supabase.instance.client.auth.signOut();
    authProvider.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showProfileDialog(BuildContext context, AuthProvider authProvider) async {
    final user = authProvider.user;
    if (user == null) return;

    final profileResponse = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    final profile = profileResponse;
    final picker = ImagePicker();
    XFile? pickedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Text('Perfil do Usuário'),
              if (isUploading) ...[
                const SizedBox(width: 10),
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: !isUploading
                      ? () async {
                          setStateDialog(() => isUploading = true);
                          final image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            setStateDialog(() => pickedImage = image);
                            final url = await authProvider.uploadAvatarToSupabase(image);
                            if (url != null) {
                              setStateDialog(() => isUploading = false);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto atualizada!')));
                            } else {
                              setStateDialog(() => isUploading = false);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao enviar foto')));
                            }
                          } else {
                            setStateDialog(() => isUploading = false);
                          }
                        }
                      : null,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        child: pickedImage != null
                            ? FutureBuilder<Uint8List>(
                                future: kIsWeb ? pickedImage!.readAsBytes() : File(pickedImage!.path).readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return CircleAvatar(
                                      radius: 50,
                                      backgroundImage: MemoryImage(snapshot.data!),
                                    );
                                  }
                                  return const CircularProgressIndicator();
                                },
                              )
                            : (authProvider.avatarUrl != null
                                ? CircleAvatar(
                                    radius: 50,
                                    backgroundImage: NetworkImage(authProvider.avatarUrl!),
                                  )
                                : const CircleAvatar(
                                    radius: 50,
                                    backgroundImage: AssetImage('assets/images/default_avatar.png'),
                                  )),
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isUploading ? Colors.grey : Colors.teal,
                        child: isUploading
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow('Email', user.email ?? 'N/A'),
                _infoRow('Nome', profile['full_name'] ?? 'N/A'),
                _infoRow('Morada', profile['address'] ?? 'N/A'),
                _infoRow('Telefone', profile['phone'] ?? 'N/A'),
                _infoRow('Idade', profile['age']?.toString() ?? 'N/A'),
                _infoRow('Função', profile['role']?.toUpperCase() ?? 'N/A'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(child: Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }
}