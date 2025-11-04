import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/services_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import 'service_detail_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Estampagem Personalizada',
      'image': 'assets/images/estampagem.png',
      'category': 'estampagem'
    },
    {
      'name': 'Design Gráfico',
      'image': 'assets/images/design_grafico.jpg',
      'category': 'design_grafico'
    },
    {
      'name': 'Reprografia',
      'image': 'assets/images/reprografia.jpg',
      'category': 'reprografia'
    },
  ];

  @override
  void initState() {
    super.initState();
    final servicesProvider = Provider.of<ServicesProvider>(context, listen: false);
    servicesProvider.init().catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar serviços: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.role == 'admin';

    // RESPONSIVIDADE: AJUSTA GRID POR TELA
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600
        ? 1
        : screenWidth < 900
            ? 2
            : 3;

    final childAspectRatio = screenWidth < 600
        ? 1.8
        : screenWidth < 900
            ? 1.0
            : 0.8;

    final padding = screenWidth < 600 ? 12.0 : 16.0;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Text(
                'Categorias de Serviços',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth < 600 ? 20 : 24,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: padding,
                mainAxisSpacing: padding,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = _categories[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailScreen(
                                category: cat['category'],
                                categoryName: cat['name'],
                                image: cat['image'],
                                isAdmin: isAdmin,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.teal.shade400, Colors.teal.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    cat['image'],
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.image_not_supported,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      cat['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _categories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}