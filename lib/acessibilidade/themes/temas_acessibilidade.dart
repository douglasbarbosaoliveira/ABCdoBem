import 'package:flutter/material.dart';

class TemasAcessibilidade {
  TemasAcessibilidade._();

  // Paleta base do ABC do Bem.
  static const Color _corPrimariaPadrao = Color(0xFF0A6862);
  static const Color _corSecundariaPadrao = Color(0xFF148F77);
  static const Color _fundoPadrao = Color(0xFFF6FAF9);
  static const Color _superficiePadrao = Color(0xFFFFFFFF);
  static const Color _textoPadrao = Color(0xFF102A27);

  // Paleta de alto contraste.
  static const Color _fundoAltoContraste = Color(0xFF000000);
  static const Color _superficieAltoContraste = Color(0xFF121212);
  static const Color _textoAltoContraste = Color(0xFFFFFFFF);
  static const Color _destaqueAltoContraste = Color(0xFFFFEA00);
  static const Color _secundariaAltoContraste = Color(0xFF00E5FF);
  static const Color _bordaAltoContraste = Color(0xFFFFFFFF);

  // Estilo de texto padrão dos botões.
  // inherit: true mantém compatibilidade com TextStyle
  // definido diretamente nos widgets das telas.
  static const TextStyle _estiloBotaoPadrao = TextStyle(
    inherit: true,
    fontFamily: 'Quicksand',
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle _estiloBotaoAltoContraste = TextStyle(
    inherit: true,
    fontFamily: 'Quicksand',
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  static ThemeData temaPadrao() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _corPrimariaPadrao,
      brightness: Brightness.light,
      primary: _corPrimariaPadrao,
      secondary: _corSecundariaPadrao,
      surface: _superficiePadrao,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _textoPadrao,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Quicksand',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _fundoPadrao,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontFamily: 'Quicksand',
          color: _textoPadrao,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Quicksand',
          color: _textoPadrao,
        ),
        labelLarge: _estiloBotaoPadrao,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _superficiePadrao,
        foregroundColor: _textoPadrao,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: _superficiePadrao,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _corPrimariaPadrao,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          textStyle: _estiloBotaoPadrao,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _corPrimariaPadrao,
          minimumSize: const Size(48, 48),
          textStyle: _estiloBotaoPadrao,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _corPrimariaPadrao,
          minimumSize: const Size(48, 48),
          textStyle: _estiloBotaoPadrao,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData temaAltoContraste() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _destaqueAltoContraste,
      onPrimary: Colors.black,
      secondary: _secundariaAltoContraste,
      onSecondary: Colors.black,
      error: Color(0xFFFF5252),
      onError: Colors.black,
      surface: _superficieAltoContraste,
      onSurface: _textoAltoContraste,
      outline: _bordaAltoContraste,
      outlineVariant: Color(0xFFCCCCCC),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Quicksand',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _fundoAltoContraste,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontFamily: 'Quicksand',
          color: _textoAltoContraste,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Quicksand',
          color: _textoAltoContraste,
        ),
        labelLarge: _estiloBotaoAltoContraste,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _fundoAltoContraste,
        foregroundColor: _textoAltoContraste,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: _superficieAltoContraste,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
          side: BorderSide(
            color: _bordaAltoContraste,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _destaqueAltoContraste,
          foregroundColor: Colors.black,
          minimumSize: const Size(48, 48),
          textStyle: _estiloBotaoAltoContraste,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: _bordaAltoContraste,
              width: 1.5,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textoAltoContraste,
          minimumSize: const Size(48, 48),
          textStyle: _estiloBotaoAltoContraste,
          side: const BorderSide(
            color: _bordaAltoContraste,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _destaqueAltoContraste,
          minimumSize: const Size(48, 48),
          textStyle: _estiloBotaoAltoContraste,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _bordaAltoContraste,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: _textoAltoContraste,
      ),
    );
  }
}
