import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double revenueAmount = 0.0; // Business revenue entered by user
  double loanAmount = 0.0; // Loan amount selected by user
  double feePercentage = 0.50;
  double revenueSharePercentage = 0.0; // Automatically calculated
  String revenueShareFrequency = 'monthly';
  String repaymentDelay = '30 days';

  TextEditingController revenueAmountController = TextEditingController();
  TextEditingController loanAmountController = TextEditingController();
  TextEditingController revenueSharePercentageController =
      TextEditingController();
  TextEditingController fundsReasonController =
      TextEditingController(); // Controller for "Reason for Funds"

  List<Map<String, dynamic>> useOfFunds = [];

  @override
  void initState() {
    super.initState();
    loanAmountController.text = loanAmount.toString();
    revenueSharePercentageController.text =
        revenueSharePercentage.toStringAsFixed(2);
  }

  void _addUseOfFunds() {
    setState(() {
      useOfFunds
          .add({'fundType': 'Marketing', 'description': '', 'amount': 0.0});
    });
  }

  void _removeUseOfFunds(int index) {
    setState(() {
      useOfFunds.removeAt(index);
    });
  }

  // Show results in the dialog box
  void _showResults() {
    double fees = loanAmount * feePercentage;
    double totalRevenueShare = loanAmount + fees;
    int expectedTransfers = (revenueShareFrequency == 'weekly')
        ? ((totalRevenueShare * 52) /
                (revenueAmount * (revenueSharePercentage / 100)))
            .ceil()
        : ((totalRevenueShare * 12) /
                (revenueAmount * (revenueSharePercentage / 100)))
            .ceil();

    DateTime currentDate = DateTime.now();
    int delayInDays = int.parse(repaymentDelay.split(' ')[0]);
    DateTime completionDate =
        currentDate.add(Duration(days: (expectedTransfers + delayInDays) * 7));

    // Format the completion date using DateFormat
    String formattedCompletionDate =
        DateFormat('MMM dd, yyyy').format(completionDate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Loan Calculation Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '📊 Annual Business Revenue: \$${revenueAmount.toStringAsFixed(2)}'),
              Text('💰 Funding Amount: \$${loanAmount.toStringAsFixed(2)}'),
              Text(
                  '💸 Fees (${(feePercentage * 100).toStringAsFixed(0)}%): \$${fees.toStringAsFixed(2)}'),
              Text(
                  '📈 Total Revenue Share: \$${totalRevenueShare.toStringAsFixed(2)}'),
              Text(
                  '📊 Revenue Share Percentage: ${revenueSharePercentage.toStringAsFixed(2)}%'),
              Text('📅 Expected Transfers: $expectedTransfers'),
              Text('🗓 Expected Completion Date: $formattedCompletionDate'),
              const SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set the minimum value of the slider to 0
    double minLoanAmount = 0.0;
    // Dynamically calculate the maximum loan amount as 1/3 of the entered revenue
    double maxLoanAmount = (revenueAmount > 0) ? (revenueAmount / 3) : 0.0;

    // If the revenue is 0, the max should be 0 (no loan possible)
    if (maxLoanAmount < minLoanAmount) {
      maxLoanAmount = minLoanAmount;
    }

    // Calculate divisions for finer increments (1 step per increment) if maxLoanAmount > 0
    int divisions = (maxLoanAmount > 0) ? maxLoanAmount.toInt() : 1;

    // Ensure loanAmount is within the min and max range
    if (loanAmount < minLoanAmount) {
      loanAmount = minLoanAmount;
    }
    if (loanAmount > maxLoanAmount) {
      loanAmount = maxLoanAmount;
    }

    // Calculate the revenue share percentage automatically based on the formula
    double calculatedRevenueSharePercentage =
        (0.156 / 6.2055 / revenueAmount) * (loanAmount * 10);
    setState(() {
      revenueSharePercentage =
          calculatedRevenueSharePercentage * 100; // Convert to percentage
      revenueSharePercentageController.text =
          revenueSharePercentage.toStringAsFixed(2);
    });

    return Scaffold(
      appBar: AppBar(
          title: const Text('Loan Calculator',
              style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
                "What is your annual business revenue?",
                TextField(
                  controller: revenueAmountController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("Enter revenue"),
                  onChanged: (value) {
                    setState(() {
                      revenueAmount = double.tryParse(value) ?? 0.0;
                      // Recalculate revenue share percentage
                      double calculatedRevenueSharePercentage =
                          (0.156 / 6.2055 / revenueAmount) * (loanAmount * 10);
                      revenueSharePercentage =
                          calculatedRevenueSharePercentage *
                              100; // Convert to percentage
                      revenueSharePercentageController.text =
                          revenueSharePercentage.toStringAsFixed(2);
                    });
                  },
                )),
            _buildCard(
                "What is your desired loan amount?",
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Displaying min and max values
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("\$${minLoanAmount.toStringAsFixed(0)}",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text("\$${maxLoanAmount.toStringAsFixed(0)}",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: loanAmount,
                      min: minLoanAmount,
                      max: maxLoanAmount,
                      divisions: divisions, // 1 increment per division
                      label: "\$${loanAmount.round()}",
                      onChanged: (value) {
                        setState(() {
                          loanAmount = value;
                          loanAmountController.text = loanAmount
                              .toStringAsFixed(0); // Update the text field
                          // Recalculate revenue share percentage
                          double calculatedRevenueSharePercentage =
                              (0.156 / 6.2055 / revenueAmount) *
                                  (loanAmount * 10);
                          revenueSharePercentage =
                              calculatedRevenueSharePercentage *
                                  100; // Convert to percentage
                          revenueSharePercentageController.text =
                              revenueSharePercentage.toStringAsFixed(2);
                        });
                      },
                    ),
                    Text(
                        "Selected Loan Amount: \$${loanAmount.toStringAsFixed(0)}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: loanAmountController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Enter loan amount"),
                      onChanged: (value) {
                        setState(() {
                          loanAmount = double.tryParse(value) ?? minLoanAmount;
                          // Recalculate revenue share percentage
                          double calculatedRevenueSharePercentage =
                              (0.156 / 6.2055 / revenueAmount) *
                                  (loanAmount * 10);
                          revenueSharePercentage =
                              calculatedRevenueSharePercentage *
                                  100; // Convert to percentage
                          revenueSharePercentageController.text =
                              revenueSharePercentage.toStringAsFixed(2);
                        });
                      },
                    ),
                  ],
                )),
            _buildCard(
                "Revenue Share Percentage",
                TextField(
                  controller: revenueSharePercentageController,
                  readOnly:
                      true, // Make it read-only as it's calculated automatically
                  decoration:
                      _inputDecoration("Calculated Revenue Share Percentage"),
                )),
            _buildCard(
                "Revenue Shared Frequency",
                Column(
                  children: [
                    RadioListTile(
                      title: const Text("Monthly"),
                      value: "monthly",
                      groupValue: revenueShareFrequency,
                      onChanged: (value) => setState(
                          () => revenueShareFrequency = value.toString()),
                    ),
                    RadioListTile(
                      title: const Text("Weekly"),
                      value: "weekly",
                      groupValue: revenueShareFrequency,
                      onChanged: (value) => setState(
                          () => revenueShareFrequency = value.toString()),
                    ),
                  ],
                )),
            _buildCard(
                "Desired Repayment Delay",
                DropdownButtonFormField<String>(
                  value: repaymentDelay,
                  decoration: _inputDecoration("Select delay"),
                  items: const [
                    DropdownMenuItem(value: "30 days", child: Text("30 days")),
                    DropdownMenuItem(value: "60 days", child: Text("60 days")),
                    DropdownMenuItem(value: "90 days", child: Text("90 days")),
                  ],
                  onChanged: (value) => setState(() => repaymentDelay = value!),
                )),
            _buildCard(
                "What will you use the funds for?",
                Column(
                  children: [
                    ...useOfFunds.map((fund) {
                      int index = useOfFunds.indexOf(fund);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            // Fund Type Dropdown
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: fund['fundType'],
                                decoration: _inputDecoration("Select Type"),
                                items: const [
                                  DropdownMenuItem(
                                      value: "Marketing",
                                      child: Text("Marketing")),
                                  DropdownMenuItem(
                                      value: "Personnel",
                                      child: Text("Personnel")),
                                  DropdownMenuItem(
                                      value: "Working Capital",
                                      child: Text("Working Capital")),
                                  DropdownMenuItem(
                                      value: "Inventory",
                                      child: Text("Inventory")),
                                  DropdownMenuItem(
                                      value: "Machinery/Equipment",
                                      child: Text("Machinery/Equipment")),
                                  DropdownMenuItem(
                                      value: "Others", child: Text("Others")),
                                ],
                                onChanged: (value) => setState(() =>
                                    fund['fundType'] = value ?? 'Marketing'),
                              ),
                            ),
                            // Description Text Field
                            Expanded(
                              child: TextField(
                                decoration: _inputDecoration("Description"),
                                onChanged: (value) =>
                                    setState(() => fund['description'] = value),
                              ),
                            ),
                            // Amount Text Field
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration("Amount"),
                                onChanged: (value) => setState(() =>
                                    fund['amount'] =
                                        double.tryParse(value) ?? 0.0),
                              ),
                            ),
                            // Delete Button (Trash Icon)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeUseOfFunds(index),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    ElevatedButton.icon(
                      onPressed: _addUseOfFunds,
                      icon: const Icon(Icons.add),
                      label: const Text('Add More'),
                    ),
                  ],
                )),
            ElevatedButton(
              onPressed: _showResults,
              child: const Text('Show Results'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, Widget child) {
    return Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              child
            ])));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(
          vertical: 10, horizontal: 10), // Ensure consistent padding
    );
  }
}
