// lib/eventos/detalhe/widgets/modal_editar_evento.dart

import 'package:flutter/material.dart';
import '../../models/evento_model.dart';
import '../../services/evento_service.dart';

class ModalEditarEvento extends StatefulWidget {
  final EventoModel evento;

  const ModalEditarEvento({super.key, required this.evento});

  static Future<bool?> exibir(BuildContext context, EventoModel evento) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModalEditarEvento(evento: evento),
    );
  }

  @override
  State<ModalEditarEvento> createState() => _ModalEditarEventoState();
}

class _ModalEditarEventoState extends State<ModalEditarEvento> {
  final _formKey = GlobalKey<FormState>();
  final EventoService _eventoService = EventoService();

  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _vagasController;
  late final TextEditingController _cidadeController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _bannerController;

  late DateTime _dataHoraSelecionada;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final ev = widget.evento;
    _tituloController = TextEditingController(text: ev.titulo);
    _descricaoController = TextEditingController(text: ev.descricao);
    _vagasController = TextEditingController(text: ev.vagasTotais.toString());
    _cidadeController = TextEditingController(text: ev.cidade);
    _enderecoController = TextEditingController(text: ev.endereco);
    _bannerController = TextEditingController(text: ev.imagemUrl);
    _dataHoraSelecionada = ev.dataHoraInicio;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _vagasController.dispose();
    _cidadeController.dispose();
    _enderecoController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataHora() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataHoraSelecionada,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (data == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHoraSelecionada),
    );
    if (hora == null || !mounted) return;

    setState(() {
      _dataHoraSelecionada = DateTime(
        data.year,
        data.month,
        data.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      final int vagas = int.tryParse(_vagasController.text.trim()) ??
          widget.evento.vagasTotais;

      final payload = <String, dynamic>{
        "title": _tituloController.text.trim(),
        "description": _descricaoController.text.trim(),
        "totalVacancies": vagas,
        "cidade": _cidadeController.text.trim(),
        "logradouro": _enderecoController.text.trim(),
        "eventDate": _dataHoraSelecionada.toUtc().toIso8601String(),
        if (_bannerController.text.trim().isNotEmpty)
          "banner": _bannerController.text.trim(),
      };

      final atualizado = await _eventoService.atualizarEvento(
        widget.evento.id,
        payload,
      );

      if (!mounted) return;
      setState(() => _salvando = false);

      if (atualizado != null) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Não foi possível salvar as alterações."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dataFmt =
        "${_dataHoraSelecionada.day.toString().padLeft(2, '0')}/${_dataHoraSelecionada.month.toString().padLeft(2, '0')}/${_dataHoraSelecionada.year} às ${_dataHoraSelecionada.hour.toString().padLeft(2, '0')}:${_dataHoraSelecionada.minute.toString().padLeft(2, '0')}";

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Editar Ação Solidária",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF062222),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: "Título do Evento",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Informe o título" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Descrição detalhada",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Informe a descrição"
                    : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selecionarDataHora,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Data e Horário de Início",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_month_rounded,
                        color: Color(0xFF0C6B6B)),
                  ),
                  child: Text(
                    dataFmt,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF062222),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _vagasController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Total de Vagas",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return "Vagas inválidas";
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _cidadeController,
                      decoration: const InputDecoration(
                        labelText: "Cidade",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _enderecoController,
                decoration: const InputDecoration(
                  labelText: "Endereço / Local de Encontro",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bannerController,
                decoration: const InputDecoration(
                  labelText: "URL ou Base64 da Imagem de Capa",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _salvando ? null : _salvarAlteracoes,
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(
                  _salvando ? "Salvando..." : "Salvar Alterações",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C6B6B),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
