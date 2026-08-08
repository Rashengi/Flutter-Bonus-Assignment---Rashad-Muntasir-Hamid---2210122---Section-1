// To parse this JSON data, do
//
//     final coffeeRecordsModel = coffeeRecordsModelFromJson(jsonString);
//
// Generated with https://quicktype.io from the following sample JSON:
//
// {
//   "id": 1754654321000000,
//   "title": "Cappuccino",
//   "des": "Morning cup from the campus cafe",
//   "amount": 180.0,
//   "date": "2026-08-08T09:15:00.000Z"
// }
//
// The generated class was then extended with:
//   * a `docId` field, to keep track of the Firestore document id
//   * a `copyWith` helper, used when Firestore hands back the document id
//   * a tolerant date parser, so both ISO-8601 strings and epoch
//     milliseconds coming back from Firestore are handled safely.

import 'dart:convert';

CoffeeRecordsModel coffeeRecordsModelFromJson(String str) =>
    CoffeeRecordsModel.fromJson(json.decode(str));

String coffeeRecordsModelToJson(CoffeeRecordsModel data) =>
    json.encode(data.toJson());

class CoffeeRecordsModel {
  /// Firestore document id. Null until the record has been written to
  /// (or read back from) Firestore.
  final String? docId;

  final int id;
  final String title;
  final String des;
  final double? amount;
  final DateTime date;

  CoffeeRecordsModel({
    this.docId,
    required this.id,
    required this.title,
    required this.des,
    this.amount,
    required this.date,
  });

  factory CoffeeRecordsModel.fromJson(Map<String, dynamic> json) =>
      CoffeeRecordsModel(
        docId: json["docId"] as String?,
        id: json["id"] is int
            ? json["id"] as int
            : int.tryParse("${json["id"]}") ?? 0,
        title: json["title"]?.toString() ?? "",
        des: json["des"]?.toString() ?? "",
        amount: json["amount"] == null
            ? null
            : double.tryParse("${json["amount"]}"),
        date: _parseDate(json["date"]),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "des": des,
    "amount": amount,
    "date": date.toIso8601String(),
  };

  CoffeeRecordsModel copyWith({
    String? docId,
    int? id,
    String? title,
    String? des,
    double? amount,
    DateTime? date,
  }) => CoffeeRecordsModel(
    docId: docId ?? this.docId,
    id: id ?? this.id,
    title: title ?? this.title,
    des: des ?? this.des,
    amount: amount ?? this.amount,
    date: date ?? this.date,
  );

  /// Firestore may return the date as an ISO-8601 String (what `toJson`
  /// writes), as epoch milliseconds, or as a Timestamp whose `toDate()`
  /// we can call dynamically without importing cloud_firestore here.
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    try {
      // Handles Firestore Timestamp without a hard dependency on it.
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }
}
