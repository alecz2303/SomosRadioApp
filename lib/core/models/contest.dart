class Contest {
  const Contest({required this.id, required this.title, required this.question, required this.options, this.prize, this.endsAt});
  final int id;
  final String title;
  final String question;
  final Map<String,String> options;
  final String? prize;
  final DateTime? endsAt;

  factory Contest.fromJson(Map<String,dynamic> json) {
    final raw = (json['options'] as Map?)?.cast<String,dynamic>() ?? const {};
    return Contest(id: json['id'] as int, title: json['title']?.toString() ?? '', question: json['question']?.toString() ?? '', options: raw.map((k,v)=>MapEntry(k,v.toString())), prize: json['prize']?.toString(), endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? ''));
  }
}

class ContestEntryResult {
  const ContestEntryResult({required this.alreadyParticipated, required this.isCorrect, required this.isWinner, this.claimCode, this.prize, this.redemptionInstructions, this.claimedAt});
  final bool alreadyParticipated;
  final bool isCorrect;
  final bool isWinner;
  final String? claimCode;
  final String? prize;
  final String? redemptionInstructions;
  final DateTime? claimedAt;

  factory ContestEntryResult.fromJson(Map<String,dynamic> json) => ContestEntryResult(
    alreadyParticipated: json['already_participated'] == true,
    isCorrect: json['is_correct'] == true,
    isWinner: json['is_winner'] == true,
    claimCode: json['claim_code']?.toString(), prize: json['prize']?.toString(),
    redemptionInstructions: json['redemption_instructions']?.toString(),
    claimedAt: DateTime.tryParse(json['claimed_at']?.toString() ?? ''),
  );
}
