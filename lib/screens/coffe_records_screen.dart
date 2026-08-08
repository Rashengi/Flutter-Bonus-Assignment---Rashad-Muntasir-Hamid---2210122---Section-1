import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:summer_iub_app/models/coffee_records_model.dart';
import 'package:summer_iub_app/state_management/coffee_state_management.dart';
import 'package:summer_iub_app/widgets/app_backgroud_design_widget.dart';

/// The original local (in-memory) list from the earlier classes, plus a
/// "pull from Firebase" action that does a one-time Firestore read.
class CoffeRecordsScreen extends StatefulWidget {
  const CoffeRecordsScreen({super.key});

  @override
  State<CoffeRecordsScreen> createState() => _CoffeRecordsScreenState();
}

class _CoffeRecordsScreenState extends State<CoffeRecordsScreen> {
  // Fixed: this used to be `late Provider<CoffeeStateManagement>` with a cast
  // that throws at runtime. Provider.of returns the value itself.
  late CoffeeStateManagement csm;

  @override
  void initState() {
    super.initState();
    csm = Provider.of<CoffeeStateManagement>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Coffee Records (Local)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.00),
        ),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Load from Firebase",
            icon: const Icon(Icons.cloud_download),
            onPressed: () async {
              await csm.fetchCoffeeRecordsOnce();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    csm.errorMessage ??
                        "Loaded ${csm.items.length} record(s) from Firebase.",
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: Consumer<CoffeeStateManagement>(
        builder: (context, csm, _) {
          return AppBackgroudDesignWidget(
            child: csm.items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Text(
                        "No local records yet.\nTap the cup to add one, or pull "
                        "from Firebase using the cloud icon.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.brown),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    itemCount: csm.items.length,
                    itemBuilder: (context, index) {
                      final CoffeeRecordsModel coffeeRecord = csm.items[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.coffee),
                          title: Text(coffeeRecord.title),
                          subtitle: Text(
                            "${coffeeRecord.des} - Amount: ${coffeeRecord.amount} "
                            "- ID: (${coffeeRecord.id})",
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),

      floatingActionButton: Consumer<CoffeeStateManagement>(
        builder: (context, csm, _) {
          return FloatingActionButton(
            onPressed: () {
              csm.addData();
            },
            child: const Icon(Icons.local_cafe),
          );
        },
      ),
    );
  }
}
