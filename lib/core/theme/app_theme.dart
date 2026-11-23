import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      error: AppColors.error,
    );

    const textStylePadrao = TextStyle(
      inherit: true,
      fontFamily: 'Quicksand',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textDark,
    );

    return ThemeData(
      useMaterial3: true,

      // Fonte padrão da aplicação.
      fontFamily: 'Quicksand',

      // Cores principais.
      colorScheme: colorScheme,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,

      // Configuração global dos textos.
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          inherit: true,
          fontFamily: 'Quicksand',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textDark,
        ),
        bodyLarge: TextStyle(
          inherit: true,
          fontFamily: 'Quicksand',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textDark,
        ),
        labelLarge: textStylePadrao,
      ),

      // Padronização dos botões elevados.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          textStyle: textStylePadrao,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Botões de texto.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          textStyle: textStylePadrao,
        ),
      ),

      // Botões com contorno.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          textStyle: textStylePadrao,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
