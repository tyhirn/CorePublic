// ignore_for_file: file_names,, non_constant_identifier_names
class MLWeights {
  Map weights;
  Map? stdWeights;
  String MLID;
  String userID;
  DateTime? createdAt;

  MLWeights({
    required this.weights,
    required this.MLID,
    required this.userID,
    this.stdWeights,
    this.createdAt,
  });

  @override
  String toString() {
    return weights.toString();
  }
}
