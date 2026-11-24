# ABC do Bem - Flutter Frontend

Resumo da arquitetura, dependências e comandos do projeto **ABC do Bem**.

## 🏗️ Arquitetura do Projeto (`lib/`)
O projeto adota uma arquitetura modular orientada a domínios e funcionalidades em `lib/`:
- **`acessibilidade/`**: Controladores, temas de alto contraste, integração com VLibras e widgets de acessibilidade.
- **`admin/`**: Painel administrativo, modelos, serviços e widgets de gestão.
- **`components/`**: Componentes reutilizáveis de UI (botões, feedback, inputs, layout).
- **`core/`**: Configurações centrais do app (temas globais, diálogos).
- **`eventos/`**: Gestão e detalhes de eventos, visualizações de ONGs e voluntários.
- **`login/`** & **`register/`**: Fluxos de autenticação e cadastro segmentados para Voluntários e ONGs.
- **`mensagens/`**: Módulo de chat e conversas.
- **`ongs/`** & **`voluntarios/`**: Módulos específicos com painéis, perfis, home e serviços para cada persona.
- **`vagas/`**: Gestão de vagas de voluntariado.
- **`nlp/`**: Serviços de Processamento de Linguagem Natural (PLN), sugestão de causas via IA e vocabulário.
- **`notificacoes/`**: Central de notificações.
- **`services/`**: Serviços globais (Auth, Supabase, Storage, Sessão, Localização, etc.).
- **`models/`**: DTOs e modelos de dados globais (Sessão, Busca de ONGs, Voluntários, etc.).
- **`utils/`**: Formatadores, validadores, helpers responsivos e de compartilhamento social.
- **`widgets/`**: Widgets compartilhados globais (mapas, feed, navegação, match, etc.).

## 📦 Dependências Principais (`pubspec.yaml`)
- **Backend & Banco de Dados**: `supabase_flutter` (^2.8.0)
- **Geolocalização & Mapas**: `flutter_map` (^7.0.2), `latlong2` (^0.9.1), `geolocator` (^13.0.1)
- **Armazenamento & Utilitários**: `shared_preferences` (^2.3.3), `http` (^1.6.0), `url_launcher` (^6.3.0), `share_plus` (^10.1.2)
- **Mídia & Formulários**: `image_picker` (^1.1.2), `mask_text_input_formatter` (^2.9.0)
- **Interface & Redes Sociais**: `flutter_social_button` (^1.1.6), `cupertino_icons` (^1.0.8), `web` (^1.1.0)

## 🛠️ Comandos de Build, Teste e Qualidade
- **Executar o projeto**:
  ```bash
  flutter run
  ```
- **Executar testes unitários e de widget**:
  ```bash
  flutter test
  ```
- **Análise estática (Lint)**:
  ```bash
  flutter analyze
  ```
- **Build para Produção (Web)**:
  ```bash
  flutter build web
  ```
