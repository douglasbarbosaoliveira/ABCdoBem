// lib/widgets/impact_gallery_section.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../ongs/services/ong_painel_service.dart';
import '../utils/responsive.dart';

class _EventoGaleriaItem {
  final String id;
  final String image;
  final String title;
  final String local;

  const _EventoGaleriaItem({
    required this.id,
    required this.image,
    required this.title,
    required this.local,
  });
}

// Fallback de exibição (mínimo de 3 eventos) caso a API não retorne itens
const List<_EventoGaleriaItem> _fallbackGalleryItems = <_EventoGaleriaItem>[
  _EventoGaleriaItem(
    id: 'fallback-1',
    image:
        'https://plus.unsplash.com/premium_photo-1681152783648-29c9c15b56ed?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    title: 'Mutirão de Revitalização',
    local: '📍 Mauá',
  ),
  _EventoGaleriaItem(
    id: 'fallback-2',
    image:
        'https://images.unsplash.com/photo-1599059813005-11265ba4b4ce?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    title: 'Arrecadação de Alimentos',
    local: '📍 Santo André',
  ),
  _EventoGaleriaItem(
    id: 'fallback-3',
    image:
        'https://images.unsplash.com/photo-1526976668912-1a811878dd37?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    title: 'Apoio Escolar Comunitário',
    local: '📍 São Bernardo do Campo',
  ),
];

class ImpactGallerySection extends StatefulWidget {
  const ImpactGallerySection({super.key});

  @override
  State<ImpactGallerySection> createState() => _ImpactGallerySectionState();
}

class _ImpactGallerySectionState extends State<ImpactGallerySection> {
  static const String _baseUrl = 'https://abc-do-bem.onrender.com';

  final Random _random = Random();
  List<_EventoGaleriaItem> _eventosExibidos =
      List<_EventoGaleriaItem>.from(_fallbackGalleryItems);
  int currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _eventosExibidos.shuffle(_random);
    _carregarEventosComFallback();

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _eventosExibidos.isNotEmpty) {
        setState(() {
          currentIndex = (currentIndex + 1) % _eventosExibidos.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregarEventosComFallback() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/opportunities'),
        headers: const <String, String>{'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final listaRaw = JsonParsers.extractList(
          jsonDecode(utf8.decode(res.bodyBytes)),
          ['opportunities', 'acoes', 'events', 'items'],
        );

        final parsed = <_EventoGaleriaItem>[];
        for (final raw in listaRaw) {
          if (raw is! JsonMap) continue;
          final id = (raw['id'] ?? '').toString().trim();
          final titulo =
              (raw['title'] ?? raw['titulo'] ?? '').toString().trim();
          final imagem = (raw['imageUrl'] ??
                  raw['imagemUrl'] ??
                  raw['image'] ??
                  raw['fotoUrl'] ??
                  '')
              .toString()
              .trim();
          final cidade = (raw['cidade'] ??
                  raw['city'] ??
                  raw['location'] ??
                  raw['ong']?['cidade'] ??
                  '')
              .toString()
              .trim();

          if (titulo.isEmpty && imagem.isEmpty) continue;
          parsed.add(
            _EventoGaleriaItem(
              id: id.isNotEmpty ? id : titulo,
              image: imagem,
              title: titulo.isNotEmpty ? titulo : 'Ação Comunitária',
              local: cidade.isNotEmpty ? "📍 $cidade" : "📍 Grande ABC",
            ),
          );
        }

        if (parsed.isNotEmpty) {
          parsed.shuffle(_random);
          // Garante ao menos 3 itens no carrossel completando com fallback se a API tiver poucos
          final listaFinal = <_EventoGaleriaItem>[...parsed];
          if (listaFinal.length < 3) {
            final extras = List<_EventoGaleriaItem>.from(_fallbackGalleryItems)
              ..shuffle(_random);
            for (final fb in extras) {
              if (listaFinal.length >= 3) break;
              if (!listaFinal.any((e) => e.title == fb.title)) {
                listaFinal.add(fb);
              }
            }
          }

          if (!mounted) return;
          setState(() {
            _eventosExibidos = listaFinal;
            currentIndex = 0;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      final fallbackEmbaralhado =
          List<_EventoGaleriaItem>.from(_fallbackGalleryItems)
            ..shuffle(_random);
      setState(() {
        _eventosExibidos = fallbackEmbaralhado;
        currentIndex = 0;
      });
    }
  }

  Widget _buildCard(_EventoGaleriaItem item, {double? width}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey<String>("${item.id}_$currentIndex"),
        width: width,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
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
              if (item.image.isNotEmpty)
                Image.network(
                  item.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFC7EBE3),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: Color(0xFF0C6B6B),
                      size: 40,
                    ),
                  ),
                )
              else
                Container(
                  color: const Color(0xFFC7EBE3),
                  child: const Center(
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      color: Color(0xFF0C6B6B),
                      size: 44,
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF062222).withOpacity(0.85),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3DCFB0).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.local,
                        style: const TextStyle(
                          color: Color(0xFF062222),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);

    final total = _eventosExibidos.length;
    final item1 = _eventosExibidos[currentIndex % total];
    final item2 = _eventosExibidos[(currentIndex + 1) % total];
    final item3 = _eventosExibidos[(currentIndex + 2) % total];

    return Container(
      width: double.infinity,
      color: const Color(0xFFF0FAF7),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 64,
        horizontal: isMobile ? 16 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Impacto Real",
                style: TextStyle(
                  fontSize: isMobile ? 26 : 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF062222),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Veja um pouco do que nossa rede já transformou no ABC",
                style: TextStyle(
                  color: const Color(0xFF3A6868),
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 14 : 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 32 : 48),

              // Layout adaptativo: Row com Expanded no desktop, card único no mobile
              if (isDesktop)
                Row(
                  children: [
                    Expanded(child: _buildCard(item1)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildCard(item2)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildCard(item3)),
                  ],
                )
              else
                _buildCard(item1, width: double.infinity),

              const SizedBox(height: 24),

              // Indicadores de paginação (Dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(total, (index) {
                  final bool isActive = currentIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: isActive ? 24 : 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF0C6B6B)
                          : const Color(0xFFC2E4DC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
