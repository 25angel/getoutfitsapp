class ClothingItem {
  final String imageUrl;
  final String category;
  final String? color;
  final String? season;
  final String? style;
  final String? function;
  final String? brand;
  final bool isWish;

  ClothingItem({
    required this.imageUrl,
    required this.category,
    this.color,
    this.season,
    this.style,
    this.function,
    this.brand,
    this.isWish = false,
  });
}
