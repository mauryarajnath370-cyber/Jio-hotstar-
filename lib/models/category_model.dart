class CategoryModel {
  final String id;
  final String name;
  final bool isPaid;
  final int order;
  final bool isAdult;

  CategoryModel({
    required this.id,
    required this.name,
    this.isPaid = false,
    this.order = 0,
    this.isAdult = false,
  });

  factory CategoryModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return CategoryModel(
      id: id,
      name: map['name']?.toString() ?? '',
      isPaid: map['isPaid'] == true,
      order: (map['order'] is int) ? map['order'] as int : int.tryParse(map['order']?.toString() ?? '0') ?? 0,
      isAdult: map['isAdult'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isPaid': isPaid,
      'order': order,
      'isAdult': isAdult,
    };
  }
}
