import 'package:mudra_manager/backup/backable_model.dart' show BackupAdapter;
import 'package:mudra_manager/db/models/goal.dart' show Goal;

class GoalBackup implements BackupAdapter<Goal> {
  final int id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? targetDate;
  final String creationDate;
  final bool isActive;
  final int? linkedAccountId; // Store linked Account ID

  GoalBackup.fromGoal(Goal goal)
      : id = goal.id,
        name = goal.name,
        targetAmount = goal.targetAmount,
        currentAmount = goal.currentAmount,
        targetDate = goal.targetDate?.toIso8601String(),
        creationDate = goal.creationDate.toIso8601String(),
        isActive = goal.isActive,
        linkedAccountId = goal.linkedAccount.value?.id;

  GoalBackup():
      id = 0,
      name = '',
      targetAmount = 0.0,
      currentAmount = 0.0,
      targetDate = null,
      creationDate = DateTime.now().toIso8601String(),
      isActive = true,
      linkedAccountId = null;

  @override
  Map<String, dynamic> toBackupJson() => {
    'id': id,
    'name': name,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'targetDate': targetDate,
    'creationDate': creationDate,
    'isActive': isActive,
    'linkedAccountId': linkedAccountId,
  };

  @override
  Goal fromBackupJson(Map<String, dynamic> json, Map<String, dynamic> linkedRefs) {
    final goal = Goal()
      ..id = json['id']
      ..name = json['name']
      ..targetAmount = json['targetAmount']
      ..currentAmount = json['currentAmount'] as double? ?? 0.0
      ..targetDate = json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null
      ..creationDate = DateTime.parse(json['creationDate'])
      ..isActive = json['isActive'] as bool? ?? true;

    // Re-link Account
    final accountMap = linkedRefs['Account'] as Map<int, dynamic>?;
    final linkedAccountId = json['linkedAccountId'];
    if (accountMap != null && linkedAccountId != null) {
      goal.linkedAccount.value = accountMap[linkedAccountId];
    }

    return goal;
  }
}