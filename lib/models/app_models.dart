import 'package:flutter/material.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final String imageUrl;
  final String? price;
  final bool isFree;
  final int duration; // بالدقائق
  final double rating;
  final int studentsCount;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.imageUrl,
    this.price,
    this.isFree = false,
    required this.duration,
    this.rating = 0.0,
    this.studentsCount = 0,
    required this.category,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      instructor: json['instructor'],
      imageUrl: json['imageUrl'],
      price: json['price'],
      isFree: json['isFree'] ?? false,
      duration: json['duration'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      studentsCount: json['studentsCount'] ?? 0,
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructor': instructor,
      'imageUrl': imageUrl,
      'price': price,
      'isFree': isFree,
      'duration': duration,
      'rating': rating,
      'studentsCount': studentsCount,
      'category': category,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Department {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<Course> courses;
  final Color color;

  Department({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.courses = const [],
    required this.color,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      courses:
          (json['courses'] as List?)?.map((e) => Course.fromJson(e)).toList() ??
              [],
      color: Color(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'courses': courses.map((e) => e.toJson()).toList(),
      'color': color.value,
    };
  }
}

class Project {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? demoUrl;
  final String? githubUrl;
  final List<String> technologies;
  final String? difficulty; // 'easy' | 'medium' | 'advanced'
  final List<String> examples;
  final List<String> howToWrite;
  final String? whatsappMessage;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.demoUrl,
    this.githubUrl,
    this.technologies = const [],
    this.difficulty,
    this.examples = const [],
    this.howToWrite = const [],
    this.whatsappMessage,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      demoUrl: json['demoUrl'],
      githubUrl: json['githubUrl'],
      technologies: List<String>.from(json['technologies'] ?? []),
      difficulty: json['difficulty'],
      examples: List<String>.from(json['examples'] ?? []),
      howToWrite: List<String>.from(json['howToWrite'] ?? []),
      whatsappMessage: json['whatsappMessage'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'demoUrl': demoUrl,
      'githubUrl': githubUrl,
      'technologies': technologies,
      'difficulty': difficulty,
      'examples': examples,
      'howToWrite': howToWrite,
      'whatsappMessage': whatsappMessage,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final DateTime createdAt;
  final List<String> enrolledCourses;
  final List<String> favoriteCourses;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    required this.createdAt,
    this.enrolledCourses = const [],
    this.favoriteCourses = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      enrolledCourses: List<String>.from(json['enrolledCourses'] ?? []),
      favoriteCourses: List<String>.from(json['favoriteCourses'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'enrolledCourses': enrolledCourses,
      'favoriteCourses': favoriteCourses,
    };
  }
}

class CourseProgress {
  final String courseId;
  final String userId;
  final double progress; // 0.0 to 1.0
  final DateTime lastAccessed;
  final int watchedVideos;
  final int totalVideos;

  CourseProgress({
    required this.courseId,
    required this.userId,
    this.progress = 0.0,
    required this.lastAccessed,
    this.watchedVideos = 0,
    this.totalVideos = 0,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['courseId'],
      userId: json['userId'],
      progress: (json['progress'] ?? 0.0).toDouble(),
      lastAccessed: DateTime.parse(json['lastAccessed']),
      watchedVideos: json['watchedVideos'] ?? 0,
      totalVideos: json['totalVideos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'userId': userId,
      'progress': progress,
      'lastAccessed': lastAccessed.toIso8601String(),
      'watchedVideos': watchedVideos,
      'totalVideos': totalVideos,
    };
  }

  int get progressPercentage => (progress * 100).round();
}
