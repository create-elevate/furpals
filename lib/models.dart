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

class Appointment {
  int id, petId;
  String title, vet, date, time, type, notes, status;
  Appointment({
    required this.id, required this.petId, required this.title,
    required this.vet, required this.date, required this.time,
    required this.type, required this.notes, required this.status,
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
}

class PetEvent {
  final int id;
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
  final bool isOwner;
  final String ownerName;
  final String ownerEmoji;
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
    this.isOwner = false,
    this.ownerName = '',
    this.ownerEmoji = '🐾',
    List<EventMember>? members,
  }) : members = members ?? [];
}