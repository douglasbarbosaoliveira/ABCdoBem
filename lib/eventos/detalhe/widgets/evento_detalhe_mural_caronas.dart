// lib/eventos/detalhe/widgets/evento_detalhe_mural_caronas.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../services/session_service.dart';
import '../../models/evento_model.dart';

class _ItemCarona {
  final String autor;
  final String tipo;
  final bool isOferta;
  final String partida;
  final String cidade;
  final String whatsapp;

  const _ItemCarona({
    required this.autor,
    required this.tipo,
    required this.isOferta,
    required this.partida,
    required this.cidade,
    required this.whatsapp,
  });
}

class EventoDetalheMuralCaronas extends StatefulWidget {
  final EventoModel evento;
  final String usuarioAtualId;
  final bool isDono;

  const EventoDetalheMuralCaronas({
    super.key,
    required this.evento,
    required this.usuarioAtualId,
    required this.isDono,
  });

  @override
  State<EventoDetalheMuralCaronas> createState() =>
      _EventoDetalheMuralCaronasState();
}

class _EventoDetalheMuralCaronasState extends State<EventoDetalheMuralCaronas> {
  static const String _baseUrl = "https://abc-do-bem.onrender.com";

  final List<_ItemCarona> _caronas = <_ItemCarona>[];
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregarCaronasDaApi();
  }

  @override
  void didUpdateWidget(covariant EventoDetalheMuralCaronas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evento.id != widget.evento.id) {
      _carregarCaronasDaApi();
    }
  }

  Future<void> _carregarCaronasDaApi() async {
    final token = SessionService.instance.token;
    if (token == null || token.trim().isEmpty || widget.evento.id.isEmpty) {
      return;
    }

    if (mounted) setState(() => _carregando = true);

    try {
      final url =
          Uri.parse("$_baseUrl/opportunities/${widget.evento.id}/applications");
      final res = await http.get(
        url,
        headers: <String, String>{
          "Accept": "application/json",
          "Authorization": "Bearer ${token.trim()}",
        },
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> listaRaw = decoded is List
            ? decoded
            : (decoded is Map && decoded['applications'] is List
                ? decoded['applications'] as List<dynamic>
                : <dynamic>[]);

        final List<_ItemCarona> carregadas = <_ItemCarona>[];
        for (final dynamic item in listaRaw) {
          if (item is Map<String, dynamic>) {
            final status =
                (item['status'] ?? '').toString().toUpperCase().trim();
            if (status == 'REJECTED' || status == 'CANCELLED') continue;

            final tipo =
                (item['tipoCarona'] ?? '').toString().toUpperCase().trim();
            final detalhes = (item['detalhesCarona'] ?? '').toString().trim();

            if (tipo == 'OFERECE_CARONA' || tipo == 'PRECISA_CARONA') {
              final user = item['user'] is Map<String, dynamic>
                  ? item['user'] as Map<String, dynamic>
                  : <String, dynamic>{};

              final userId = (user['id'] ?? item['userId'] ?? '').toString();
              final nomeBruto =
                  (user['name'] ?? user['nome'] ?? 'Voluntário').toString();
              final isEu = userId.isNotEmpty && userId == widget.usuarioAtualId;
              final autor = isEu ? "Você ($nomeBruto)" : nomeBruto;
              final cidade = (user['cidade'] ?? '').toString().trim();

              final isOferta = tipo == 'OFERECE_CARONA';
              final tituloCarona = detalhes.isNotEmpty
                  ? detalhes
                  : (isOferta
                      ? "Oferecendo carona solidária${cidade.isNotEmpty ? ' saindo de $cidade' : ''}"
                      : "Precisando de carona${cidade.isNotEmpty ? ' em $cidade' : ''}");

              carregadas.add(
                _ItemCarona(
                  autor: autor,
                  tipo: isOferta ? "Oferece carona" : "Precisa de carona",
                  isOferta: isOferta,
                  partida: tituloCarona,
                  cidade: cidade.isNotEmpty ? cidade : "Grande ABC",
                  whatsapp:
                      (user['whatsapp'] ?? user['telefone'] ?? '').toString(),
                ),
              );
            }
          }
        }

        if (mounted) {
          setState(() {
            _caronas
              ..clear()
              ..addAll(carregadas);
            _carregando = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint("Erro ao carregar caronas da API: $e");
    }

    if (mounted) setState(() => _carregando = false);
  }

  void _abrirDialogOferecerCarona() {
    final pontoCtrl = TextEditingController();
    String tipoSelecionado = "OFERECE_CARONA";

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text(
            "Mural de Carona Solidária",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: "OFERECE_CARONA",
                    label: Text("Ofereço", style: TextStyle(fontSize: 12)),
                    icon: Icon(Icons.directions_car_rounded, size: 16),
                  ),
                  ButtonSegment<String>(
                    value: "PRECISA_CARONA",
                    label: Text("Preciso", style: TextStyle(fontSize: 12)),
                    icon: Icon(Icons.hail_rounded, size: 16),
                  ),
                ],
                selected: <String>{tipoSelecionado},
                onSelectionChanged: (sel) {
                  setDialogState(() => tipoSelecionado = sel.first);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pontoCtrl,
                decoration: InputDecoration(
                  labelText: tipoSelecionado == "OFERECE_CARONA"
                      ? "De onde você vai sair e quantas vagas?"
                      : "Onde você está e precisa de carona?",
                  hintText: "Ex: Estação Santo André - 2 vagas às 08:15",
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                if (pontoCtrl.text.trim().isNotEmpty) {
                  final isOferta = tipoSelecionado == "OFERECE_CARONA";
                  setState(() {
                    _caronas.insert(
                      0,
                      _ItemCarona(
                        autor: "Você",
                        tipo: isOferta ? "Oferece carona" : "Precisa de carona",
                        isOferta: isOferta,
                        partida: pontoCtrl.text.trim(),
                        cidade: SessionService.instance.cidade ?? "Grande ABC",
                        whatsapp: "",
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C6B6B),
              ),
              child: const Text(
                "Publicar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_car_filled_rounded,
                      color: Color(0xFF0C6B6B), size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Mural de Caronas do ABC",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF062222),
                    ),
                  ),
                ],
              ),
              if (!widget.isDono)
                TextButton.icon(
                  onPressed: _abrirDialogOferecerCarona,
                  icon: const Icon(Icons.add, size: 14),
                  label:
                      const Text("Participar", style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0C6B6B),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.isDono
                ? "Voluntários inscritos que oferecem ou solicitaram carona para esta ação:"
                : "Combine transporte solidário com outros voluntários da região:",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          if (_carregando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0C6B6B),
                  ),
                ),
              ),
            )
          else if (_caronas.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.isDono
                    ? "Nenhuma solicitação ou oferta de carona registrada pelos voluntários até o momento."
                    : "Nenhuma carona publicada ainda. Seja o primeiro a oferecer ou pedir carona!",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7AAAA0),
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._caronas.map((c) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FAF7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: c.isOferta
                          ? const Color(0xFFD1F5EE)
                          : const Color(0xFFFFF3E0),
                      child: Icon(
                        c.isOferta
                            ? Icons.directions_car_rounded
                            : Icons.hail_rounded,
                        size: 16,
                        color: c.isOferta
                            ? const Color(0xFF0C6B6B)
                            : const Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: c.isOferta
                                      ? const Color(0xFFE3F5F1)
                                      : const Color(0xFFFFE0B2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  c.tipo,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: c.isOferta
                                        ? const Color(0xFF0C6B6B)
                                        : const Color(0xFFE65100),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "${c.autor} • ${c.cidade}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            c.partida,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF062222),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (c.whatsapp.isNotEmpty)
                      IconButton(
                        tooltip: "Contato: ${c.whatsapp}",
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: Color(0xFF0C6B6B),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "WhatsApp de ${c.autor}: ${c.whatsapp}",
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
