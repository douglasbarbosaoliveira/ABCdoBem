import 'package:flutter/material.dart';

import 'app_sidebar.dart';
import 'app_header.dart';
import 'models/ong_models.dart';
import 'services/ong_service.dart';

class BuscarOngsPage extends StatefulWidget {
  final String voluntarioId;
  final Function(int ongId)? onOngSelect;

  const BuscarOngsPage({
    super.key,
    this.voluntarioId = "voluntario-1",
    this.onOngSelect,
  });

  @override
  State<BuscarOngsPage> createState() => _BuscarOngsPageState();
}

class _BuscarOngsPageState extends State<BuscarOngsPage> {
  final OngService _ongService = OngService();
  final TextEditingController _buscaController = TextEditingController();

  String _filtroCategoria = "Todas";
  bool _carregando = true;
  bool _erroConexao = false;

  List<OngModel> _todasOngs = [];
  List<OngRecomendadaModel> _ongsRecomendadas = [];

  final List<String> _categorias = [
    "Todas",
    "Educação",
    "Meio Ambiente",
    "Saúde",
    "Cultura",
    "Habitação",
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erroConexao = false;
    });

    try {
      final resultados = await Future.wait([
        _ongService.buscarOngs(),
        _ongService.buscarRecomendacoes(widget.voluntarioId),
      ]);

      if (mounted) {
        setState(() {
          _todasOngs = resultados[0] as List<OngModel>;
          _ongsRecomendadas = resultados[1] as List<OngRecomendadaModel>;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erroConexao = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    // Filtro em memória ágil (pesquisa por nome/cidade e categoria selecionada)
    final ongsFiltradas = _todasOngs.where((ong) {
      final matchCategoria =
          _filtroCategoria == "Todas" || ong.categoria == _filtroCategoria;
      final matchBusca =
          _buscaController.text.isEmpty ||
          ong.nome.toLowerCase().contains(
            _buscaController.text.toLowerCase(),
          ) ||
          ong.cidade.toLowerCase().contains(
            _buscaController.text.toLowerCase(),
          );
      return matchCategoria && matchBusca;
    }).toList();

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
        body: Row(
          children: [
            if (isDesktop) const AppSidebar(currentIndex: 1),
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
                              const Text(
                                "Buscar ONGs",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF062222),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Grande ABC Paulista",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Barra de Pesquisa
                              TextField(
                                controller: _buscaController,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: "Nome ou cidade...",
                                  hintStyle: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: Color(0xFF0C6B6B),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFC2E4DC),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0C6B6B),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Chips de Categoria
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _categorias.map((cat) {
                                    final bool selecionado =
                                        _filtroCategoria == cat;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: ChoiceChip(
                                        label: Text(cat),
                                        selected: selecionado,
                                        selectedColor: const Color(0xFF0C6B6B),
                                        labelStyle: TextStyle(
                                          color: selecionado
                                              ? Colors.white
                                              : const Color(0xFF062222),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          side: BorderSide(
                                            color: selecionado
                                                ? const Color(0xFF0C6B6B)
                                                : const Color(0xFFC2E4DC),
                                          ),
                                        ),
                                        onSelected: (_) {
                                          setState(
                                            () => _filtroCategoria = cat,
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ESTADOS: CARREGANDO, ERRO OU LISTA
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
                                          "Localizando instituições no Grande ABC...",
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
                              else ...[
                                // --- SEÇÃO DE RECOMENDAÇÕES ---
                                if (_ongsRecomendadas.isNotEmpty) ...[
                                  const Text(
                                    "Recomendações para Você",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF062222),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Com base nas suas habilidades e causas de interesse",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: isDesktop ? 3 : 1,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          childAspectRatio: isDesktop
                                              ? 2.2
                                              : 3.2,
                                        ),
                                    itemCount: _ongsRecomendadas.length,
                                    itemBuilder: (context, index) {
                                      final rec = _ongsRecomendadas[index];
                                      return _buildRecommendationCard(rec);
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                ],

                                // --- MAPA INTERATIVO ---
                                _buildInteractiveMapWidget(ongsFiltradas),
                                const SizedBox(height: 24),

                                // Contagem e Lista de Resultados
                                Text(
                                  "${ongsFiltradas.length} resultados encontrados",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3A6868),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                if (ongsFiltradas.isEmpty)
                                  _buildEmptyState()
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: ongsFiltradas.length,
                                    itemBuilder: (context, index) {
                                      final ong = ongsFiltradas[index];
                                      return _buildOngResultCard(ong);
                                    },
                                  ),
                              ],
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

  Widget _buildRecommendationCard(OngRecomendadaModel rec) {
    return InkWell(
      onTap: () {
        if (rec.id != null) widget.onOngSelect?.call(rec.id!);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF9FE8D8)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0C6B6B).withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                rec.imagem,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1F5EE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      rec.match,
                      style: const TextStyle(
                        color: Color(0xFF0C6B6B),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rec.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF062222),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${rec.cidade} • ${rec.categoria}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveMapWidget(List<OngModel> ongsFiltradas) {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFC7EBE3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9FE8D8)),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.map_rounded, size: 48, color: Color(0xFF0C5252)),
                SizedBox(height: 8),
                Text(
                  "Mapa Interativo - A ser integrado com Google Maps ou Mapbox",
                  style: TextStyle(
                    color: Color(0xFF062222),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          ...ongsFiltradas.map((ong) {
            return Align(
              alignment: Alignment(
                ong.posMapa.x * 2 - 1,
                ong.posMapa.y * 2 - 1,
              ),
              child: Tooltip(
                message: "${ong.nome} (${ong.cidade})",
                child: InkWell(
                  onTap: () => widget.onOngSelect?.call(ong.id),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C6B6B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "${ong.id}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Text(
                "${ongsFiltradas.length} ONGs próximas a você",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C6B6B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOngResultCard(OngModel ong) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => widget.onOngSelect?.call(ong.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F5F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "${ong.id}",
                    style: const TextStyle(
                      color: Color(0xFF0C6B6B),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ong.imagem,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ong.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF062222),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ong.cidade,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F5F1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ong.categoria,
                            style: const TextStyle(
                              color: Color(0xFF0C6B6B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${ong.voluntarios} vol.",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF3A6868),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Column(
        children: [
          const Text("🏢", style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text(
            "Nenhuma instituição encontrada",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF062222),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Tente buscar com outros termos ou selecione a categoria 'Todas'.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _filtroCategoria = "Todas";
                _buscaController.clear();
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0C6B6B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Limpar busca",
              style: TextStyle(
                color: Color(0xFF0C6B6B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
            "Não foi possível carregar as ONGs",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF062222),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "Houve uma falha na comunicação com o servidor. Verifique sua conexão e tente novamente.",
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _carregarDados,
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
}
