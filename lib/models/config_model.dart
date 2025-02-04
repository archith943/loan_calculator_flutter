class ConfigItem {
  final String name;
  final double value; // Change to double for numeric value
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
      value: _parseValue(json['value']), // Call helper function to parse value
      label: json['label'] ?? "",
      placeholder: json['placeholder'] ?? "",
      tooltip: json['tooltip'] ?? "",
    );
  }

  // Helper function to safely parse the value and handle invalid cases
  static double _parseValue(dynamic value) {
    if (value is String) {
      // Try to parse the value as a double, return 0.0 if parsing fails
      return double.tryParse(value) ?? 0.0;
    }
    return value is double
        ? value
        : 0.0; // If it's already a double, use it, otherwise fallback to 0.0
  }
}
