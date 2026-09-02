import 'dart:async';

import 'package:flutter/material.dart';

// Dados para o carrossel de ações realizadas
final List<Map<String, String>> galleryItems = [
  {
    "image": "https://plus.unsplash.com/premium_photo-1681152783648-29c9c15b56ed?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    "title": "Mutirão de Revitalização",
    "local": "📍 Mauá",
  },
  {
    "image": "https://images.unsplash.com/photo-1599059813005-11265ba4b4ce?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    "title": "Arrecadação de Alimentos",
    "local": "📍 Santo André",
  },
  {
    "image": "https://images.unsplash.com/photo-1526976668912-1a811878dd37?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    "title": "Apoio Escolar Comunitário",
    "local": "📍 São Bernardo do Campo",
  },
  {
    "image": "https://images.unsplash.com/photo-1559027615-cd4628902d4a?q=80&w=1174&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    "title": "Feira de Adoção Pet",
    "local": "📍 São Caetano do Sul",
  },
  {
    "image": "https://plus.unsplash.com/premium_photo-1661775317533-2163ba4dbc93?q=80&w=1174&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    "title": "Pintura da Casa de Apoio aos Imigrantes",
    "local": "📍 Mauá",
  },
  {
    "image": "https://images.unsplash.com/photo-1565803974275-dccd2f933cbb?q=80&w=1171&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    "title": "Limpeza da Prainha da Represa Billings",
    "local": "📍 São Bernardo do Campo",
  },
];

class ImpactGallerySection extends StatefulWidget {
  const ImpactGallerySection({super.key});

  @override
  State<ImpactGallerySection> createState() => _ImpactGallerySectionState();
}

class _ImpactGallerySectionState extends State<ImpactGallerySection> {
  int currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Configura o cronômetro para mudar os dados a cada 4 segundos
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      setState(() {
        currentIndex = (currentIndex + 1) % galleryItems.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Limpa o cronômetro se a pessoa sair da página
    super.dispose();
  }

  // Molde visual de um card individual
  Widget _buildCard(Map<String, String> item, double width) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500), // Suavidade na troca
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      // Usamos uma Key diferente baseada no título para o Flutter saber que a imagem mudou e rodar a animação
      child: Container(
        key: ValueKey<String>(item["title"]!),
        width: width,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(item["image"]!, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF062222).withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3DCFB0).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item["local"]!,
                        style: const TextStyle(
                          color: Color(0xFF062222),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item["title"]!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // Lógica Matemática: Define quem são as 3 imagens atuais da "roleta"
    final item1 = galleryItems[currentIndex];
    final item2 = galleryItems[(currentIndex + 1) % galleryItems.length];
    final item3 = galleryItems[(currentIndex + 2) % galleryItems.length];

    return Container(
      width: double.infinity,
      color: const Color(0xFFF0FAF7),
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Impacto Real",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF062222),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Veja um pouco do que nossa rede já transformou no ABC",
                      style: TextStyle(
                        color: Color(0xFF3A6868),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Se for Computador: Mostra os 3 cards lado a lado.
              // Se for Celular: Mostra só 1 card que ocupa a tela toda.
              isDesktop
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCard(item1, 350),
                        _buildCard(item2, 350),
                        _buildCard(item3, 350),
                      ],
                    )
                  : Center(child: _buildCard(item1, double.infinity)),
            ],
          ),
        ),
      ),
    );
  }
}
