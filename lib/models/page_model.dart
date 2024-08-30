// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/// Represents a page on the [Information] page
class PageModel {
  /// The title of the [PageModel]
  final String title;

  /// The description of the [PageModel]
  final String description;

  /// The SVG icon url of the [PageModel]
  final String icon;

  /// The body of the [PageModel]
  final String body;

  /// The group id of the [PageModel]
  final int group;

  /// The category of the [PageModel]
  final String category;

  PageModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.body,
    required this.group,
    required this.category,
  });

  bool get isExternal => Uri.tryParse(body)?.host.isNotEmpty ?? false;

  Uri get externalUri => Uri.parse(body);

  PageModel copyWith({
    String? title,
    String? description,
    String? icon,
    String? body,
    int? group,
    String? category,
  }) {
    return PageModel(
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      body: body ?? this.body,
      group: group ?? this.group,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'icon': icon,
      'body': body,
      'group': group,
      'category': category,
    };
  }

  factory PageModel.fromMap(Map<String, dynamic> map) {
    return PageModel(
      title: map['title'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String,
      body: map['body'] as String,
      group: map['group'] as int,
      category: (map['category'] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PageModel.fromJson(String source) =>
      PageModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PageModel(title: $title, description: $description, icon: '
        '$icon, body: $body, group: $group, category: $category)';
  }

  @override
  bool operator ==(covariant PageModel other) {
    if (identical(this, other)) return true;

    return other.title == title &&
        other.description == description &&
        other.icon == icon &&
        other.body == body &&
        other.group == group &&
        other.category == category;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        description.hashCode ^
        icon.hashCode ^
        body.hashCode ^
        group.hashCode ^
        category.hashCode;
  }
}
