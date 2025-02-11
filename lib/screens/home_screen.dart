// home_screen.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'config_model.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:convert';

class LoanCalculatorPage extends StatefulWidget {
  @override
  _LoanCalculatorPageState createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  List<ConfigItem> configItems = [];
  double revenueAmount = 0.0;
  double loanAmount = 0.0;
  double revenueSharePercentage = 0.0;
  String revenueShareFrequency = "monthly";
  String repaymentDelay = "30 days"; // Default value for repayment delay
  String expectedCompletionDate = '';
  String errorMessage = '';
  bool isLoading = true;

  // Variables for limits and options from API
  double minFundingAmount = 0.0;
  double maxFundingAmount = 0.0;
  double minRevenueSharePercentage = 0.0;
  double maxRevenueSharePercentage = 0.0;

  @override
  void initState() {
    super.initState();
    fetchConfig();
  }

  Future<void> fetchConfig() async {
    try {
      configItems = await ApiService().fetchConfig();
      setState(() {
        minFundingAmount = configItems
                .firstWhere((item) => item.name == 'funding_amount_min')
                .value ??
            0.0;
        maxFundingAmount = configItems
                .firstWhere((item) => item.name == 'funding_amount_max')
                .value ??
            0.0;
        minRevenueSharePercentage = configItems
                .firstWhere((item) => item.name == 'revenue_percentage_min')
                .value ??
            0.0;
        maxRevenueSharePercentage = configItems
                .firstWhere((item) => item.name == 'revenue_percentage_max')
                .value ??
            0.0;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching configuration: $e';
        isLoading = false;
      });
    }
  }

  void calculateResults() {
    if (revenueAmount <= 0 || loanAmount <= 0) {
      setState(() {
        revenueSharePercentage = 0.0;
        expectedCompletionDate = 'Invalid input values';
      });
      return;
    }

    // Calculate revenue share percentage
    revenueSharePercentage =
        (0.156 / 6.2055 / revenueAmount) * (loanAmount * 10);

    // Ensure that the revenue share percentage is within the allowed range
    revenueSharePercentage = revenueSharePercentage.clamp(
        minRevenueSharePercentage, maxRevenueSharePercentage);

    double fees =
        loanAmount * 0.5; // Assume a fee percentage (from API or default)
    double totalRevenueShare = loanAmount + fees;

    int expectedTransfers = revenueShareFrequency == 'weekly'
        ? ((totalRevenueShare * 52) /
                (revenueAmount * (revenueSharePercentage / 100)))
            .ceil()
        : ((totalRevenueShare * 12) /
                (revenueAmount * (revenueSharePercentage / 100)))
            .ceil();

    DateTime currentDate = DateTime.now();
    DateTime expectedDate = currentDate.add(Duration(
        days: expectedTransfers * (revenueShareFrequency == 'weekly' ? 7 : 30) +
            int.parse(repaymentDelay.split(' ')[0])));
    expectedCompletionDate =
        '${expectedDate.month}/${expectedDate.day}/${expectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Loan Calculator')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Revenue Amount
            _buildCard(
                "What is your annual business revenue?",
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: "Enter revenue"),
                  onChanged: (value) {
                    setState(() {
                      revenueAmount = double.tryParse(value) ?? 0.0;
                      calculateResults();
                    });
                  },
                )),
            // Loan Amount
            _buildCard(
                "What is your desired loan amount?",
                Slider(
                  value: loanAmount,
                  min: minFundingAmount,
                  max: maxFundingAmount,
                  divisions: 10,
                  label: "\$${loanAmount.round()}",
                  onChanged: (value) {
                    setState(() {
                      loanAmount = value;
                      calculateResults();
                    });
                  },
                )),
            // Revenue Share Percentage
            _buildCard(
                "Revenue Share Percentage",
                Text(
                  "${revenueSharePercentage.toStringAsFixed(2)}%",
                )),
            // Revenue Share Frequency
            _buildCard(
                "Revenue Share Frequency",
                Column(
                  children: [
                    RadioListTile(
                      title: Text("Monthly"),
                      value: "monthly",
                      groupValue: revenueShareFrequency,
                      onChanged: (value) {
                        setState(() {
                          revenueShareFrequency = value!;
                          calculateResults();
                        });
                      },
                    ),
                    RadioListTile(
                      title: Text("Weekly"),
                      value: "weekly",
                      groupValue: revenueShareFrequency,
                      onChanged: (value) {
                        setState(() {
                          revenueShareFrequency = value!;
                          calculateResults();
                        });
                      },
                    ),
                  ],
                )),
            // Desired Repayment Delay
            _buildCard(
                "Desired Repayment Delay",
                DropdownButtonFormField<String>(
                  value: repaymentDelay,
                  items: ['30 days', '60 days', '90 days'].map((String delay) {
                    return DropdownMenuItem<String>(
                      value: delay,
                      child: Text(delay),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      repaymentDelay = value!;
                      calculateResults();
                    });
                  },
                )),
            ElevatedButton(
              onPressed: calculateResults,
              child: Text("Show Results"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, Widget child) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            child,
          ],
        ),
      ),
    );
  }
}
