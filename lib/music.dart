import 'package:mongo_dart/mongo_dart.dart';

class Section {
  final String sectionId;
  final String sectionName;
  final int goalBpm;
  Section({
    required this.sectionId,
    required this.sectionName,
    required this.goalBpm,
  });

  String getSectionId() {
    return this.sectionId;
  }

  String getSectionName() {
    return this.sectionName;
  }



  int getGoalBpm() {
    return this.goalBpm;
  }
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

  String getPieceId() {
    return this.pieceId;
  }

  String getpieceName() {
    return this.pieceName;
  }
  
}
