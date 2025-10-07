class PopulationCell {
  final String geohash;
  final int pplDensity;

  PopulationCell({required this.geohash, required this.pplDensity});

  factory PopulationCell.fromJson(Map<String, dynamic> json) {
    final data = json['populationDensityData'];
    return PopulationCell(
      geohash: json['geohash'],
      pplDensity: data != null && data['pplDensity'] != null
          ? data['pplDensity']
          : 0,
    );
  }
}
