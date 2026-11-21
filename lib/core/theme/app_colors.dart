import 'package:flutter/material.dart';

enum NovaRegionTone {
  pink,
  mint,
  peach,
  yellow,
  blue,
  purple,
  lime,
  coral,
  indigo,
  rose,
}

typedef RegionPalette = ({Color top, Color bottom, Color edge});

abstract final class AppColors {
  static const primary = Color(0xFF7138DC);
  static const primaryLight = Color(0xFF7C48EB);
  static const primaryDark = Color(0xFF6833D5);
  static const primaryEdge = Color(0xFFDDC8FF);
  static const background = Color(0xFFF4F2FC);
  static const backgroundDecor = Color(0xFFEEEAFA);
  static const heroLavender = Color(0xFFECE8FF);
  static const heroBlue = Color(0xFFE3E8FE);
  static const heroPink = Color(0xFFF6EBFB);
  static const heroOrb = Color(0x80F6F3FF);
  static const heroViolet = Color(0xFFDAD5FE);
  static const heroBlush = Color(0x70F5E0FA);
  static const decorStar = Color(0xFFCDB1F1);
  static const wordmarkAccent = Color(0xFF8E71DF);
  static const decorMint = Color(0xFFA2DDCF);
  static const decorGold = Color(0xFFFFD58E);
  static const characterGround = Color(0xFFD9DDF8);
  static const text = Color(0xFF242038);
  static const secondaryText = Color(0xFF635D74);
  static const surface = Color(0xFFFFFFFF);
  static const transparent = Color(0x00000000);
  static const border = Color(0xFFEAE6F1);
  static const pill = Color(0xFFEFE8FA);
  static const segmentTrack = Color(0xFFE8E0F5);
  static const disabled = Color(0xFFE8E3EF);
  static const disabledText = Color(0xFF746C82);
  static const heart = Color(0xFFEC7CAA);
  static const heartEmpty = Color(0xFFE3DFEB);
  static const success = Color(0xFF235F52);
  static const successSurface = Color(0xFFDEF4EB);
  static const error = Color(0xFF9A3658);
  static const errorSurface = Color(0xFFFDE6F0);
  static const mistakeFlash = Color(0xFFFF6B63);
  static const hintSurface = Color(0xFFFFF2D1);
  static const overlay = Color(0x66242038);
  static const shadow = Color(0x14242038);
  static const focus = primary;
  static const gridHighlight = surface;
  static const cellSheen = Color(0x4DFFFFFF);
  static const regionPatternInk = Color(0x30242038);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryDark],
  );
  static const resultGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [background, heroBlue],
  );
  static const calmGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundDecor, background],
  );
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [heroLavender, heroBlue, heroPink],
    stops: [0, 0.52, 1],
  );

  static const regions = <NovaRegionTone, RegionPalette>{
    NovaRegionTone.pink: (
      top: Color(0xFFFF9EBB),
      bottom: Color(0xFFF88AAD),
      edge: Color(0xFFDC7196),
    ),
    NovaRegionTone.mint: (
      top: Color(0xFF7FE3D3),
      bottom: Color(0xFF66DAC7),
      edge: Color(0xFF4ABDAA),
    ),
    NovaRegionTone.peach: (
      top: Color(0xFFFFC88E),
      bottom: Color(0xFFFFB576),
      edge: Color(0xFFE79A58),
    ),
    NovaRegionTone.yellow: (
      top: Color(0xFFFFE99E),
      bottom: Color(0xFFFFDF7C),
      edge: Color(0xFFE8C46B),
    ),
    NovaRegionTone.blue: (
      top: Color(0xFF97D2FC),
      bottom: Color(0xFF7DC4FC),
      edge: Color(0xFF65ACDD),
    ),
    NovaRegionTone.purple: (
      top: Color(0xFFCEB8FC),
      bottom: Color(0xFFBDA2F1),
      edge: Color(0xFFA489D7),
    ),
    NovaRegionTone.lime: (
      top: Color(0xFFCFE9A2),
      bottom: Color(0xFFB5D782),
      edge: Color(0xFF8DB85A),
    ),
    NovaRegionTone.coral: (
      top: Color(0xFFFFB1A0),
      bottom: Color(0xFFF78F82),
      edge: Color(0xFFDA7168),
    ),
    NovaRegionTone.indigo: (
      top: Color(0xFFAABAFB),
      bottom: Color(0xFF98A7EF),
      edge: Color(0xFF7888CC),
    ),
    NovaRegionTone.rose: (
      top: Color(0xFFF3B8E7),
      bottom: Color(0xFFE69BD8),
      edge: Color(0xFFC17BB5),
    ),
  };
}
