import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:summer_iub_app/models/coffee_records_model.dart';
import 'package:summer_iub_app/utility/constant.dart';

class CoffeeStateManagement with ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Local (in memory) list — kept from the earlier classes so the offline
  // screen still works exactly as it did before.
  // ---------------------------------------------------------------------------
  List<CoffeeRecordsModel> items = [];

  // ---------------------------------------------------------------------------
  // Firebase
  // ---------------------------------------------------------------------------
  final bool firebaseEnabled;
  FirebaseFirestore? _firestore;

  CoffeeStateManagement({this.firebaseEnabled = true}) {
    if (firebaseEnabled) {
      _firestore = FirebaseFirestore.instance;
    }
  }

  FirebaseFirestore get _effectiveFirestore {
    if (!firebaseEnabled) {
      throw StateError('Firebase is not configured.');
    }
    return _firestore ??= FirebaseFirestore.instance;
  }

  /// The `coffee_records` collection in Firestore.
  CollectionReference<Map<String, dynamic>> get coffeeRecordsCollection =>
      _effectiveFirestore.collection(AppConstant.coffeeRecordsCollection);

  /// Set while a write is in flight, so screens can show a spinner.
  bool isSaving = false;

  /// Last error message from a Firebase call, or null when everything is fine.
  String? errorMessage;

  void _setSaving(bool value) {
    isSaving = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // READ — real time
  // ---------------------------------------------------------------------------

  /// Raw snapshots, ordered newest first. Feed this straight into a
  /// `StreamBuilder<QuerySnapshot<Map<String, dynamic>>>`.
  Stream<QuerySnapshot<Map<String, dynamic>>> get coffeeRecordsSnapshots {
    if (!firebaseEnabled) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.error(
        'Firebase is not configured. Please update firebase_options.dart with your Firebase project values.',
      );
    }

    return coffeeRecordsCollection
        .orderBy("date", descending: true)
        .snapshots();
  }

  /// The same stream, already mapped into model objects.
  Stream<List<CoffeeRecordsModel>> get coffeeRecordsStream =>
      coffeeRecordsSnapshots.map(
        (snapshot) =>
            snapshot.docs
                .map(
                  (doc) => CoffeeRecordsModel.fromJson(
                    doc.data(),
                  ).copyWith(docId: doc.id),
                )
                .toList(),
      );

  // ---------------------------------------------------------------------------
  // READ — one time
  // ---------------------------------------------------------------------------

  /// Reads the collection once (no live updates) and refreshes [items].
  Future<List<CoffeeRecordsModel>> fetchCoffeeRecordsOnce() async {
    if (!firebaseEnabled) {
      errorMessage = 'Firebase is not configured.';
      notifyListeners();
      return [];
    }

    try {
      final snapshot =
          await coffeeRecordsCollection.orderBy("date", descending: true).get();

      items =
          snapshot.docs
              .map(
                (doc) => CoffeeRecordsModel.fromJson(
                  doc.data(),
                ).copyWith(docId: doc.id),
              )
              .toList();

      errorMessage = null;
      notifyListeners();
      return items;
    } catch (e) {
      errorMessage = "Could not load coffee records: $e";
      notifyListeners();
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------

  /// Sends one record to Firestore. Returns the new document id, or null on
  /// failure (check [errorMessage] in that case).
  Future<String?> sendCoffeeRecordToFirebase(
    CoffeeRecordsModel coffeeRecord,
  ) async {
    if (!firebaseEnabled) {
      errorMessage = 'Firebase is not configured.';
      notifyListeners();
      return null;
    }

    _setSaving(true);
    try {
      final docRef = await coffeeRecordsCollection.add(coffeeRecord.toJson());

      // Store the document id inside the document too, so it round-trips.
      await docRef.update({"docId": docRef.id});

      errorMessage = null;
      return docRef.id;
    } catch (e) {
      errorMessage = "Could not save the coffee record: $e";
      return null;
    } finally {
      _setSaving(false);
    }
  }

  /// Convenience wrapper used by the create screen — builds the model from the
  /// form values and writes it straight to Firestore.
  Future<String?> createCoffeeRecord({
    required String title,
    required String des,
    required double? amount,
  }) {
    final record = CoffeeRecordsModel(
      id: DateTime.now().microsecondsSinceEpoch,
      title: title,
      des: des,
      amount: amount,
      date: DateTime.now(),
    );
    return sendCoffeeRecordToFirebase(record);
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------

  /// Overwrites an existing document. [docId] must come from Firestore.
  Future<bool> updateCoffeeRecord(CoffeeRecordsModel coffeeRecord) async {
    if (!firebaseEnabled) {
      errorMessage = 'Firebase is not configured.';
      notifyListeners();
      return false;
    }

    final docId = coffeeRecord.docId;
    if (docId == null || docId.isEmpty) {
      errorMessage = "This record has no document id, so it cannot be updated.";
      notifyListeners();
      return false;
    }

    _setSaving(true);
    try {
      await coffeeRecordsCollection.doc(docId).update(coffeeRecord.toJson());
      errorMessage = null;
      return true;
    } catch (e) {
      errorMessage = "Could not update the coffee record: $e";
      return false;
    } finally {
      _setSaving(false);
    }
  }

  /// Updates only the fields the user actually edited.
  Future<bool> updateCoffeeRecordFields({
    required String docId,
    String? title,
    String? des,
    double? amount,
  }) async {
    if (!firebaseEnabled) {
      errorMessage = 'Firebase is not configured.';
      notifyListeners();
      return false;
    }

    _setSaving(true);
    try {
      final data = <String, dynamic>{};
      if (title != null) data["title"] = title;
      if (des != null) data["des"] = des;
      if (amount != null) data["amount"] = amount;

      if (data.isNotEmpty) {
        await coffeeRecordsCollection.doc(docId).update(data);
      }
      errorMessage = null;
      return true;
    } catch (e) {
      errorMessage = "Could not update the coffee record: $e";
      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  Future<bool> deleteCoffeeRecord(String docId) async {
    if (!firebaseEnabled) {
      errorMessage = 'Firebase is not configured.';
      notifyListeners();
      return false;
    }

    _setSaving(true);
    try {
      await coffeeRecordsCollection.doc(docId).delete();
      errorMessage = null;
      return true;
    } catch (e) {
      errorMessage = "Could not delete the coffee record: $e";
      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Local-only helpers (unchanged from the earlier classes)
  // ---------------------------------------------------------------------------

  void addData() {
    items.add(
      CoffeeRecordsModel(
        id: DateTime.now().microsecondsSinceEpoch,
        title: "Coffee Record ${items.length + 1}",
        des: "Details about Coffee Record ${items.length + 1}",
        amount: 10.0,
        date: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  void addCoffeeRecord(CoffeeRecordsModel coffeeRecord) {
    items.add(
      CoffeeRecordsModel(
        id: DateTime.now().microsecondsSinceEpoch,
        title: coffeeRecord.title,
        des: coffeeRecord.des,
        amount: coffeeRecord.amount,
        date: coffeeRecord.date,
      ),
    );
    notifyListeners();
  }
}
