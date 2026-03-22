import 'package:flutter/material.dart';

/// Colori fissi del brand PartVault.
/// Il resto della palette viene generato automaticamente da Material 3
/// a partire da [brandSeed] tramite [ColorScheme.fromSeed].
abstract final class AppColors {
  /// Colore seme che guida l'intera generazione della palette M3.
  /// Teal scuro tecnico → genera primari vividi in dark, sobri in light.
  static const Color brandSeed = Color(0xFF006874);

  /// Usato per badge di avviso o highlight secondari (non nei ruoli M3).
  static const Color warningAmber = Color(0xFFFFC107);

  /// Colore placeholder per immagini mancanti.
  static const Color imagePlaceholder = Color(0xFF37474F);
}
