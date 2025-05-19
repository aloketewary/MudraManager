/// Defines how a [T] can be backed up and restored.
abstract class BackupAdapter<T> {
  /// Serializes the model to JSON.
  /// The result will be stored directly in the backup file.
  Map<String, dynamic> toBackupJson();

  /// Deserializes the model from JSON.
  /// [linkedRefs] is a map of all objects that are referenced by this model.
  T fromBackupJson(Map<String, dynamic> json, Map<String, dynamic> linkedRefs);
}
