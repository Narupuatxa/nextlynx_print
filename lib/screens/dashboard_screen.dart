import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/auth_provider.dart';
import 'services_screen.dart';
import 'sales_screen.dart';
import 'expenses_screen.dart';
import 'reports_screen.dart';
import 'admin_screen.dart';
import 'customers_screen.dart';

// CONFIGURAÇÃO DOS CARDS
class _CardConfig {
  final IconData icon;
  final Color borderColor;
  final String imagePath;

  const _CardConfig({
    required this.icon,
    required this.borderColor,
    required this.imagePath,
  });
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const Map<String, _CardConfig> _cardConfigs = {
    'Serviços': _CardConfig(
      icon: Icons.print,
      borderColor: Colors.teal,
      imagePath: 'assets/images/dashboard/services.jpg',
    ),
    'Vendas': _CardConfig(
      icon: Icons.shopping_cart,
      borderColor: Colors.green,
      imagePath: 'assets/images/dashboard/sales.png',
    ),
    'Despesas': _CardConfig(
      icon: Icons.money_off,
      borderColor: Colors.orange,
      imagePath: 'assets/images/dashboard/expenses.jpg',
    ),
    'Clientes': _CardConfig(
      icon: Icons.people,
      borderColor: Colors.blue,
      imagePath: 'assets/images/dashboard/customers.jpg',
    ),
    'Relatórios': _CardConfig(
      icon: Icons.bar_chart,
      borderColor: Colors.purple,
      imagePath: 'assets/images/dashboard/reports.jpg',
    ),
    'Admin': _CardConfig(
      icon: Icons.admin_panel_settings,
      borderColor: Colors.red,
      imagePath: 'assets/images/dashboard/admin.jpg',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.role == 'admin';

    // RESPONSIVIDADE: DEFINE COLUNAS E ESPAÇAMENTO
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600
        ? 1
        : screenWidth < 900
            ? 2
            : screenWidth < 1200
                ? 3
                : 4;

    final childAspectRatio = screenWidth < 600
        ? 2.0
        : screenWidth < 900
            ? 1.5
            : 1.1;

    final padding = screenWidth < 600 ? 12.0 : 16.0;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenWidth < 600 ? 8 : 16),

              // GRID RESPONSIVO
              Expanded(
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: padding,
                  mainAxisSpacing: padding,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _buildAnimatedCard(context, 'Serviços', const ServicesScreen()),
                    _buildAnimatedCard(context, 'Vendas', const SalesScreen()),
                    _buildAnimatedCard(context, 'Despesas', const ExpensesScreen()),
                    _buildAnimatedCard(context, 'Clientes', const CustomersScreen()),
                    if (isAdmin) _buildAnimatedCard(context, 'Relatórios', const ReportsScreen()),
                    if (isAdmin) _buildAnimatedCard(context, 'Admin', const AdminScreen()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(BuildContext context, String title, Widget screen) {
    final config = _cardConfigs[title]!;

    return AnimatedCard(
      title: title,
      icon: config.icon,
      borderColor: config.borderColor,
      imagePath: config.imagePath,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
    );
  }
}

// WIDGET DE CARD COM ANIMAÇÃO (TEXTO CENTRALIZADO E VISÍVEL)
class AnimatedCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color borderColor;
  final String imagePath;
  final VoidCallback onTap;

  const AnimatedCard({
    super.key,
    required this.title,
    required this.icon,
    required this.borderColor,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 8.0, end: 20.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Card(
                elevation: _elevationAnimation.value,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: widget.borderColor, width: 3),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Image.asset(
                        widget.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.broken_image, size: 60, color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(12), // REDUZIDO
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: widget.borderColor, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icon,
                                size: 32, // REDUZIDO
                                color: widget.borderColor,
                              ),
                            ),
                            const SizedBox(height: 6), // REDUZIDO
                            // TEXTO CENTRALIZADO E NUNCA CORTADO
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: widget.borderColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}