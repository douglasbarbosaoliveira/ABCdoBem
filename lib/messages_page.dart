// lib/mensagens_page.dart

import 'package:flutter/material.dart';

import 'app_sidebar.dart';
import 'app_header.dart';
import 'models/chat_models.dart';
import 'services/chat_service.dart';

class MensagensPage extends StatefulWidget {
  /// 'voluntario' ou 'ong'
  final String tipoUsuario;
  final String usuarioId;

  const MensagensPage({
    super.key,
    this.tipoUsuario = 'voluntario',
    this.usuarioId = 'meu_id',
  });

  @override
  State<MensagensPage> createState() => _MensagensPageState();
}

class _MensagensPageState extends State<MensagensPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _mensagemController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatConversation> _conversas = [];
  ChatConversation? _conversaSelecionada;
  List<ChatMessage> _mensagensAtuais = [];

  bool _carregandoConversas = true;
  bool _carregandoMensagens = false;
  String _filtroBusca = "";

  @override
  void initState() {
    super.initState();
    _carregarListaConversas();
  }

  /// Busca as conversas na API REST
  Future<void> _carregarListaConversas() async {
    setState(() => _carregandoConversas = true);
    try {
      final resultado = await _chatService.buscarConversas(
        usuarioId: widget.usuarioId,
        tipoUsuario: widget.tipoUsuario,
      );

      setState(() {
        _conversas = resultado;
        _carregandoConversas = false;
      });

      // No Desktop, pré-seleciona a primeira conversa se disponível
      final isDesktop = MediaQuery.of(context).size.width > 900;
      if (isDesktop && _conversas.isNotEmpty && _conversaSelecionada == null) {
        _selecionarConversa(_conversas.first);
      }
    } catch (e) {
      setState(() => _carregandoConversas = false);
      _mostrarAlertaErro("Não foi possível carregar as conversas.");
    }
  }

  /// Seleciona a conversa, zera o contador de não lidas e busca o histórico
  Future<void> _selecionarConversa(ChatConversation conversa) async {
    setState(() {
      _conversaSelecionada = conversa;
      _carregandoMensagens = true;
      conversa.naoLidas = 0; // Atualização visual imediata
    });

    // Notifica a API REST em segundo plano
    _chatService.marcarComoLida(conversa.id);

    try {
      final msgs = await _chatService.buscarMensagens(conversa.id);
      setState(() {
        _mensagensAtuais = msgs;
        _carregandoMensagens = false;
      });
      _rolarParaOFim();
    } catch (e) {
      setState(() => _carregandoMensagens = false);
      _mostrarAlertaErro("Erro ao carregar mensagens desta conversa.");
    }
  }

  /// Envia uma nova mensagem para a API REST
  Future<void> _enviarMensagem() async {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty || _conversaSelecionada == null) return;

    _mensagemController.clear();

    try {
      final novaMsg = await _chatService.enviarMensagem(
        conversaId: _conversaSelecionada!.id,
        remetenteId: widget.usuarioId,
        texto: texto,
      );

      setState(() {
        _mensagensAtuais.add(novaMsg);
        _conversaSelecionada!.ultimaMensagem = novaMsg;
      });

      _rolarParaOFim();
    } catch (e) {
      _mostrarAlertaErro("Falha ao enviar mensagem. Tente novamente.");
    }
  }

  void _rolarParaOFim() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _mostrarAlertaErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    final conversasFiltradas = _conversas.where((c) {
      return c.interlocutorNome.toLowerCase().contains(
            _filtroBusca.toLowerCase(),
          ) ||
          c.interlocutorSubtitulo.toLowerCase().contains(
            _filtroBusca.toLowerCase(),
          );
    }).toList();

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
        body: Row(
          children: [
            // Sidebar mantida no desktop (Índice 4 = Mensagens)
            if (isDesktop) const AppSidebar(currentIndex: 4),
            Expanded(
              child: Column(
                children: [
                  if (isDesktop) const AppHeader(),
                  Expanded(
                    child: _carregandoConversas
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0C6B6B),
                            ),
                          )
                        : isDesktop
                        ? _buildDesktopLayout(conversasFiltradas)
                        : _buildMobileLayout(conversasFiltradas),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LAYOUT DESKTOP (Split View) ---
  Widget _buildDesktopLayout(List<ChatConversation> conversas) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC2E4DC)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 320,
              child: _buildListaConversas(conversas, isMobile: false),
            ),
            const VerticalDivider(width: 1, color: Color(0xFFC2E4DC)),
            Expanded(
              child: _conversaSelecionada == null
                  ? Center(
                      child: Text(
                        widget.tipoUsuario == 'ong'
                            ? "Selecione um voluntário para conversar"
                            : "Selecione uma instituição para conversar",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : _buildJanelaChat(isMobile: false),
            ),
          ],
        ),
      ),
    );
  }

  // --- LAYOUT MOBILE (Navegação em pilha estilo WhatsApp) ---
  Widget _buildMobileLayout(List<ChatConversation> conversas) {
    if (_conversaSelecionada != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          setState(() => _conversaSelecionada = null);
        },
        child: _buildJanelaChat(isMobile: true),
      );
    }
    return _buildListaConversas(conversas, isMobile: true);
  }

  // --- COMPONENTE: LISTA LATERAL DE CONVERSAS ---
  Widget _buildListaConversas(
    List<ChatConversation> conversas, {
    required bool isMobile,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: isMobile ? MediaQuery.of(context).padding.top + 16 : 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFC2E4DC))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Mensagens",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF062222),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: Color(0xFF0C6B6B),
                      ),
                      tooltip: "Atualizar conversas",
                      onPressed: _carregarListaConversas,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (val) => setState(() => _filtroBusca = val),
                  decoration: InputDecoration(
                    hintText: widget.tipoUsuario == 'ong'
                        ? "Buscar voluntário..."
                        : "Buscar instituição...",
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Color(0xFF0C6B6B),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF0FAF7),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFC2E4DC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0C6B6B)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: conversas.isEmpty
                ? const Center(
                    child: Text(
                      "Nenhuma conversa encontrada",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: conversas.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF0FAF7)),
                    itemBuilder: (context, index) {
                      final chat = conversas[index];
                      final isSelected =
                          !isMobile && _conversaSelecionada?.id == chat.id;

                      return InkWell(
                        onTap: () => _selecionarConversa(chat),
                        child: Container(
                          color: isSelected
                              ? const Color(0xFFD1F5EE).withOpacity(0.5)
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      chat.interlocutorFoto,
                                    ),
                                    radius: 24,
                                  ),
                                  if (chat.online)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF29B0A0),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            chat.interlocutorNome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF062222),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (chat.ultimaMensagem != null)
                                          Text(
                                            chat
                                                .ultimaMensagem!
                                                .horarioFormatado,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            chat.ultimaMensagem != null
                                                ? chat.ultimaMensagem!.texto
                                                : chat.interlocutorSubtitulo,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isSelected
                                                  ? const Color(0xFF0C6B6B)
                                                  : Colors.grey.shade600,
                                              fontWeight: chat.naoLidas > 0
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (chat.naoLidas > 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE53935),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              "${chat.naoLidas}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  // --- COMPONENTE: JANELA ATIVA DE CHAT ---
  Widget _buildJanelaChat({required bool isMobile}) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Cabeçalho da conversa ativa
          Container(
            padding: EdgeInsets.only(
              top: isMobile ? MediaQuery.of(context).padding.top + 8 : 12,
              bottom: 12,
              left: isMobile ? 8 : 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFC2E4DC))),
            ),
            child: Row(
              children: [
                if (isMobile)
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF0C6B6B),
                    ),
                    onPressed: () =>
                        setState(() => _conversaSelecionada = null),
                  ),
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    _conversaSelecionada!.interlocutorFoto,
                  ),
                  radius: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _conversaSelecionada!.interlocutorNome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF062222),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _conversaSelecionada!.online
                            ? "Online agora"
                            : _conversaSelecionada!.interlocutorSubtitulo,
                        style: TextStyle(
                          fontSize: 11,
                          color: _conversaSelecionada!.online
                              ? const Color(0xFF29B0A0)
                              : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Área de mensagens com histórico
          Expanded(
            child: Container(
              color: const Color(0xFFF0FAF7).withOpacity(0.6),
              child: _carregandoMensagens
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0C6B6B),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: _mensagensAtuais.length,
                      itemBuilder: (context, index) {
                        final msg = _mensagensAtuais[index];
                        final ehMinha = msg.remetenteId == widget.usuarioId;

                        return Align(
                          alignment: ehMinha
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width *
                                  (isMobile ? 0.75 : 0.45),
                            ),
                            decoration: BoxDecoration(
                              color: ehMinha
                                  ? const Color(0xFF0C6B6B)
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: Radius.circular(ehMinha ? 14 : 2),
                                bottomRight: Radius.circular(ehMinha ? 2 : 14),
                              ),
                              border: Border.all(
                                color: ehMinha
                                    ? Colors.transparent
                                    : const Color(0xFFC2E4DC),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: ehMinha
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.texto,
                                  style: TextStyle(
                                    color: ehMinha
                                        ? Colors.white
                                        : const Color(0xFF062222),
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg.horarioFormatado,
                                  style: TextStyle(
                                    color: ehMinha
                                        ? Colors.white70
                                        : Colors.grey,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Campo inferior para digitação e envio
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensagemController,
                      onSubmitted: (_) => _enviarMensagem(),
                      decoration: InputDecoration(
                        hintText: "Mensagem...",
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF0FAF7),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFFC2E4DC),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFF0C6B6B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _enviarMensagem,
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0C6B6B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
