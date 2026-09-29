import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/session.dart';

/// Colors of a session-type chip (calendar.component.css `.type-*`).
class ChipColors {
  const ChipColors(this.background, this.foreground, this.accent, [this.background2]);

  final Color background;
  final Color foreground;
  final Color accent;
  final Color? background2;
}

extension SessionTypeStyle on SessionType {
  ChipColors get colors => switch (this) {
        SessionType.therapy => const ChipColors(
            SessionColors.therapyBg, SessionColors.therapyFg, SessionColors.therapyAccent, SessionColors.therapyBg2),
        SessionType.cognitive => const ChipColors(
            SessionColors.cognitiveBg, SessionColors.cognitiveFg, SessionColors.cognitiveAccent, SessionColors.cognitiveBg2),
        SessionType.physical => const ChipColors(
            SessionColors.physicalBg, SessionColors.physicalFg, SessionColors.physicalAccent, SessionColors.physicalBg2),
        SessionType.creative => const ChipColors(
            SessionColors.creativeBg, SessionColors.creativeFg, SessionColors.creativeAccent, SessionColors.creativeBg2),
        SessionType.general => const ChipColors(
            SessionColors.generalBg, SessionColors.generalFg, SessionColors.generalAccent, SessionColors.generalBg2),
      };
}

extension SessionStatusStyle on SessionStatus {
  /// Consultation calendar status chip (planned / done / default).
  ChipColors get plannedColors => switch (this) {
        SessionStatus.scheduled =>
          const ChipColors(SessionColors.plannedBg, SessionColors.plannedFg, SessionColors.plannedBorder),
        SessionStatus.done => const ChipColors(SessionColors.doneBg, SessionColors.doneFg, SessionColors.doneBorder),
        _ => const ChipColors(SessionColors.defaultBg, SessionColors.defaultFg, SessionColors.defaultBorder),
      };

  /// Reservation status chip (pending / accepted / refused / finished).
  ChipColors get reservationColors => switch (this) {
        SessionStatus.draft => const ChipColors(SessionColors.pendingBg, SessionColors.pendingFg, SessionColors.pendingFg),
        SessionStatus.scheduled =>
          const ChipColors(SessionColors.acceptedBg, SessionColors.acceptedFg, SessionColors.acceptedFg),
        SessionStatus.cancelled =>
          const ChipColors(SessionColors.refusedBg, SessionColors.refusedFg, SessionColors.refusedFg),
        SessionStatus.done => const ChipColors(SessionColors.finishedBg, SessionColors.finishedFg, SessionColors.finishedFg),
      };

  String get plannedLabel => switch (this) {
        SessionStatus.scheduled => 'Planifiee',
        SessionStatus.done => 'Terminee',
        _ => label,
      };
}
