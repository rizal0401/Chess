enum BotDifficulty {
  beginner(
    label: 'Beginner',
    skillLevel: 0,
    maxDepth: 1,
    elo: 1000,
    description: 'Makes quick basic moves, occasionally blunders.',
  ),
  easy(
    label: 'Easy',
    skillLevel: 5,
    maxDepth: 3,
    elo: 1300,
    description: 'Casual level, plays basic chess principles.',
  ),
  medium(
    label: 'Medium',
    skillLevel: 10,
    maxDepth: 5,
    elo: 1600,
    description: 'Solid club player level.',
  ),
  hard(
    label: 'Hard',
    skillLevel: 15,
    maxDepth: 8,
    elo: 2000,
    description: 'Advanced tactical player.',
  ),
  master(
    label: 'Master',
    skillLevel: 20,
    maxDepth: 12,
    elo: 2800,
    description: 'Full engine power, near flawless play.',
  );

  final String label;
  final int skillLevel;
  final int maxDepth;
  final int elo;
  final String description;

  const BotDifficulty({
    required this.label,
    required this.skillLevel,
    required this.maxDepth,
    required this.elo,
    required this.description,
  });
}
