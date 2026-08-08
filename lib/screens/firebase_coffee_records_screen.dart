import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:summer_iub_app/models/coffee_records_model.dart';
import 'package:summer_iub_app/screens/create_coffee_record_screen.dart';
import 'package:summer_iub_app/state_management/coffee_state_management.dart';
import 'package:summer_iub_app/widgets/app_backgroud_design_widget.dart';
import 'package:summer_iub_app/widgets/core_input_widget.dart';
import 'package:summer_iub_app/utility/vlaidators.dart';

/// Reads the `coffee_records` collection live, using Firestore snapshots
/// wrapped in a StreamBuilder. Anything written from another device (or typed
/// directly into the Firebase console) shows up here without a refresh.
class FirebaseCoffeeRecordsScreen extends StatelessWidget {
  const FirebaseCoffeeRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final csm = Provider.of<CoffeeStateManagement>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Coffee Records (Live)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.00),
        ),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),

      body: AppBackgroudDesignWidget(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: csm.coffeeRecordsSnapshots,
          builder: (context, snapshot) {
            // ---------------------------------------------------- waiting ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.brown),
              );
            }

            // ------------------------------------------------------ error ---
            if (snapshot.hasError) {
              return _MessageView(
                icon: Icons.cloud_off,
                title: "Could not reach Firestore",
                message:
                    "${snapshot.error}\n\nCheck your Firestore rules and that "
                    "firebase_options.dart holds your real project keys.",
              );
            }

            final docs = snapshot.data?.docs ?? [];

            // ------------------------------------------------------ empty ---
            if (docs.isEmpty) {
              return _MessageView(
                icon: Icons.coffee_outlined,
                title: "No coffee records yet",
                message: "Tap the button below to add your first one.",
              );
            }

            // ------------------------------------------------------- data ---
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final CoffeeRecordsModel coffeeRecord =
                    CoffeeRecordsModel.fromJson(doc.data()).copyWith(docId: doc.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.brown,
                      child: Icon(Icons.coffee, color: Colors.white),
                    ),
                    title: Text(
                      coffeeRecord.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(coffeeRecord.des),
                        const SizedBox(height: 4),
                        Text(
                          "Amount: ${coffeeRecord.amount ?? 0}  •  "
                          "${_formatDate(coffeeRecord.date)}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Doc ID: ${coffeeRecord.docId}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: "Edit",
                          icon: const Icon(Icons.edit, color: Colors.brown),
                          onPressed: () => _openEditSheet(
                            context,
                            csm,
                            coffeeRecord,
                          ),
                        ),
                        IconButton(
                          tooltip: "Delete",
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _confirmDelete(
                            context,
                            csm,
                            coffeeRecord,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateCoffeeRecordScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Record"),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}/${date.year} "
      "${date.hour.toString().padLeft(2, '0')}:"
      "${date.minute.toString().padLeft(2, '0')}";

  // ---------------------------------------------------------------- UPDATE --
  void _openEditSheet(
    BuildContext context,
    CoffeeStateManagement csm,
    CoffeeRecordsModel record,
  ) {
    final titleController = TextEditingController(text: record.title);
    final desController = TextEditingController(text: record.des);
    final amountController = TextEditingController(
      text: (record.amount ?? 0).toString(),
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Coffee Record",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 20),
              CoreInputWidget(
                controller: titleController,
                labelText: "Title",
                validator: CustomValidators.validateTitle,
              ),
              const SizedBox(height: 15),
              CoreInputWidget(
                controller: amountController,
                labelText: "Amount",
                keyboardType: TextInputType.number,
                validator: CustomValidators.validateAmount,
              ),
              const SizedBox(height: 15),
              CoreInputWidget(
                controller: desController,
                labelText: "Description",
                keyboardType: TextInputType.multiline,
                maxLine: 3,
                validator: CustomValidators.validateDescreption,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.save),
                label: const Text("Save changes"),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final ok = await csm.updateCoffeeRecord(
                    record.copyWith(
                      title: titleController.text.trim(),
                      des: desController.text.trim(),
                      amount: double.tryParse(amountController.text) ?? 0.0,
                    ),
                  );

                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? "Record updated."
                            : csm.errorMessage ?? "Update failed.",
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- DELETE --
  void _confirmDelete(
    BuildContext context,
    CoffeeStateManagement csm,
    CoffeeRecordsModel record,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete this record?"),
        content: Text(
          "\"${record.title}\" will be removed from Firestore. "
          "This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final ok = await csm.deleteCoffeeRecord(record.docId!);

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? "Record deleted." : csm.errorMessage ?? "Delete failed.",
                  ),
                ),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

/// Shared empty / error placeholder.
class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.brown),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
