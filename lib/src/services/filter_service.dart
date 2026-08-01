/// A named cinematic colour-grade. [vf] is the FFmpeg `-vf` filter chain that
/// produces the look (empty for the untouched original).
class CinematicFilter {
  const CinematicFilter(this.name, this.vf);

  final String name;
  final String vf;
}

/// Catalogue of one-tap cinematic filters plus the command that renders them.
///
/// Every look is built from standard FFmpeg colour filters (curves presets,
/// colorbalance, colorlevels, eq, colorchannelmixer, vignette, gblur…) so they
/// run on-device with the bundled FFmpeg — no cloud, no external LUT files.
/// None of the chains contain spaces, keeping the `-vf` argument quoting simple
/// and robust. Command construction is a pure helper so it can be unit tested.
class FilterService {
  static const List<CinematicFilter> cinematicFilters = [
    CinematicFilter('Original', ''),
    // Teal shadows + warm skin — the classic blockbuster grade.
    CinematicFilter(
      'Cinematic',
      'curves=preset=medium_contrast,'
          'colorbalance=rs=-0.05:bs=0.05:rm=0.05:bm=-0.05:rh=0.08:bh=-0.08,'
          'eq=saturation=1.06',
    ),
    // High-contrast black & white.
    CinematicFilter('Noir', 'hue=s=0,curves=preset=strong_contrast'),
    CinematicFilter('Vintage', 'curves=preset=vintage,vignette=PI/5'),
    CinematicFilter('Cross Process', 'curves=preset=cross_process'),
    CinematicFilter(
      'Warm',
      'colorbalance=rm=0.12:gm=0.04:bm=-0.1,eq=saturation=1.12:gamma=1.02',
    ),
    CinematicFilter('Cool', 'colorbalance=rm=-0.1:bm=0.12,eq=saturation=1.05'),
    // Lifted blacks + lowered whites for a faded-film matte.
    CinematicFilter(
      'Faded Film',
      'colorlevels=romin=0.06:gomin=0.06:bomin=0.06:'
          'romax=0.92:gomax=0.92:bomax=0.92,eq=saturation=0.88',
    ),
    CinematicFilter(
      'Vivid',
      'eq=contrast=1.15:saturation=1.35:brightness=0.02,unsharp=5:5:0.6',
    ),
    CinematicFilter(
      'Sepia',
      'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131',
    ),
    CinematicFilter(
      'Sunset',
      'colorbalance=rh=0.12:rm=0.08:bh=-0.1,eq=saturation=1.15:gamma_r=1.05',
    ),
    CinematicFilter(
      'Moody',
      'colorbalance=bs=0.1:bm=0.06,curves=preset=darker,eq=saturation=1.05',
    ),
    CinematicFilter('Dreamy', 'gblur=sigma=1.4,eq=brightness=0.04:saturation=1.1'),
    CinematicFilter('Invert', 'negate'),
  ];

  /// The FFmpeg command that bakes filter chain [vf] into [input], writing
  /// [output]. Audio is copied; only the video is re-encoded.
  static String filterCommand(String input, String output, String vf) =>
      '-y -i $input -vf "$vf" '
      '-c:v libx264 -crf 20 -preset fast -c:a copy $output';
}
