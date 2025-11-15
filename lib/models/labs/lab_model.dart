class LabModel {
  final String id;               
  final String labKode;
  final String labName;
  final String labLocation;
  final String labDescription;
  final int labCapacity;
  final bool isShow;

  LabModel({
    required this.id,
    required this.labKode,
    required this.labName,
    required this.labLocation,
    required this.labDescription,
    required this.labCapacity,
    required this.isShow,
  });

  factory LabModel.fromFirestore(String id, Map<String, dynamic> data) {
    return LabModel(
      id: id,
      labKode: data['lab_kode'] ?? '',
      labName: data['lab_name'] ?? '',
      labLocation: data['lab_location'] ?? '',
      labDescription: data['lab_description'] ?? '',
      labCapacity: data['lab_capacity'] ?? 0,
      isShow: data['is_show'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lab_kode': labKode,
      'lab_name': labName,
      'lab_location': labLocation,
      'lab_description': labDescription,
      'lab_capacity': labCapacity,
      'is_show': isShow,
    };
  }
}
