import 'package:flutter/material.dart';

class FurPalsColors {
  static const blush       = Color(0xFFF9C8D0);
  static const peach       = Color(0xFFFFD9C0);
  static const mint        = Color(0xFFC5EDD6);
  static const lavender    = Color(0xFFDDD0F5);
  static const butter      = Color(0xFFFFF3C4);
  static const cream       = Color(0xFFFFF8F2);
  static const warmWhite   = Color(0xFFFFFAF6);
  static const textDark    = Color(0xFF4A3728);
  static const textMid     = Color(0xFF7A6055);
  static const textSoft    = Color(0x33000000);
  static const pink        = Color(0xFFF4738A);
  static const pinkLight   = Color(0xFFFF9AB0);
  static const green       = Color(0xFF5DB87A);
  static const purple      = Color(0xFF8B6FD4);
  static const shadow      = Color(0x20B47864);
  static const creamwhite  = Color(0xFFF9E9D5);
  static const blue        = Color(0xFF448AFF);
  static const heartRed    = Color(0xFFE53935);
  static const onlineGreen = Color(0xFF4CAF50);
  static const offlineGray = Color(0xFFBDBDBD);
}

const appBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.5, 1.0],
  colors: [Color(0xFFFCDDE8), Color(0xFFFFE8D2), Color(0xFFD4F0E4)],
);

// ─── MODELS ──────────────────────────────────────────────────
class VaccinationRecord {
  String name, date, status;
  VaccinationRecord({required this.name, required this.date, required this.status});
}

class Pet {
  int id;
  String emoji, name, breed, gender, age, weight, vet, notes;
  bool online;
  List<VaccinationRecord> vaccinations;
  Pet({
    required this.id, required this.emoji, required this.name,
    required this.breed, required this.gender, required this.age,
    required this.weight, required this.vet, required this.notes,
    required this.online, required this.vaccinations,
  });
}

class LostPet {
  String id;
  String type; // DOG, CAT, BIRD, OTHER
  String name;
  String breed;
  String? gender;
  String? weight;
  String? age;
  String location;
  String description;
  List<String> photoUrls; // For storing Firebase Storage URLs
  DateTime createdAt;
  DateTime? dateMissing; // When the pet went missing
  String userId; // ID of the user who reported
  String posterName; // Full name of the user who reported

  LostPet({
    required this.id,
    required this.type,
    required this.name,
    required this.breed,
    this.gender,
    this.weight,
    this.age,
    required this.location,
    required this.description,
    required this.photoUrls,
    required this.createdAt,
    this.dateMissing,
    required this.userId,
    required this.posterName,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'breed': breed,
      'gender': gender,
      'weight': weight,
      'age': age,
      'location': location,
      'description': description,
      'photoUrls': photoUrls,
      'createdAt': createdAt.toIso8601String(),
      'dateMissing': dateMissing?.toIso8601String(),
      'userId': userId,
      'posterName': posterName,
    };
  }

  // Create from Firestore document
  factory LostPet.fromMap(String id, Map<String, dynamic> map) {
    return LostPet(
      id: id,
      type: map['type'] ?? '',
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      gender: map['gender'],
      weight: map['weight'],
      age: map['age'],
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      dateMissing: map['dateMissing'] != null ? DateTime.parse(map['dateMissing']) : null,
      userId: map['userId'] ?? '',
      posterName: map['posterName'] ?? '',
    );
  }
}

class Appointment {
  String id;
  int petId;
  String title, vet, date, time, type, notes, status, ownerId;
  Appointment({
    required this.id,
    required this.petId,
    required this.title,
    required this.vet,
    required this.date,
    required this.time,
    required this.type,
    required this.notes,
    required this.status,
    required this.ownerId,
  });
}

class EventMember {
  final String id;
  final String name;
  final String emoji;
  final String joinedDate;

  EventMember({
    required this.id,
    required this.name,
    required this.emoji,
    required this.joinedDate,
  });

  factory EventMember.fromMap(Map<String, dynamic> map) {
    return EventMember(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Friend',
      emoji: map['emoji'] ?? '🐾',
      joinedDate: map['joinedDate'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'joinedDate': joinedDate,
    };
  }
}

class PetEvent {
  final String id;
  final String emoji;
  final String title;
  final String location;
  final String date;
  final String time;
  final String category;
  final String description;
  final Color color1;
  final Color color2;
  final String? photoPath;
  final String? photoUrl;
  final bool isOwner;
  final String ownerName;
  final String ownerEmoji;
  final String ownerId;
  List<EventMember> members;

  PetEvent({
    required this.id,
    required this.emoji,
    required this.title,
    required this.location,
    required this.date,
    required this.time,
    required this.category,
    required this.description,
    required this.color1,
    required this.color2,
    this.photoPath,
    this.photoUrl,
    this.isOwner = false,
    this.ownerName = '',
    this.ownerEmoji = '🐾',
    required this.ownerId,
    List<EventMember>? members,
  }) : members = members ?? [];

  PetEvent copyWith({
    List<EventMember>? members,
  }) {
    return PetEvent(
      id: id,
      emoji: emoji,
      title: title,
      location: location,
      date: date,
      time: time,
      category: category,
      description: description,
      color1: color1,
      color2: color2,
      photoPath: photoPath,
      photoUrl: photoUrl,
      isOwner: isOwner,
      ownerName: ownerName,
      ownerEmoji: ownerEmoji,
      ownerId: ownerId,
      members: members ?? this.members,
    );
  }
}