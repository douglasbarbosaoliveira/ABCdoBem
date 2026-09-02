import 'dart:async';

import 'package:flutter/material.dart';

import 'app_sidebar.dart';
import 'app_header.dart';
import 'models/event_models.dart';
import 'services/event_service.dart';

class EventosPage extends StatefulWidget {
  final Function(String ongId)? onOngSelect;
  final Function(String eventId)? onShareEvent;
  final String voluntarioId;

  const EventosPage({
    super.key,
    this.onOngSelect,
    this.onShareEvent,
    this.voluntarioId = "voluntario-1",
  });

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  final EventService _eventService = EventService();

  int _mainTabIndex = 0; // 0: Descobrir Eventos | 1: Meus Eventos
  String _selectedTag = "Todos";
  String _viewMode = "list";

  late DateTime _currentMonthDate;
  String? _selectedDate;

  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  // Estados de dados da API
  bool _carregandoEventos = true;
  bool _carregandoMeusEventos = false;
  bool _erroConexaoEventos = false;
  bool _erroConexaoMeusEventos = false;

  List<EventoModel> _events = [];
  List<InscricaoEventoModel> _proximosEventos = [];
  List<InscricaoEventoModel> _eventosConcluidos = [];

  final List<String> _tags = [
    "Todos",
    "Educação",
    "Meio Ambiente",
    "Saúde",
    "Cultura",
    "Habitação",
  ];

  final List<String> _weekdays = [
    "Dom",
    "Seg",
    "Ter",
    "Qua",
    "Qui",
    "Sex",
    "Sáb",
  ];

  final List<String> _months = [
    "Janeiro",
    "Fevereiro",
    "Março",
    "Abril",
    "Maio",
    "Junho",
    "Julho",
    "Agosto",
    "Setembro",
    "Outubro",
    "Novembro",
    "Dezembro",
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonthDate = DateTime(now.year, now.month, 1);

    // Atualiza a contagem regressiva a cada minuto
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _carregarEventosVitrine();
    _carregarMeusEventos();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // --- REQUISIÇÕES HTTP ---

  Future<void> _carregarEventosVitrine() async {
    setState(() {
      _carregandoEventos = true;
      _erroConexaoEventos = false;
    });

    try {
      final eventos = await _eventService.buscarEventosDisponiveis(
        voluntarioId: widget.voluntarioId,
        tag: _selectedTag,
      );
      if (mounted) {
        setState(() {
          _events = eventos;
          _carregandoEventos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregandoEventos = false;
          _erroConexaoEventos = true;
        });
        _mostrarSnackBar(
          "A conexão com o servidor falhou. Verifique sua rede.",
          isErro: true,
        );
      }
    }
  }

  Future<void> _carregarMeusEventos() async {
    setState(() {
      _carregandoMeusEventos = true;
      _erroConexaoMeusEventos = false;
    });

    try {
      final mapa = await _eventService.buscarMeusEventos(widget.voluntarioId);
      if (mounted) {
        setState(() {
          _proximosEventos = mapa['proximos'] ?? [];
          _eventosConcluidos = mapa['concluidos'] ?? [];
          _carregandoMeusEventos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregandoMeusEventos = false;
          _erroConexaoMeusEventos = true;
        });
      }
    }
  }

  void _mostrarSnackBar(String mensagem, {bool isErro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isErro ? Colors.redAccent : const Color(0xFF0C6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // --- CÁLCULOS DO CALENDÁRIO ---

  List<int?> _buildCalendarCells(int year, int month) {
    final firstDayWeekday = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final List<int?> cells = [];

    for (int i = 0; i < firstDayWeekday; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(d);
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  String _formatCellDate(int year, int month, int day) {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return "$year-$m-$d";
  }

  void _prevMonth() {
    setState(() {
      _currentMonthDate = DateTime(
        _currentMonthDate.year,
        _currentMonthDate.month - 1,
        1,
      );
      _selectedDate = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonthDate = DateTime(
        _currentMonthDate.year,
        _currentMonthDate.month + 1,
        1,
      );
      _selectedDate = null;
    });
  }

  // --- POP-UP DE CONFIRMAÇÃO DE INSCRIÇÃO ---

  void _mostrarPopupConfirmacao(EventoModel ev) {
    bool autorizouContato = false;
    bool enviando = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF0C6B6B),
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Confirmar Participação",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF062222),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                ev.titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C6B6B),
                ),
              ),
              const SizedBox(height: 12),
              _buildPopupInfoRow(
                Icons.business_rounded,
                "Instituição:",
                ev.ongNome,
              ),
              const SizedBox(height: 8),
              _buildPopupInfoRow(
                Icons.calendar_today_rounded,
                "Data:",
                ev.data,
              ),
              const SizedBox(height: 8),
              _buildPopupInfoRow(
                Icons.access_time_rounded,
                "Horário:",
                ev.horario,
              ),
              const SizedBox(height: 8),
              _buildPopupInfoRow(
                Icons.location_on_outlined,
                "Local:",
                ev.cidade,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F5F1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC2E4DC)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Color(0xFF0C6B6B),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Ao confirmar, enviaremos a sua solicitação diretamente para a instituição responsável, que avaliará sua inscrição.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF062222),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: autorizouContato,
                      activeColor: const Color(0xFF0C6B6B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: enviando
                          ? null
                          : (val) {
                              setDialogState(() {
                                autorizouContato = val ?? false;
                              });
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: enviando
                          ? null
                          : () {
                              setDialogState(() {
                                autorizouContato = !autorizouContato;
                              });
                            },
                      child: const Text(
                        "Autorizo que a instituição entre em contato comigo pelo aplicativo, e-mail e WhatsApp cadastrado.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF062222),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (!autorizouContato || enviando)
                        ? null
                        : () async {
                            setDialogState(() => enviando = true);
                            try {
                              await _eventService.solicitarParticipacao(
                                eventoId: ev.id,
                                voluntarioId: widget.voluntarioId,
                                autorizouContato: autorizouContato,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                _mostrarSnackBar(
                                  "Solicitação enviada para ${ev.ongNome}!",
                                );
                                _carregarEventosVitrine();
                                _carregarMeusEventos();
                              }
                            } catch (e) {
                              setDialogState(() => enviando = false);
                              _mostrarSnackBar(
                                "Erro ao enviar solicitação.",
                                isErro: true,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C6B6B),
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: enviando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "Sim, quero participar",
                            style: TextStyle(
                              color: autorizouContato
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: enviando ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
            ),
          ],
        ),
      ),
    );
  }

  // --- POP-UP DE CANCELAMENTO DE PARTICIPAÇÃO ---

  void _mostrarPopupCancelamento(
    String eventoId,
    String titulo,
    String ongNome,
  ) {
    String? motivoSelecionado;
    bool cancelamentoEnviado = false;
    bool enviando = false;
    String? erroMotivo;

    final List<String> opcoesMotivos = [
      "Saúde / Mal-estar",
      "Compromisso de Trabalho",
      "Motivos Pessoais",
      "Ajuda em outra instituição",
      "Dificuldade de Transporte",
      "Conflito de Horário",
      "Outros",
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: cancelamentoEnviado
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD1F5EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFF0C6B6B),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Cancelamento Enviado",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF062222),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Avisamos a $ongNome sobre a sua desistência.\n\nSabemos que imprevistos acontecem! Seu apoio faz toda a diferença para o Grande ABC e estaremos de braços abertos te esperando na próxima oportunidade. 💚",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3A6868),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _carregarEventosVitrine();
                            _carregarMeusEventos();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C6B6B),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Entendido, até a próxima!",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Cancelar Participação?",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF062222),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF3A6868),
                            fontFamily: 'Quicksand',
                            height: 1.3,
                          ),
                          children: [
                            const TextSpan(
                              text: "Você está prestes a liberar sua vaga no evento ",
                            ),
                            TextSpan(
                              text: titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF062222),
                              ),
                            ),
                            const TextSpan(
                              text: ". Tem certeza que deseja prosseguir?",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Qual o motivo da desistência?",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF062222),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: opcoesMotivos.map((motivo) {
                          final isSelected = motivoSelecionado == motivo;
                          return ChoiceChip(
                            label: Text(motivo),
                            selected: isSelected,
                            selectedColor: const Color(0xFFD1F5EE),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF0C6B6B)
                                  : const Color(0xFF062222),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF0C6B6B)
                                    : const Color(0xFFC2E4DC),
                              ),
                            ),
                            onSelected: enviando
                                ? null
                                : (selected) {
                                    setDialogState(() {
                                      motivoSelecionado = selected
                                          ? motivo
                                          : null;
                                      if (motivoSelecionado != null)
                                        erroMotivo = null;
                                    });
                                  },
                          );
                        }).toList(),
                      ),
                      if (erroMotivo != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          erroMotivo!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: enviando
                                  ? null
                                  : () async {
                                      if (motivoSelecionado == null) {
                                        setDialogState(() {
                                          erroMotivo =
                                              "Selecione uma das opções acima.";
                                        });
                                        return;
                                      }

                                      setDialogState(() => enviando = true);
                                      try {
                                        await _eventService
                                            .cancelarParticipacao(
                                              eventoId: eventoId,
                                              voluntarioId: widget.voluntarioId,
                                              motivo: motivoSelecionado!,
                                            );
                                        setDialogState(() {
                                          enviando = false;
                                          cancelamentoEnviado = true;
                                        });
                                      } catch (e) {
                                        setDialogState(() => enviando = false);
                                        _mostrarSnackBar(
                                          "Falha ao cancelar inscrição.",
                                          isErro: true,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: enviando
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Confirmar Cancelamento",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: enviando
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF0C6B6B),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Voltar",
                                style: TextStyle(
                                  color: Color(0xFF0C6B6B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildPopupInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF7AAAA0)),
        const SizedBox(width: 6),
        Text(
          "$label ",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Color(0xFF3A6868)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
        body: Row(
          children: [
            if (isDesktop) const AppSidebar(currentIndex: 2),
            Expanded(
              child: Column(
                children: [
                  const AppHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildMainTabsSelector(),
                              const SizedBox(height: 24),
                              if (_mainTabIndex == 0)
                                _buildDescobrirEventosView()
                              else
                                _buildMeusEventosView(),
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

  // --- SELETOR DE ABAS PRINCIPAIS ---

  Widget _buildMainTabsSelector() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFC2E4DC), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          _buildMainTabItem("Descobrir Eventos", 0),
          const SizedBox(width: 24),
          _buildMainTabItem("Meus Eventos (${_proximosEventos.length})", 1),
        ],
      ),
    );
  }

  Widget _buildMainTabItem(String label, int index) {
    final isSelected = _mainTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _mainTabIndex = index);
        if (index == 1) _carregarMeusEventos();
      },
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? const Color(0xFF0C6B6B)
                : const Color(0xFF7AAAA0),
          ),
        ),
      ),
    );
  }

  // --- ABA 1: DESCOBRIR EVENTOS ---

  Widget _buildDescobrirEventosView() {
    final eventDates = _events.map((e) => e.data).toSet();
    final filteredEvents = _events.where((ev) {
      final matchDate = _selectedDate == null || ev.data == _selectedDate;
      return matchDate;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Eventos no Grande ABC",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF062222),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Participe e faça a diferença",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7AAAA0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            _buildViewToggle(),
          ],
        ),
        const SizedBox(height: 16),
        _buildTagFilters(),
        const SizedBox(height: 24),
        if (_viewMode == "calendar") ...[
          _buildCalendarSection(eventDates),
          const SizedBox(height: 20),
        ],
        if (_selectedDate != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Eventos em: $_selectedDate",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF062222),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedDate = null),
                  child: const Text(
                    "Ver todos",
                    style: TextStyle(
                      color: Color(0xFF0C6B6B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // TRATAMENTO DE CARREGAMENTO, ERRO OU LISTAGEM
        if (_carregandoEventos)
          const Padding(
            padding: EdgeInsets.all(48.0),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF0C6B6B)),
                  SizedBox(height: 12),
                  Text(
                    "Carregando eventos...",
                    style: TextStyle(color: Color(0xFF7AAAA0), fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else if (_erroConexaoEventos)
          _buildErrorConnectionState(aoTentarNovamente: _carregarEventosVitrine)
        else if (filteredEvents.isEmpty)
          _buildEmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              return _buildEventCard(filteredEvents[index]);
            },
          ),
      ],
    );
  }

  // --- ABA 2: MEUS EVENTOS ---

  Widget _buildMeusEventosView() {
    if (_carregandoMeusEventos) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF0C6B6B)),
              SizedBox(height: 12),
              Text(
                "Carregando suas participações...",
                style: TextStyle(color: Color(0xFF7AAAA0), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_erroConexaoMeusEventos) {
      return _buildErrorConnectionState(
        aoTentarNovamente: _carregarMeusEventos,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Próximos Eventos",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Eventos em que sua participação está confirmada ou aguardando aprovação",
          style: TextStyle(fontSize: 12, color: Color(0xFF7AAAA0)),
        ),
        const SizedBox(height: 16),
        if (_proximosEventos.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC2E4DC)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Text("🎯", style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  const Text(
                    "Você ainda não se inscreveu em nenhum evento",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF062222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Explore a aba Descobrir e encontre uma causa para apoiar.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => _mainTabIndex = 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C6B6B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Explorar Eventos",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _proximosEventos.length,
            itemBuilder: (context, index) {
              final inscricao = _proximosEventos[index];
              if (inscricao.evento == null) return const SizedBox.shrink();
              return _buildUpcomingEventCardWithCountdown(inscricao);
            },
          ),
        const SizedBox(height: 36),
        const Text(
          "Eventos Concluídos",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Histórico de ações sociais que contaram com a sua ajuda",
          style: TextStyle(fontSize: 12, color: Color(0xFF7AAAA0)),
        ),
        const SizedBox(height: 16),
        if (_eventosConcluidos.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC2E4DC)),
            ),
            child: const Center(
              child: Text(
                "Você ainda não possui histórico de participações concluídas.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _eventosConcluidos.length,
            itemBuilder: (context, index) {
              final inscricao = _eventosConcluidos[index];
              return _buildPastEventCard(inscricao);
            },
          ),
      ],
    );
  }

  // --- COMPONENTES VISUAIS DOS CARDS ---

  Widget _buildUpcomingEventCardWithCountdown(InscricaoEventoModel inscricao) {
    final ev = inscricao.evento!;
    final diff = ev.dataHoraInicio.difference(_now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    final String status = inscricao.status;
    final bool isAprovado = status.toLowerCase() == "aprovado";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9FE8D8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C6B6B).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF062222), Color(0xFF0C5252)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                diff.isNegative
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "Em andamento",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Color(0xFF9FE8D8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Começa em: ",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _buildCountdownUnit("$days", "dias"),
                          const Text(
                            " : ",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildCountdownUnit(
                            "${hours.toString().padLeft(2, '0')}",
                            "horas",
                          ),
                          const Text(
                            " : ",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildCountdownUnit(
                            "${minutes.toString().padLeft(2, '0')}",
                            "min",
                          ),
                        ],
                      ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAprovado
                        ? const Color(0xFF29B0A0)
                        : Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAprovado
                            ? Icons.check_circle_outline_rounded
                            : Icons.hourglass_top_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    ev.imagemUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ev.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF062222),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "🏢 ${ev.ongNome}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0C6B6B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "📅 ${ev.data} • ${ev.horario} • 📍 ${ev.cidade}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _mostrarPopupCancelamento(ev.id, ev.titulo, ev.ongNome),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownUnit(String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF9FE8D8),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 9)),
      ],
    );
  }

  Widget _buildPastEventCard(InscricaoEventoModel inscricao) {
    final ev = inscricao.evento;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              ev?.imagemUrl ?? "https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?w=600",
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ev?.titulo ?? "Ação Social",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF062222),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${ev?.ongNome ?? 'Instituição'} • ${ev?.cidade ?? 'Grande ABC'}",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  "Participado em: ${ev?.data ?? ''}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7AAAA0),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD1F5EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF0C6B6B),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  "${inscricao.horasValidadas}h validadas",
                  style: const TextStyle(
                    color: Color(0xFF0C6B6B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFD1F5EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption("☰ Lista", "list"),
          _buildToggleOption("📅 Calendário", "calendar"),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, String mode) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? const Color(0xFF0C6B6B)
                : const Color(0xFF3A6868),
          ),
        ),
      ),
    );
  }

  Widget _buildTagFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tags.map((tag) {
          final isSelected = _selectedTag == tag;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTag = tag);
                _carregarEventosVitrine();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF0C6B6B), Color(0xFF29B0A0)],
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFFD1F5EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF0C6B6B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarSection(Set<String> eventDates) {
    final year = _currentMonthDate.year;
    final month = _currentMonthDate.month;
    final cells = _buildCalendarCells(year, month);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A3B3B), Color(0xFF0C6B6B)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                Text(
                  "${_months[month - 1]} $year",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFC2E4DC))),
            ),
            child: Row(
              children: _weekdays.map((w) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      w,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7AAAA0),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, i) {
              final day = cells[i];
              if (day == null) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: const BorderSide(color: Color(0x33C2E4DC)),
                      right: (i % 7 != 6)
                          ? const BorderSide(color: Color(0x33C2E4DC))
                          : BorderSide.none,
                    ),
                  ),
                );
              }

              final dateStr = _formatCellDate(year, month, day);
              final hasEvent = eventDates.contains(dateStr);
              final isSelected = _selectedDate == dateStr;
              final isToday = dateStr == todayStr;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = isSelected ? null : dateStr;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0C6B6B)
                        : isToday
                        ? const Color(0xFFD1F5EE)
                        : Colors.transparent,
                    border: Border(
                      bottom: const BorderSide(color: Color(0x33C2E4DC)),
                      right: (i % 7 != 6)
                          ? const BorderSide(color: Color(0x33C2E4DC))
                          : BorderSide.none,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$day",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : isToday
                              ? const Color(0xFF0C6B6B)
                              : const Color(0xFF062222),
                        ),
                      ),
                      if (hasEvent)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFF9FE8D8)
                                : const Color(0xFF29B0A0),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: const [
                _CalendarLegendItem(
                  color: Color(0xFF29B0A0),
                  label: "Tem evento",
                  isCircle: true,
                ),
                SizedBox(width: 16),
                _CalendarLegendItem(color: Color(0xFFD1F5EE), label: "Hoje"),
                SizedBox(width: 16),
                _CalendarLegendItem(
                  color: Color(0xFF0C6B6B),
                  label: "Selecionado",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventoModel ev) {
    final bool isInscrito = ev.isInscrito;
    final bool isFull = ev.isEsgotado;
    final bool isAlmostFull = ev.isQuaseEsgotado;
    final double progress = ev.progressoOcupacao;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC2E4DC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                ev.imagemUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB3062222)],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isFull
                        ? Colors.redAccent
                        : isAlmostFull
                        ? Colors.amber.shade700
                        : const Color(0xFF29B0A0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFull ? "Esgotado" : "${ev.vagasRestantes} vagas",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      children: ev.tags.map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ev.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => widget.onOngSelect?.call(ev.ongId),
                      child: Text(
                        "🏢 ${ev.ongNome}",
                        style: const TextStyle(
                          color: Color(0xFF0C6B6B),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (widget.onShareEvent != null)
                      InkWell(
                        onTap: () => widget.onShareEvent?.call(ev.id),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.share_outlined,
                              size: 14,
                              color: Color(0xFF7AAAA0),
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Compartilhar",
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF7AAAA0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "📅 ${ev.data} • ${ev.horario}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "📍 ${ev.cidade}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ev.descricao,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3A6868),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${ev.vagasTotais - ev.vagasRestantes} inscritos",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF7AAAA0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${ev.vagasTotais} vagas totais",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF7AAAA0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFD1F5EE),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFull
                          ? Colors.redAccent
                          : isAlmostFull
                          ? Colors.amber
                          : const Color(0xFF0C6B6B),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isFull
                        ? null
                        : () {
                            if (isInscrito) {
                              _mostrarPopupCancelamento(
                                ev.id,
                                ev.titulo,
                                ev.ongNome,
                              );
                            } else {
                              _mostrarPopupConfirmacao(ev);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInscrito
                          ? const Color(0xFFD1F5EE)
                          : const Color(0xFF0C6B6B),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isInscrito
                            ? const BorderSide(
                                color: Color(0xFF29B0A0),
                                width: 1.5,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: Text(
                      isFull
                          ? "Esgotado"
                          : isInscrito
                          ? "✓ Inscrito — Cancelar"
                          : "Quero Participar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFull
                            ? Colors.grey
                            : isInscrito
                            ? const Color(0xFF0C6B6B)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ESTADOS VAZIOS E DE FALHA DE CONEXÃO ---

  Widget _buildErrorConnectionState({required VoidCallback aoTentarNovamente}) {
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
            "Conexão com o servidor falhou",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF062222),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "Não foi possível conectar ao banco de dados ou sincronizar os eventos. Verifique sua conexão e tente novamente.",
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: aoTentarNovamente,
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
    final bool temFiltroAtivo =
        _selectedTag != "Todos" || _selectedDate != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Column(
        children: [
          const Text("🔍", style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            temFiltroAtivo
                ? "Nenhum evento encontrado para este filtro"
                : "Nenhum evento cadastrado no momento",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF062222),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            temFiltroAtivo
                ? "Tente selecionar outra causa ou limpar a data do calendário para ver mais opções."
                : "Fique de olho! Novas oportunidades são publicadas frequentemente por ONGs da região.",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (temFiltroAtivo) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedTag = "Todos";
                  _selectedDate = null;
                });
                _carregarEventosVitrine();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0C6B6B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
              child: const Text(
                "Limpar filtros e ver todos",
                style: TextStyle(
                  color: Color(0xFF0C6B6B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalendarLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isCircle;

  const _CalendarLegendItem({
    required this.color,
    required this.label,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7AAAA0),
          ),
        ),
      ],
    );
  }
}
