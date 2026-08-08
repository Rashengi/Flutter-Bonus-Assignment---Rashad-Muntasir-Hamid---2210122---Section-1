import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:summer_iub_app/models/coffee_records_model.dart';
import 'package:summer_iub_app/state_management/coffee_state_management.dart';
import 'package:summer_iub_app/utility/vlaidators.dart';
import 'package:summer_iub_app/widgets/app_backgroud_design_widget.dart';
import 'package:summer_iub_app/widgets/core_input_widget.dart';

/// Now a StatefulWidget so the TextEditingControllers survive rebuilds and can
/// be disposed properly. On save the record goes to Firestore, and a copy is
/// kept in the local list so the offline screen stays in sync.
class CreateCoffeeRecordScreen extends StatefulWidget {
  const CreateCoffeeRecordScreen({super.key});

  @override
  State<CreateCoffeeRecordScreen> createState() =>
      _CreateCoffeeRecordScreenState();
}

class _CreateCoffeeRecordScreenState extends State<CreateCoffeeRecordScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!formKey.currentState!.validate()) return;

    final csm = Provider.of<CoffeeStateManagement>(context, listen: false);

    final CoffeeRecordsModel newRecord = CoffeeRecordsModel(
      id: DateTime.now().microsecondsSinceEpoch,
      title: titleController.text.trim(),
      des: descriptionController.text.trim(),
      amount: double.tryParse(amountController.text) ?? 0.0,
      date: DateTime.now(),
    );

    // ---- Send to Firebase -------------------------------------------------
    final docId = await csm.sendCoffeeRecordToFirebase(newRecord);

    if (!mounted) return;

    if (docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(csm.errorMessage ?? "Could not save to Firebase."),
        ),
      );
      return;
    }

    // ---- Keep the local list in sync too ----------------------------------
    csm.addCoffeeRecord(newRecord.copyWith(docId: docId));

    titleController.clear();
    amountController.clear();
    descriptionController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Coffee record saved to Firebase.")),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Coffee Record",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.00),
        ),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: AppBackgroudDesignWidget(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                CoreInputWidget(
                  controller: titleController,
                  labelText: "Title",
                  validator: CustomValidators.validateTitle,
                ),

                const SizedBox(height: 20.00),

                CoreInputWidget(
                  controller: amountController,
                  labelText: "Amount",
                  keyboardType: TextInputType.number,
                  validator: CustomValidators.validateAmount,
                ),

                const SizedBox(height: 20.00),

                CoreInputWidget(
                  controller: descriptionController,
                  labelText: "Description",
                  keyboardType: TextInputType.multiline,
                  maxLine: 5,
                  validator: CustomValidators.validateDescreption,
                ),

                const Spacer(),

                // Rebuilds while a write is in flight so the button can show
                // a spinner and block double taps.
                Consumer<CoffeeStateManagement>(
                  builder: (context, csm, _) {
                    return ElevatedButton.icon(
                      onPressed: csm.isSaving ? null : _saveRecord,
                      label: Text(
                        csm.isSaving ? "Saving..." : "Save Coffee Record",
                        style: const TextStyle(
                          fontSize: 18.00,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: csm.isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save, size: 30.00),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50.00),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50.00,
                          vertical: 15.00,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
