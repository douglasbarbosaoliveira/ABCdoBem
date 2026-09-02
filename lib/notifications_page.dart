// lib/notificacoes_page.dart

import 'package:flutter/material.dart';

import 'app_sidebar.dart';
import 'app_header.dart';
import 'events_page.dart';
import 'models/notification_models.dart';
import 'services/notification_service.dart';

class NotificacoesPage extends StatefulWidget {
  final String usuarioId;

  const NotificacoesPage({
    super.key,
    this.usuarioId = "voluntario-1", // ID do usuário autenticado
  });

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  final NotificationService _notificationService = NotificationService();

  int _tabIndex = 0; // 0: Novas (Não lidas) | 1: Lidas
  bool _carregando = true;
  bool _erroConexao = false;
  List<NotificacaoModel> _notificacoes = [];

  @override
  void initState() {
    super.initState();
    _carregarNotificacoes();
  }

  // --- REQUISIÇÕES HTTP ---

  Future<void> _carregarNotificacoes() async {
    setState(() {
      _carregando = true;
      _erroConexao = false;
    });

    try {
      final dados = await _notificationService.buscarNotificacoes(
        widget.usuarioId,
      );
      if (mounted) {
        setState(() {
          _notificacoes = dados;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erroConexao = true;
        });
        _mostrarFeedback(
          "Não foi possível carregar as notificações.",
          isErro: true,
        );
      }
    }
  }

  Future<void> _marcarTodasComoLidas() async {
    // Atualização otimista na interface
    setState(() {
      for (var n in _notificacoes) {
        n.lida = true;
      }
    });

    try {
      await _notificationService.marcarTodasComoLidas(widget.usuarioId);
      _mostrarFeedback("Todas as notificações foram marcadas como lidas.");
    } catch (e) {
      _mostrarFeedback("Erro ao sincronizar com o servidor.", isErro: true);
    }
  }

  void _abrirDetalhesNotificacao(NotificacaoModel notif) {
    if (!notif.lida) {
      setState(() {
        notif.lida = true;
      });
      // Sincroniza leitura com a API REST em segundo plano
      _notificationService.marcarComoLida(notif.id);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notif.corTema.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(notif.icone, color: notif.corTema, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF062222),
                        ),
                      ),
                      Text(
                        notif.dataRelativa,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              notif.mensagemCompleta,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF3A6868),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            _buildDialogActions(notif),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogActions(NotificacaoModel notif) {
    if (notif.tipo == TipoNotificacao.evento) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (c, a1, a2) => const EventosPage(),
                    transitionDuration: Duration.zero,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C6B6B),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Quero Participar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: Color(0xFF0C6B6B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Fechar",
                style: TextStyle(
                  color: Color(0xFF0C6B6B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (notif.tipo == TipoNotificacao.aprovacao) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (c, a1, a2) => const EventosPage(),
                    transitionDuration: Duration.zero,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C6B6B),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Ver em Meus Eventos",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: Color(0xFF0C6B6B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Fechar",
                style: TextStyle(
                  color: Color(0xFF0C6B6B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (notif.tipo == TipoNotificacao.conquista) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _mostrarFeedback(
                  "Link de conquista copiado para a área de transferência!",
                );
              },
              icon: const Icon(
                Icons.share_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: const Text(
                "Compartilhar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C6B6B),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: Color(0xFF0C6B6B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Fechar",
                style: TextStyle(
                  color: Color(0xFF0C6B6B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0C6B6B),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: const Text(
            "Entendido",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _mostrarFeedback(String msg, {bool isErro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isErro ? Colors.redAccent : const Color(0xFF0C6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    final List<NotificacaoModel> naoLidas = _notificacoes
        .where((n) => !n.lida)
        .toList();
    final List<NotificacaoModel> lidas = _notificacoes
        .where((n) => n.lida)
        .toList();
    final List<NotificacaoModel> listaExibida = _tabIndex == 0
        ? naoLidas
        : lidas;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
        body: Row(
          children: [
            if (isDesktop) const AppSidebar(currentIndex: 3),
            Expanded(
              child: Column(
                children: [
                  const AppHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "Notificações",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF062222),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "Fique por dentro das novidades da sua comunidade",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF7AAAA0),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (naoLidas.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: _marcarTodasComoLidas,
                                      icon: const Icon(
                                        Icons.done_all_rounded,
                                        size: 16,
                                        color: Color(0xFF0C6B6B),
                                      ),
                                      label: const Text(
                                        "Marcar lidas",
                                        style: TextStyle(
                                          color: Color(0xFF0C6B6B),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFC2E4DC),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _buildTabItem(
                                      "Novas (${naoLidas.length})",
                                      0,
                                    ),
                                    const SizedBox(width: 24),
                                    _buildTabItem("Lidas (${lidas.length})", 1),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_carregando)
                                const Padding(
                                  padding: EdgeInsets.all(48.0),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        CircularProgressIndicator(
                                          color: Color(0xFF0C6B6B),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          "Buscando novidades...",
                                          style: TextStyle(
                                            color: Color(0xFF7AAAA0),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (_erroConexao)
                                _buildErrorConnectionState()
                              else if (listaExibida.isEmpty)
                                _buildEmptyState()
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: listaExibida.length,
                                  itemBuilder: (context, index) {
                                    final notif = listaExibida[index];
                                    return _buildNotificationCard(notif);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _tabIndex == index;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF0C6B6B) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? const Color(0xFF0C6B6B)
                : const Color(0xFF7AAAA0),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificacaoModel notif) {
    final bool isNaoLida = !notif.lida;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNaoLida ? const Color(0xFF9FE8D8) : const Color(0xFFC2E4DC),
          width: isNaoLida ? 1.5 : 1,
        ),
        boxShadow: isNaoLida
            ? [
                BoxShadow(
                  color: const Color(0xFF0C6B6B).withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrirDetalhesNotificacao(notif),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notif.corTema.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(notif.icone, color: notif.corTema, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.titulo,
                            style: TextStyle(
                              fontWeight: isNaoLida
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF062222),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          notif.dataRelativa,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.descricaoCurta,
                      style: TextStyle(
                        fontSize: 12,
                        color: isNaoLida
                            ? const Color(0xFF3A6868)
                            : Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (isNaoLida) ...[
                const SizedBox(width: 10),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0C6B6B),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorConnectionState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Falha ao carregar notificações",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF062222),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "Não foi possível sincronizar suas mensagens com o servidor. Verifique sua conexão.",
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _carregarNotificacoes,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: Colors.white,
            ),
            label: const Text(
              "Tentar novamente",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C6B6B),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Column(
        children: [
          const Text("🔔", style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(
            _tabIndex == 0
                ? "Você não tem notificações novas"
                : "Nenhuma notificação lida por enquanto",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF062222),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Novidades sobre eventos e ações da comunidade aparecerão aqui.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
