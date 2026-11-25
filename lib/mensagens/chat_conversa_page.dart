// lib/mensagens/chat_conversa_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/session_service.dart';

class ChatConversaPage extends StatefulWidget {
  final String destinatarioId;
  final String destinatarioNome;
  final String? destinatarioFoto;

  const ChatConversaPage({
    super.key,
    required this.destinatarioId,
    required this.destinatarioNome,
    this.destinatarioFoto,
  });

  @override
  State<ChatConversaPage> createState() => _ChatConversaPageState();
}

class _ChatConversaPageState extends State<ChatConversaPage> {
  static const String baseUrl = 'https://abc-do-bem.onrender.com';

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _mensagens = <dynamic>[];
  bool _carregando = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, String> get _headers {
    final token = SessionService.instance.token?.trim();
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _carregarHistorico() async {
    setState(() => _carregando = true);
    final url = Uri.parse('$baseUrl/chat/history/${widget.destinatarioId}');

   

    try {
      final response = await http.get(url, headers: _headers);

      debugPrint('Status Code Histórico: ${response.statusCode}');
      

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List) {
          setState(() {
            _mensagens = List<dynamic>.from(data);
            _carregando = false;
          });
          _scrollParaFim();
          return;
        }
      }
    } catch (e) {
      debugPrint('>>> ERRO ao carregar histórico: $e');
    }

    if (mounted) {
      setState(() => _carregando = false);
    }
  }

  Future<void> _enviarMensagem() async {
    final texto = _msgController.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);
    _msgController.clear();

    final meuId = SessionService.instance.usuarioId ?? '';
    final url = Uri.parse('$baseUrl/chat/send');

    final payloadEnvio = <String, dynamic>{
      'receiverId': widget.destinatarioId,
      'content': texto,
    };


    // Mensagem otimista exibida imediatamente na tela
    final novaMensagemLocal = <String, dynamic>{
      'senderId': meuId,
      'receiverId': widget.destinatarioId,
      'content': texto,
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _mensagens.add(novaMensagemLocal);
    });
    _scrollParaFim();

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payloadEnvio),
      );

      debugPrint('Status Code Envio: ${response.statusCode}');
     

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('>>> Mensagem persistida no banco com sucesso!');
      } else {
        debugPrint('>>> Falha ao persistir mensagem: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('>>> ERRO de envio: $e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _scrollParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final meuId = SessionService.instance.usuarioId;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C6B6B)),
          onPressed: () => Navigator.pop(
              context, true), // Retorna 'true' para atualizar a lista anterior
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFD1F5EE),
              backgroundImage: (widget.destinatarioFoto != null &&
                      widget.destinatarioFoto!.startsWith('http'))
                  ? NetworkImage(widget.destinatarioFoto!)
                  : null,
              child: (widget.destinatarioFoto == null ||
                      !widget.destinatarioFoto!.startsWith('http'))
                  ? Text(
                      widget.destinatarioNome.isNotEmpty
                          ? widget.destinatarioNome[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C6B6B),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.destinatarioNome,
                    style: const TextStyle(
                      color: Color(0xFF062222),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Online no ABC do Bem',
                    style: TextStyle(color: Color(0xFF2BB696), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _carregando
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0C6B6B)),
                  )
                : _mensagens.isEmpty
                    ? Center(
                        child: Text(
                          'Inicie uma conversa solidária com ${widget.destinatarioNome}!',
                          style: const TextStyle(
                            color: Color(0xFF7AAAA0),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        itemCount: _mensagens.length,
                        itemBuilder: (context, index) {
                          final dynamic msgRaw = _mensagens[index];
                          final Map<String, dynamic> msg = msgRaw is Map
                              ? Map<String, dynamic>.from(msgRaw)
                              : <String, dynamic>{};

                          final bool souEu =
                              (msg['senderId']?.toString() == meuId) ||
                                  (msg['fromMe'] == true);
                          final texto = msg['content']?.toString() ??
                              msg['texto']?.toString() ??
                              '';

                          return Align(
                            alignment: souEu
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: souEu
                                    ? const Color(0xFF0C6B6B)
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft: Radius.circular(souEu ? 14 : 2),
                                  bottomRight: Radius.circular(souEu ? 2 : 14),
                                ),
                                border: souEu
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFC2E4DC)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x06062222),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                texto,
                                style: TextStyle(
                                  color: souEu
                                      ? Colors.white
                                      : const Color(0xFF062222),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFC2E4DC))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FAF7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFBFE5DC)),
                      ),
                      child: TextField(
                        controller: _msgController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Digite uma mensagem...',
                          hintStyle: TextStyle(
                            color: Color(0xFF7AAAA0),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _enviarMensagem(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _enviarMensagem,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(10),
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
