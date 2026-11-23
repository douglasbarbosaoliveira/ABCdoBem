// lib/eventos/services/evento_service.dart

import '../models/evento_model.dart';
import 'evento_discovery_service.dart';
import 'evento_gestao_ong_service.dart';
import 'evento_inscricao_service.dart';
import 'evento_mapper.dart';

export 'evento_discovery_service.dart';
export 'evento_gestao_ong_service.dart';
export 'evento_inscricao_service.dart';
export 'evento_mapper.dart';

class EventoService {
  final EventoDiscoveryService _discovery = EventoDiscoveryService();
  final EventoInscricaoService _inscricao = EventoInscricaoService();
  final EventoGestaoOngService _gestaoOng = EventoGestaoOngService();

  // --- CACHE & INSCRIÇÕES ---
  Future<void> registrarInscricaoLocal(String vagaId,
          {String status = "PENDING"}) =>
      _inscricao.registrarInscricaoLocal(vagaId, status: status);

  Future<void> removerInscricaoLocal(String vagaId) =>
      _inscricao.removerInscricaoLocal(vagaId);

  Future<MapaInscricoes> obterInscricoesLocais() =>
      _inscricao.obterInscricoesLocais();

  Future<List<InscricaoEventoModel>> listarMinhasInscricoes(
    String voluntarioId, {
    String? token,
  }) =>
      _inscricao.listarMinhasInscricoes(voluntarioId, token: token);

  Future<bool> inscreverVoluntario(
    String eventoId,
    String voluntarioId, {
    String? tipoCarona,
    String? detalhesCarona,
    String? token,
  }) =>
      _inscricao.inscreverVoluntario(
        eventoId,
        voluntarioId,
        tipoCarona: tipoCarona,
        detalhesCarona: detalhesCarona,
        token: token,
      );

  Future<bool> cancelarInscricao(
    String eventoId,
    String voluntarioId, {
    String? token,
    String? motivo,
  }) =>
      _inscricao.cancelarInscricao(
        eventoId,
        voluntarioId,
        token: token,
        motivo: motivo,
      );

  // --- DESCOBERTA, IA/ML & PROXIMIDADE ---
  Future<List<EventoModel>> listarEventos({
    String? cidade,
    String? categoria,
    String? busca,
    String? token,
    bool incluirEncerrados = false,
  }) async {
    final locais = await obterInscricoesLocais();
    return _discovery.listarEventos(
      cidade: cidade,
      categoria: categoria,
      busca: busca,
      token: token,
      incluirEncerrados: incluirEncerrados,
      inscricoesLocais: locais,
    );
  }

  Future<List<MapaJson>> listarEventosRecomendados({String? token}) =>
      _discovery.listarEventosRecomendados(token: token);

  Future<List<MapaJson>> listarEventosProximos({String? token}) =>
      _discovery.listarEventosProximos(token: token);

  Future<List<MapaJson>> listarRecomendadosEProximos({
    String? token,
    List<EventoModel>? catalogoBase,
  }) =>
      _discovery.listarRecomendadosEProximos(
        token: token,
        catalogoBase: catalogoBase,
      );

  Future<MapaJson?> buscarDetalhesBrutosPorId(String id, {String? token}) =>
      _discovery.buscarDetalhesBrutosPorId(id, token: token);

  Future<EventoModel?> buscarPorId(
    String id, {
    String? voluntarioId,
    String? token,
  }) async {
    final locais = await obterInscricoesLocais();
    return _discovery.buscarPorId(
      id,
      token: token,
      inscricoesLocais: locais,
    );
  }

  Future<List<EventoModel>> listarEventosPorOng(
    String ongId, {
    String? token,
  }) =>
      _discovery.listarEventosPorOng(ongId, token: token);

  Future<List<EventoModel>> buscarEventos({
    String? ongId,
    String? busca,
    String? cidade,
    String? categoria,
    String? token,
  }) {
    if (ongId != null && ongId.isNotEmpty) {
      return listarEventosPorOng(ongId, token: token);
    }
    return listarEventos(
      cidade: cidade,
      categoria: categoria,
      busca: busca,
      token: token,
    );
  }

  // --- GESTÃO ONG ---
  Future<EventoModel?> criarEvento(
    CriarEventoDTO dto, {
    String? modality,
    int? durationHours,
    DateTime? endDate,
    String? cep,
    String? logradouro,
    String? numero,
    String? bairro,
    String? estado,
    int? minAge,
    String? token,
  }) =>
      _gestaoOng.criarEvento(
        dto,
        modality: modality,
        durationHours: durationHours,
        endDate: endDate,
        cep: cep,
        logradouro: logradouro,
        numero: numero,
        bairro: bairro,
        estado: estado,
        minAge: minAge,
        token: token,
      );

  Future<EventoModel?> atualizarEvento(
    String eventoId,
    MapaJson payloadAtualizado, {
    String? token,
  }) =>
      _gestaoOng.atualizarEvento(eventoId, payloadAtualizado, token: token);

  Future<bool> atualizarStatusEvento(
    String eventoId,
    String novoStatus, {
    String? token,
  }) =>
      _gestaoOng.atualizarStatusEvento(eventoId, novoStatus, token: token);
}
