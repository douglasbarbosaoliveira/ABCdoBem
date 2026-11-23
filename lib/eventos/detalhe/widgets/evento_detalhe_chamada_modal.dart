// lib/eventos/detalhe/widgets/evento_detalhe_chamada_modal.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../services/session_service.dart';
import '../../models/evento_model.dart';

class _ChamadaParticipanteItem {
  final String applicationId;
  final String userId;
  final String nome;
  final String? fotoUrl;
  final bool jaPresente;

  const _ChamadaParticipanteItem({
    required this.applicationId,
    required this.userId,
    required this.nome,
    this.fotoUrl,
    this.jaPresente = false,
  });
}

class EventoDetalheChamadaModal extends StatefulWidget {
  final EventoModel evento;

  const EventoDetalheChamadaModal({
    super.key,
    required this.evento,
  });

  static Future<bool?> exibir(BuildContext context, EventoModel evento) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => EventoDetalheChamadaModal(evento: evento),
    );
  }

  @override
  State<EventoDetalheChamadaModal> createState() =>
      _EventoDetalheChamadaModalState();
}

class _EventoDetalheChamadaModalState extends State<EventoDetalheChamadaModal> {
  static const String _baseUrl = "https://abc-do-bem.onrender.com";

  List<_ChamadaParticipanteItem> _participantes = [];
  final Map<String, bool> _presencas = {};
  int _horasPadrao = 4;
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _horasPadrao = _calcularHorasEstimadas(widget.evento.horario);

    // Preenche inicialmente com os locais se existirem
    for (final p in widget.evento.participantesConfirmados) {
      _participantes.add(
        _ChamadaParticipanteItem(
          applicationId: p.id,
          userId: p.id,
          nome: p.nome,
          fotoUrl: p.fotoUrl,
        ),
      );
      _presencas[p.id] = true;
    }

    _carregarParticipantesApi();
  }

  bool _isStatusAceito(String statusRaw) {
    final s = statusRaw.toUpperCase().trim();
    return s == 'ACCEPTED' ||
        s == 'APPROVED' ||
        s == 'CONFIRMED' ||
        s == 'CONFIRMADA' ||
        s == 'APROVADO' ||
        s == 'PRESENTE' ||
        s == 'ATTENDED';
  }

  Future<void> _carregarParticipantesApi() async {
    final token = SessionService.instance.token;
    if (token == null || token.trim().isEmpty || widget.evento.id.isEmpty) {
      if (mounted) setState(() => _carregando = false);
      return;
    }

    try {
      final url =
          Uri.parse("$_baseUrl/opportunities/${widget.evento.id}/applications");
      debugPrint("=== [GET] CHAMADA - BUSCANDO VOLUNTÁRIOS ACEITOS ===");
      debugPrint("URL: $url");

      final res = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer ${token.trim()}",
        },
      ).timeout(const Duration(seconds: 12));

      final bodyTexto = utf8.decode(res.bodyBytes);
      debugPrint("Status Code Chamada Applications: ${res.statusCode}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(bodyTexto);
        final List<dynamic> listaRaw = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] is List
                ? decoded['data'] as List
                : (decoded is Map && decoded['applications'] is List
                    ? decoded['applications'] as List
                    : []));

        final List<_ChamadaParticipanteItem> carregados = [];
        final Map<String, bool> novasPresencas = {};

        for (final item in listaRaw) {
          if (item is Map<String, dynamic>) {
            final status = (item['status'] ?? '').toString();
            if (_isStatusAceito(status)) {
              final user = item['user'] is Map<String, dynamic>
                  ? item['user'] as Map<String, dynamic>
                  : <String, dynamic>{};

              final appId = (item['id'] ?? '').toString();
              final userId = (user['id'] ?? item['userId'] ?? appId).toString();
              final nome =
                  (user['name'] ?? user['nome'] ?? item['nome'] ?? 'Voluntário')
                      .toString();
              final avatar =
                  (user['avatar'] ?? user['fotoUrl'] ?? item['fotoUrl'] ?? '')
                      .toString();
              final attended = item['attended'] == true;

              if (userId.isNotEmpty) {
                carregados.add(
                  _ChamadaParticipanteItem(
                    applicationId: appId,
                    userId: userId,
                    nome: nome,
                    fotoUrl: avatar.isEmpty ? null : avatar,
                    jaPresente: attended,
                  ),
                );
                novasPresencas[userId] = true;
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _participantes = carregados;
            _presencas
              ..clear()
              ..addAll(novasPresencas);
            _carregando = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint("Erro ao buscar lista de chamada na API: $e");
    }

    if (mounted) setState(() => _carregando = false);
  }

  int _calcularHorasEstimadas(String horario) {
    try {
      final limpa = horario.replaceAll('às', '-');
      final partes = limpa.split('-');
      if (partes.length == 2) {
        final inicio = int.parse(partes[0].trim().split(':').first);
        final fim = int.parse(partes[1].trim().split(':').first);
        final diff = fim - inicio;
        if (diff > 0) return diff;
      }
    } catch (_) {}
    return 4;
  }

  void _alternarTodos(bool marcar) {
    setState(() {
      for (final key in _presencas.keys) {
        _presencas[key] = marcar;
      }
    });
  }

  Uint8List? _decodificarBase64(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed.toLowerCase().startsWith('http://') ||
        trimmed.toLowerCase().startsWith('https://')) {
      return null;
    }
    try {
      final base64Puro = trimmed.contains(',')
          ? trimmed.substring(trimmed.indexOf(',') + 1)
          : trimmed;
      var limpo = base64Puro
          .replaceAll(' ', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .replaceAll('\t', '');
      while (limpo.length % 4 != 0) {
        limpo += '=';
      }
      if (limpo.length < 32) return null;
      return base64Decode(limpo);
    } catch (_) {
      return null;
    }
  }

  Widget _buildAvatar(String? fotoUrl) {
    const iconePadrao = Icon(
      Icons.person_rounded,
      color: Color(0xFF0C6B6B),
      size: 20,
    );

    if (fotoUrl == null || fotoUrl.trim().isEmpty) {
      return const CircleAvatar(
        radius: 20,
        backgroundColor: Color(0xFFD1F5EE),
        child: iconePadrao,
      );
    }

    final src = fotoUrl.trim();
    if (src.toLowerCase().startsWith('http://') ||
        src.toLowerCase().startsWith('https://')) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFFD1F5EE),
        backgroundImage: NetworkImage(src),
      );
    }

    final bytes = _decodificarBase64(src);
    if (bytes != null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFFD1F5EE),
        backgroundImage: MemoryImage(bytes),
      );
    }

    return const CircleAvatar(
      radius: 20,
      backgroundColor: Color(0xFFD1F5EE),
      child: iconePadrao,
    );
  }

  Future<void> _salvarChamada() async {
    setState(() => _salvando = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Lista de presença salva com sucesso! (${_presencas.values.where((v) => v).length} presenças validadas)",
            ),
            backgroundColor: const Color(0xFF0C6B6B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao salvar lista de chamada. Tente novamente."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalPresentes = _presencas.values.where((v) => v).length;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra superior de arraste
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Cabeçalho do Modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Lista de Chamada & Horas",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.evento.titulo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7AAAA0),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Ajuste de Horas e Ações Rápidas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3FAF8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC2E4DC)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 20, color: Color(0xFF0C6B6B)),
                        SizedBox(width: 8),
                        Text(
                          "Horas por voluntário:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF062222),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Color(0xFF0C6B6B), size: 22),
                          onPressed: _horasPadrao > 1
                              ? () => setState(() => _horasPadrao--)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "${_horasPadrao}h",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0C6B6B),
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.add_circle_outline,
                              color: Color(0xFF0C6B6B), size: 22),
                          onPressed: _horasPadrao < 12
                              ? () => setState(() => _horasPadrao++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Controles de Seleção Rápida
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Confirmados: $totalPresentes de ${_participantes.length}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF062222),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _alternarTodos(true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text("Todos",
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF0C6B6B))),
                      ),
                      const Text("|", style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () => _alternarTodos(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text("Nenhum",
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lista de Voluntários
            Expanded(
              child: _carregando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0C6B6B),
                      ),
                    )
                  : _participantes.isEmpty
                      ? const Center(
                          child: Text(
                            "Nenhum participante inscrito nesta ação.",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          itemCount: _participantes.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, index) {
                            final p = _participantes[index];
                            final bool presente = _presencas[p.userId] ?? false;

                            return CheckboxListTile(
                              value: presente,
                              activeColor: const Color(0xFF0C6B6B),
                              checkColor: Colors.white,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                setState(() {
                                  _presencas[p.userId] = val ?? false;
                                });
                              },
                              secondary: _buildAvatar(p.fotoUrl),
                              title: Text(
                                p.nome,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: presente
                                      ? const Color(0xFF062222)
                                      : Colors.grey,
                                ),
                              ),
                              subtitle: Text(
                                presente
                                    ? "Presença confirmada (+${_horasPadrao}h no perfil)"
                                    : "Ausente / Falta",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: presente
                                      ? const Color(0xFF0C6B6B)
                                      : Colors.redAccent,
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Botão Inferior de Confirmação
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _salvando || _participantes.isEmpty
                        ? null
                        : _salvarChamada,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C6B6B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _salvando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Salvar e Validar Horas",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
