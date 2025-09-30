class Instructor {
  final String id;
  final String name;
  final String email;
  final String? instituteId;
  final String? specialization;
  final String? imageUrl;
  final DateTime? createdAt;

  Instructor({
    required this.id,
    required this.name,
    required this.email,
    this.instituteId,
    this.specialization,
    this.imageUrl,
    this.createdAt,
  });

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'غير محدد',
      email: json['email']?.toString() ?? '',
      instituteId: json['institute_id']?.toString(),
      specialization: json['specialization']?.toString(),
      imageUrl: json['image_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'institute_id': instituteId,
      'specialization': specialization,
      'image_url': imageUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class InstructorsResponse {
  final List<Instructor> data;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  InstructorsResponse({
    required this.data,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory InstructorsResponse.fromJson(Map<String, dynamic> json) {
    return InstructorsResponse(
      data: (json['data'] as List?)
              ?.map((item) => Instructor.fromJson(item))
              .toList() ??
          [],
      total: json['meta']?['total'] ?? 0,
      perPage: json['meta']?['per_page'] ?? 15,
      currentPage: json['meta']?['current_page'] ?? 1,
      lastPage: json['meta']?['last_page'] ?? 1,
    );
  }
}
