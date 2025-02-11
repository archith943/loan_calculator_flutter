// config_model.dart
class ConfigItem {
  final String name;
  final dynamic value; // Can be double or String, depending on the API field
  final String label;
  final String placeholder;
  final String tooltip;

  ConfigItem({
    required this.name,
    required this.value,
    required this.label,
    required this.placeholder,
    required this.tooltip,
  });

  factory ConfigItem.fromJson(Map<String, dynamic> json) {
    return ConfigItem(
      name: json['name'],
      value: json['value'], // Can handle both String and double values
      label: json['label'] ?? '',
      placeholder: json['placeholder'] ?? '',
      tooltip: json['tooltip'] ?? '',
    );
  }
}
