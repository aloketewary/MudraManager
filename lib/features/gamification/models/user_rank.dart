class FinanceRank {
  final int level;
  final String name;
  final String icon;

  const FinanceRank(this.level, this.name, this.icon);

  static FinanceRank getRankForLevel(int level) {
    return financeRanks.lastWhere(
      (r) => level >= r.level,
      orElse: () => financeRanks.first,
    );
  }

  static final financeRanks = FinanceRankRegistry().financeRanks;
}

class FinanceRankRegistry {
  final List<FinanceRank> financeRanks = const [
    // 🟢 Tier 1 — Foundation
    FinanceRank(1, 'Rookie Saver', 'soldier'),
    FinanceRank(2, 'Budget Starter', 'private-pv2'),
    FinanceRank(3, 'Expense Learner', 'private-first-class-pfc'),
    FinanceRank(4, 'Money Cadet', 'corporal'),
    FinanceRank(5, 'Smart Spender', 'corporal-cpl'),

    // 🔵 Tier 2 — Builder
    FinanceRank(6, 'Savings Builder', 'sergeant'),
    FinanceRank(7, 'Cash Manager', 'sergeant-sgt'),
    FinanceRank(8, 'Budget Captain', 'staff-sergeant-ssg'),
    FinanceRank(9, 'Expense Controller', 'sergeant-first-class-sfc'),
    FinanceRank(10, 'Finance Analyst', 'first-sergeant'),

    // 🟠 Tier 3 — Professional
    FinanceRank(11, 'Wealth Planner', 'first-sergeant-1sg'),
    FinanceRank(12, 'Asset Strategist', 'master-sergeant-msg'),
    FinanceRank(13, 'Portfolio Lead', 'sergeant-major-sgt'),
    FinanceRank(14, 'Investment Manager', 'sergeant-major-of-army-sma'),
    FinanceRank(15, 'Capital Director', 'command-sergeant-major-csm'),

    // 🔴 Tier 4 — Leadership
    FinanceRank(16, 'Market Advisor', 'second-lieutenant'),
    FinanceRank(17, 'Fund Supervisor', 'lieutenant'),
    FinanceRank(18, 'Risk Controller', 'sub-lieutenant-of-the-canadian-navy'),
    FinanceRank(19, 'Growth Strategist', 'lieutenant-of-the-canadian-navy'),
    FinanceRank(
      20,
      'Senior Analyst',
      'lieutenant-commander-of-the-canadian-navy',
    ),

    // 🟣 Tier 5 — Executive
    FinanceRank(21, 'Wealth Executive', 'commander-of-the-canadian-navy'),
    FinanceRank(22, 'Capital Governor', 'commodore-of-the-canadian-navy'),
    FinanceRank(23, 'Investment Chief', 'captain'),
    FinanceRank(24, 'Finance Director', 'captain-of-the-canadian-navy'),
    FinanceRank(25, 'Asset Commander', 'captain-general'),

    // 🟨 Tier 6 — Elite
    FinanceRank(26, 'Market Leader', 'major-general'),
    FinanceRank(27, 'Wealth General', 'lieutenant-general'),
    FinanceRank(28, 'Capital Strategist', 'brigadier-general'),
    FinanceRank(29, 'Fund Marshal', 'army-general'),
    FinanceRank(30, 'Economic Overseer', 'colonel'),

    // 👑 Tier 7 — Legendary
    FinanceRank(31, 'Money Architect', 'rear-admiral-of-the-canadian-navy'),
    FinanceRank(32, 'Wealth Visionary', 'vice-admiral-of-the-canadian-navy'),
    FinanceRank(33, 'Investment Titan', 'admiral-of-the-canadian-navy'),
    FinanceRank(34, 'Capital Emperor', 'brigada'),
    FinanceRank(35, 'Financial Overlord', 'comandante'),

    // 🌟 Tier 8 — Mythic
    FinanceRank(36, 'Wealth Sovereign', 'caballero'),
    FinanceRank(37, 'Market Legend', 'cabo'),
    FinanceRank(38, 'Fortune Master', 'lady-cadet'),
    FinanceRank(39, 'Capital Oracle', 'ensign'),
    FinanceRank(40, 'Money Grandmaster', 'lieutenant-colonel'),

    // 🏆 Tier 9 — Ultimate
    FinanceRank(41, 'Wealth Supreme', 'captain-general'),
    FinanceRank(
      42,
      'Financial Titan',
      'acting-sub-lieutenant-of-the-canadian-navy',
    ),
  ];
}
