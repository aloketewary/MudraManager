import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FinanceRank {
  final int level;
  final String name;
  final IconData icon;
  final Color accent;

  const FinanceRank(this.level, this.name, this.icon, this.accent);

  static FinanceRank getRankForLevel(int level) {
    return financeRanks.lastWhere(
      (r) => level >= r.level,
      orElse: () => financeRanks.first,
    );
  }

  static final financeRanks = FinanceRankRegistry().financeRanks;
}

class FinanceRankRegistry {
  final List<FinanceRank> financeRanks = [
    // 🌱 Tier 1 — Beginner
    const FinanceRank(
      1,
      'Penny Starter',
      LucideIcons.sprout,
      Color(0xFF8BC34A),
    ),
    const FinanceRank(2, 'Coin Counter', LucideIcons.coins, Color(0xFF8BC34A)),
    const FinanceRank(
      3,
      'Bill Tracker',
      LucideIcons.receipt,
      Color(0xFF8BC34A),
    ),
    const FinanceRank(
      4,
      'Budget Rookie',
      LucideIcons.notebook,
      Color(0xFF8BC34A),
    ),
    const FinanceRank(
      5,
      'Smart Spender',
      LucideIcons.badgeCheck,
      Color(0xFF8BC34A),
    ),

    // 💰 Tier 2 — Saver
    const FinanceRank(
      6,
      'Savings Builder',
      LucideIcons.piggyBank,
      Color(0xFF4CAF50),
    ),
    const FinanceRank(7, 'Cash Keeper', LucideIcons.wallet, Color(0xFF4CAF50)),
    const FinanceRank(
      8,
      'Budget Planner',
      LucideIcons.clipboardList,
      Color(0xFF4CAF50),
    ),
    const FinanceRank(9, 'Expense Hawk', LucideIcons.eye, Color(0xFF4CAF50)),
    const FinanceRank(
      10,
      'Money Manager',
      LucideIcons.briefcase,
      Color(0xFF4CAF50),
    ),

    // 📊 Tier 3 — Analyst
    const FinanceRank(
      11,
      'Wealth Planner',
      LucideIcons.chartLine,
      Color(0xFF2196F3),
    ),
    const FinanceRank(
      12,
      'Asset Tracker',
      LucideIcons.chartBar,
      Color(0xFF2196F3),
    ),
    const FinanceRank(
      13,
      'Portfolio Lead',
      LucideIcons.chartPie,
      Color(0xFF2196F3),
    ),
    const FinanceRank(
      14,
      'Fund Strategist',
      LucideIcons.target,
      Color(0xFF2196F3),
    ),
    const FinanceRank(
      15,
      'Capital Analyst',
      LucideIcons.trendingUp,
      Color(0xFF2196F3),
    ),

    // 🏦 Tier 4 — Professional
    const FinanceRank(
      16,
      'Market Advisor',
      LucideIcons.landmark,
      Color(0xFF9C27B0),
    ),
    const FinanceRank(
      17,
      'Fund Director',
      LucideIcons.building2,
      Color(0xFF9C27B0),
    ),
    const FinanceRank(
      18,
      'Risk Controller',
      LucideIcons.shield,
      Color(0xFF9C27B0),
    ),
    const FinanceRank(
      19,
      'Growth Strategist',
      LucideIcons.rocket,
      Color(0xFF9C27B0),
    ),
    const FinanceRank(
      20,
      'Senior Analyst',
      LucideIcons.award,
      Color(0xFF9C27B0),
    ),

    // 🔥 Tier 5 — Executive
    const FinanceRank(
      21,
      'Wealth Executive',
      LucideIcons.flame,
      Color(0xFFFF5722),
    ),
    const FinanceRank(
      22,
      'Capital Governor',
      LucideIcons.castle,
      Color(0xFFFF5722),
    ),
    const FinanceRank(
      23,
      'Investment Chief',
      LucideIcons.swords,
      Color(0xFFFF5722),
    ),
    const FinanceRank(
      24,
      'Finance Director',
      LucideIcons.star,
      Color(0xFFFF5722),
    ),
    const FinanceRank(
      25,
      'Asset Commander',
      LucideIcons.medal,
      Color(0xFFFF5722),
    ),

    // 💎 Tier 6 — Elite
    const FinanceRank(26, 'Market Leader', LucideIcons.gem, Color(0xFFE91E63)),
    const FinanceRank(
      27,
      'Wealth General',
      LucideIcons.crown,
      Color(0xFFE91E63),
    ),
    const FinanceRank(
      28,
      'Capital Strategist',
      LucideIcons.brain,
      Color(0xFFE91E63),
    ),
    const FinanceRank(
      29,
      'Fund Marshal',
      LucideIcons.trophy,
      Color(0xFFE91E63),
    ),
    const FinanceRank(
      30,
      'Economic Overseer',
      LucideIcons.globe,
      Color(0xFFE91E63),
    ),

    // 👑 Tier 7 — Legendary
    const FinanceRank(
      31,
      'Money Architect',
      LucideIcons.compass,
      Color(0xFFFF9800),
    ),
    const FinanceRank(
      32,
      'Wealth Visionary',
      LucideIcons.telescope,
      Color(0xFFFF9800),
    ),
    const FinanceRank(
      33,
      'Investment Titan',
      LucideIcons.mountain,
      Color(0xFFFF9800),
    ),
    const FinanceRank(
      34,
      'Capital Emperor',
      LucideIcons.eclipse,
      Color(0xFFFF9800),
    ),
    const FinanceRank(
      35,
      'Financial Overlord',
      LucideIcons.sparkles,
      Color(0xFFFF9800),
    ),

    // 🌟 Tier 8 — Mythic
    const FinanceRank(
      36,
      'Wealth Sovereign',
      LucideIcons.sun,
      Color(0xFFFFD600),
    ),
    const FinanceRank(37, 'Market Legend', LucideIcons.zap, Color(0xFFFFD600)),
    const FinanceRank(
      38,
      'Fortune Master',
      LucideIcons.infinity,
      Color(0xFFFFD600),
    ),
    const FinanceRank(
      39,
      'Capital Oracle',
      LucideIcons.orbit,
      Color(0xFFFFD600),
    ),
    const FinanceRank(
      40,
      'Money Grandmaster',
      LucideIcons.hexagon,
      Color(0xFFFFD600),
    ),

    // 🏆 Tier 9 — Ultimate
    const FinanceRank(
      41,
      'Wealth Supreme',
      LucideIcons.diamond,
      Color(0xFFFFD700),
    ),
    const FinanceRank(
      42,
      'Financial Titan',
      LucideIcons.crown,
      Color(0xFFFFD700),
    ),
  ];
}
