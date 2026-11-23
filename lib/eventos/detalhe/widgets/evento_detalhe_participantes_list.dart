// lib/eventos/detalhe/widgets/evento_detalhe_participantes_list.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../services/session_service.dart';
import '../../models/evento_model.dart';
import '../../../voluntarios/perfil/voluntario_perfil_page.dart';

class _ParticipanteItem {
  final String id;
  final String nome;
  final String? fotoUrl;

  const _ParticipanteItem({
    required this.id,
    required this.nome,
    this.fotoUrl,
  });
}

class EventoDetalheParticipantesList extends StatefulWidget {
  final EventoModel evento;
  final bool isDono;
  final bool isEventoPassado;
  final String? usuarioLogadoId;

  const EventoDetalheParticipantesList({
    super.key,
    required this.evento,
    required this.isDono,
    this.isEventoPassado = false,
    this.usuarioLogadoId,
  });

  @override
  State<EventoDetalheParticipantesList> createState() =>
      _EventoDetalheParticipantesListState();
}

class _EventoDetalheParticipantesListState
    extends State<EventoDetalheParticipantesList> {
  static const String _baseUrl = "https://abc-do-bem.onrender.com";

  late List<_ParticipanteItem> _participantes;
  bool _carregandoApi = false;

  @override
  void initState() {
    super.initState();
    _participantes = _mapearParticipantesLocais();
    _buscarConfirmadosNaApi();
  }

  @override
  void didUpdateWidget(covariant EventoDetalheParticipantesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evento.id != widget.evento.id ||
        oldWidget.evento.isInscrito != widget.evento.isInscrito ||
        oldWidget.evento.statusInscricao != widget.evento.statusInscricao ||
        oldWidget.evento.participantesConfirmados.length !=
            widget.evento.participantesConfirmados.length) {
      _participantes = _mapearParticipantesLocais();
      _buscarConfirmadosNaApi();
    }
  }

  String _resolverMeuId() {
    if (widget.usuarioLogadoId != null &&
        widget.usuarioLogadoId!.trim().isNotEmpty &&
        widget.usuarioLogadoId != 'voluntario-1') {
      return widget.usuarioLogadoId!.trim();
    }
    if (SessionService.instance.usuarioId != null &&
        SessionService.instance.usuarioId!.trim().isNotEmpty) {
      return SessionService.instance.usuarioId!.trim();
    }
    return (widget.usuarioLogadoId ?? '').trim();
  }

  void _garantirUsuarioLogadoSeInscrito(List<_ParticipanteItem> lista) {
    if (!widget.evento.isInscrito || widget.isDono) return;
    final String meuId = _resolverMeuId();
    if (meuId.isEmpty) return;

    final bool jaNaLista = lista.any((p) => p.id == meuId);
    if (!jaNaLista) {
      final String meuNome =
          SessionService.instance.nomeUsuario?.trim().isNotEmpty == true
              ? SessionService.instance.nomeUsuario!.trim()
              : 'Você';
      lista.insert(
        0,
        _ParticipanteItem(
          id: meuId,
          nome: meuNome,
          fotoUrl: SessionService.instance.fotoUrl,
        ),
      );
    }
  }

  List<_ParticipanteItem> _mapearParticipantesLocais() {
    final lista = widget.evento.participantesConfirmados
        .map((dynamic p) => _ParticipanteItem(
              id: (p.id ?? '').toString(),
              nome: (p.nome ?? 'Voluntário').toString(),
              fotoUrl: p.fotoUrl?.toString(),
            ))
        .where((p) => p.id.isNotEmpty)
        .toList();

    _garantirUsuarioLogadoSeInscrito(lista);
    return lista;
  }

  bool _isStatusConfirmado(String statusRaw) {
    final s = statusRaw.toUpperCase().trim();
    return s == 'ACCEPTED' ||
        s == 'APPROVED' ||
        s == 'CONFIRMED' ||
        s == 'CONFIRMADA' ||
        s == 'APROVADO' ||
        s == 'PRESENTE' ||
        s == 'ATTENDED' ||
        s == 'PENDING' ||
        s == 'PENDENTE';
  }

  Future<void> _buscarConfirmadosNaApi() async {
    final token = SessionService.instance.token;
    if (token == null || token.trim().isEmpty || widget.evento.id.isEmpty) {
      return;
    }

    if (mounted) setState(() => _carregandoApi = true);

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

      final bodyTexto = utf8.decode(res.bodyBytes);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(bodyTexto);
        final List<dynamic> listaRaw = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] is List
                ? decoded['data'] as List<dynamic>
                : (decoded is Map && decoded['applications'] is List
                    ? decoded['applications'] as List<dynamic>
                    : <dynamic>[]));

        final List<_ParticipanteItem> confirmados = <_ParticipanteItem>[];
        for (final item in listaRaw) {
          if (item is Map<String, dynamic>) {
            final status = (item['status'] ?? '').toString();
            if (_isStatusConfirmado(status)) {
              final user = item['user'] is Map<String, dynamic>
                  ? item['user'] as Map<String, dynamic>
                  : <String, dynamic>{};

              final id =
                  (user['id'] ?? item['userId'] ?? item['id'] ?? '').toString();
              final nome =
                  (user['name'] ?? user['nome'] ?? item['nome'] ?? 'Voluntário')
                      .toString();
              final avatar =
                  (user['avatar'] ?? user['fotoUrl'] ?? item['fotoUrl'] ?? '')
                      .toString();

              if (id.isNotEmpty) {
                confirmados.add(
                  _ParticipanteItem(
                    id: id,
                    nome: nome,
                    fotoUrl: avatar.isEmpty ? null : avatar,
                  ),
                );
              }
            }
          }
        }

        _garantirUsuarioLogadoSeInscrito(confirmados);

        if (mounted) {
          setState(() {
            _participantes = confirmados;
            _carregandoApi = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint("Erro ao carregar participantes confirmados: $e");
    }

    if (mounted) {
      setState(() {
        _garantirUsuarioLogadoSeInscrito(_participantes);
        _carregandoApi = false;
      });
    }
  }

  void _abrirPerfilVoluntario(BuildContext context, String participanteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoluntarioPerfilPage(
          usuarioId: participanteId,
          usuarioLogadoId: widget.usuarioLogadoId,
          tipoUsuario: "voluntario",
        ),
      ),
    );
  }

  String _extrairPrimeiroNome(String nomeCompleto) {
    final partes = nomeCompleto
        .trim()
        .split(' ')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (partes.isEmpty) return "Voluntário";
    return partes.first;
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

  Widget _buildAvatar(String? fotoUrl, bool isEu) {
    final iconePadrao = Center(
      child: Icon(
        Icons.person_rounded,
        color: isEu ? Colors.white : const Color(0xFF0C6B6B),
        size: 24,
      ),
    );

    if (fotoUrl == null) return iconePadrao;
    final src = fotoUrl.trim();
    if (src.isEmpty ||
        src == 'null' ||
        src.contains('default.png') ||
        src.contains('placeholder')) {
      return iconePadrao;
    }

    if (src.toLowerCase().startsWith('http://') ||
        src.toLowerCase().startsWith('https://')) {
      return Image.network(
        src,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => iconePadrao,
      );
    }

    if (src.startsWith('/')) {
      return Image.network(
        '$_baseUrl$src',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => iconePadrao,
      );
    }

    final bytes = _decodificarBase64(src);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => iconePadrao,
      );
    }

    return iconePadrao;
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoApi && _participantes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC2E4DC)),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF0C6B6B),
            ),
          ),
        ),
      );
    }

    if (_participantes.isEmpty) {
      final String mensagemVazia = widget.isEventoPassado
          ? "Nenhum voluntário participou deste evento."
          : (widget.isDono
              ? "Você ainda não tem nenhum voluntário confirmado."
              : "Seja o primeiro voluntário a confirmar presença nesta ação!");

      final IconData iconeVazio = widget.isEventoPassado
          ? Icons.history_rounded
          : (widget.isDono
              ? Icons.people_outline_rounded
              : Icons.volunteer_activism_outlined);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC2E4DC)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconeVazio,
              size: 16,
              color: const Color(0xFF7AAAA0),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                mensagemVazia,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7AAAA0),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final String tituloLista = widget.isEventoPassado
        ? "Participantes do Evento (${_participantes.length})"
        : (widget.isDono
            ? "Voluntários Confirmados (${_participantes.length})"
            : "Presenças Confirmadas (${_participantes.length})");

    final String meuIdAtivo = _resolverMeuId();

    return Container(
      width: double.infinity,
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
              Text(
                tituloLista,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF062222),
                ),
              ),
              const Text(
                "Toque para ver o perfil",
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF7AAAA0),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _participantes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (ctx, index) {
                final p = _participantes[index];
                final bool isEu = !widget.isDono &&
                    meuIdAtivo.isNotEmpty &&
                    p.id == meuIdAtivo;
                final String primeiroNome =
                    isEu ? "Você" : _extrairPrimeiroNome(p.nome);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _abrirPerfilVoluntario(context, p.id),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipOval(
                            child: Container(
                              width: 44,
                              height: 44,
                              color: isEu
                                  ? const Color(0xFF0C6B6B)
                                  : const Color(0xFFD1F5EE),
                              child: _buildAvatar(p.fotoUrl, isEu),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 62,
                            child: Text(
                              primeiroNome,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    isEu ? FontWeight.bold : FontWeight.w600,
                                color: isEu
                                    ? const Color(0xFF0C6B6B)
                                    : const Color(0xFF062222),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
