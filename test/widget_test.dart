import 'package:flutter/material.dart';
import '../service/api_service.dart';
import '../models/config_model.dart';
import '../utils/calculations.dart'; // Import the calculations file

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ConfigItem> configItems = [];
  double revenueAmount = 0.0;
  double loanAmount = 0.0;
  double revenuePercentage = 0.0;
  String repaymentDelay = "30 days"; // Keep this as class member
  String revenueSharedFrequency = "Monthly";
  List<String> useOfFunds = [];

  @override
  void initState() {
    super.initState();
    fetchConfig();
  }

  // Update fetchConfig to handle missing or malformed data
  void fetchConfig() async {
    try {
      configItems = await ApiService.fetchConfig();
      setState(() {
        // Initialize with values from configItems or set default values
        revenueAmount = double.tryParse(configItems.firstWhere(
          (item) => item.name == 'revenueAmount', 
          orElse: () => ConfigItem(name: 'revenueAmount', value: '0', label: '', placeholder: '', tooltip: '')
        ).value) ?? 0.0;

        loanAmount = double.tryParse(configItems.firstWhere(
          (item) => item.name == 'loanAmount', 
          orElse: () => ConfigItem(name: 'loanAmount', value: '0', label: '', placeholder: '', tooltip: '')
        ).value) ?? 0.0;

        // Optionally, initialize other values if needed (e.g., feePercentage, repaymentDelay)
        repaymentDelay = configItems.firstWhere(
          (item) => item.name == 'repaymentDelay',
          orElse: () => ConfigItem(name: 'repaymentDelay', value: '30 days', label: '', placeholder: '', tooltip: '')
        ).value;
      });
    } catch (e) {
      print("Error fetching config: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely get feePercentage from configItems or use a default value
    double feePercentage = double.tryParse(configItems.firstWhere(
      (item) => item.name == 'feePercentage',
      orElse: () => ConfigItem(name: 'feePercentage', value: '0.5', label: '', placeholder: '', tooltip: '')
    ).value) ?? 0.5;

    double fees = Calculations.calculateFees(loanAmount, feePercentage);
    double totalRevenueShare = Calculations.calculateTotalRevenueShare(loanAmount, fees);
    int expectedTransfers = Calculations.calculateExpectedTransfers(
      totalRevenueShare,
      revenueAmount,
      revenuePercentage,
      revenueSharedFrequency,
    );
    DateTime expectedCompletionDate = Calculations.calculateExpectedCompletionDate(
      DateTime.now(),
      expectedTransfers,
      repaymentDelay,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Loan Calculator')),
      body: configItems.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Display loading indicator if config is not yet fetched
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "What is your annual business revenue?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: "\$250,000",
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        revenueAmount = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "What is your desired loan amount?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: loanAmount,
                    min: 0,
                    max: revenueAmount / 3,
                    divisions: 10,
                    label: "\$${loanAmount.round()}",
                    onChanged: (value) {
                      setState(() {
                        loanAmount = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Handle logic here
                    },
                    child: const Text("Submit"),
                  ),
                  const SizedBox(height: 20),
                  Text("Fees: \$${fees.toStringAsFixed(2)}"),
                  Text("Total Revenue Share: \$${totalRevenueShare.toStringAsFixed(2)}"),
                  Text("Expected Transfers: $expectedTransfers"),
                  Text("Expected Completion Date: ${expectedCompletionDate.toLocal()}"),
                ],
              ),
            ),
    );
  }
}
