class Section {
  final String sectionName;
  final int goalBpm;

  Section({required this.sectionName, required this.goalBpm});
}

class Piece {
  final String pieceId;
  final String pieceName;
  final List<Section> sections;

  Piece({
    required this.pieceId,
    required this.pieceName,
    required this.sections,
  });
}
