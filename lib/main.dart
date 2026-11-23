import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'acessibilidade/acessibilidade.dart';
import 'core/theme/app_theme.dart';
import 'landing_page.dart';
import 'login/login_page.dart';
import 'register/voluntario/register_step1_page.dart';
import 'register/ong/register_ong_step1_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }

  final acessibilidadeController = AcessibilidadeController.instancia;

  await acessibilidadeController.carregar();

  runApp(
    MyApp(
      acessibilidadeController: acessibilidadeController,
    ),
  );
}

class MyApp extends StatefulWidget {
  final AcessibilidadeController acessibilidadeController;

  const MyApp({
    super.key,
    required this.acessibilidadeController,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _modalAcessibilidadeAberto = false;

  late final VlibrasBridge _vlibrasBridge;

  @override
  void initState() {
    super.initState();

    _vlibrasBridge = criarVlibrasBridge();

    widget.acessibilidadeController.addListener(
      _atualizarVlibras,
    );

    _atualizarVlibras();
  }

  void _atualizarVlibras() {
    _vlibrasBridge.atualizarVisibilidade(
      ativo: widget.acessibilidadeController.vlibrasAtivo,
    );
  }

  Future<void> _abrirModalAcessibilidade() async {
    if (_modalAcessibilidadeAberto) return;

    final navContext = rootNavigatorKey.currentContext;

    if (navContext == null) return;

    setState(() {
      _modalAcessibilidadeAberto = true;
    });

    try {
      await MenuAcessibilidadeModal.exibir(
        navContext,
        controller: widget.acessibilidadeController,
      );
    } finally {
      if (mounted) {
        setState(() {
          _modalAcessibilidadeAberto = false;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.acessibilidadeController.removeListener(
      _atualizarVlibras,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.acessibilidadeController,
      builder: (context, _) {
        final controller = widget.acessibilidadeController;

        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'ABC do Bem',
          debugShowCheckedModeBanner: false,
          themeAnimationDuration: Duration.zero,
          theme: AppTheme.lightTheme,
          darkTheme: TemasAcessibilidade.temaAltoContraste(),
          themeMode:
              controller.altoContraste ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            return WrapperAcessibilidade(
              config: controller.config,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: AppRouter(
            acessibilidadeController: controller,
            onOpenAccessibility: _abrirModalAcessibilidade,
          ),
        );
      },
    );
  }
}

class AppRouter extends StatelessWidget {
  final AcessibilidadeController acessibilidadeController;
  final VoidCallback onOpenAccessibility;

  const AppRouter({
    super.key,
    required this.acessibilidadeController,
    required this.onOpenAccessibility,
  });

  @override
  Widget build(BuildContext context) {
    return LandingPage(
      acessibilidadeController: acessibilidadeController,
      onOpenAccessibility: onOpenAccessibility,
      onLogin: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      },
      onRegisterVolunteer: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RegisterStep1Page(),
          ),
        );
      },
      onRegisterOng: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RegisterOngStep1Page(),
          ),
        );
      },
    );
  }
}
