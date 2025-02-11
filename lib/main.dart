import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Ensure this import is present at the top of your file

void main() {
  runApp(LoanCalculatorApp());
}

class LoanCalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loan Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoanCalculatorPage(), // Correct reference to LoanCalculatorPage
    );
  }
}

class LoanCalculatorPage extends StatefulWidget {
  @override
  _LoanCalculatorPageState createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  Map<String, dynamic> config = {}; // To hold the API response
  double revenueAmount = 0.0;
  double fundingAmount = 0.0;
  double revenueSharePercentage = 0.0;
  String revenueShareFrequency = 'monthly';
  String repaymentDelay = '30 days';
  double feePercentage = 0.0;
  double totalRevenueShare = 0.0;
  int expectedTransfers = 0;
  String expectedCompletionDate = '';
  bool isLoading = true;
  String errorMessage = '';
  final List<Map<String, dynamic>> useOfFunds = [];

  @override
  void initState() {
    super.initState();
    fetchConfig(); // Fetch data from the API on initialization
  }

  Future<void> fetchConfig() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://gist.githubusercontent.com/motgi/8fc373cbfccee534c820875ba20ae7b5/raw/7143758ff2caa773e651dc3576de57cc829339c0/config.json'),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data is List && data.isNotEmpty) {
          setState(() {
            config = data[0] as Map<String, dynamic>;
            feePercentage = config['desired_fee_percentage'] != null
                ? double.tryParse(
                        config['desired_fee_percentage'].toString()) ??
                    0.0
                : 0.0;
            isLoading = false;
          });
        } else {
          throw Exception('The API response is not in the expected format');
        }
      } else {
        throw Exception(
            'Failed to load config, status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading configuration: $e';
      });
      print('Error fetching config: $e');
    }
  }

  void calculateResults() {
    if (revenueAmount <= 0 || fundingAmount <= 0) {
      setState(() {
        revenueSharePercentage = 0.0;
        totalRevenueShare = 0.0;
        expectedTransfers = 0;
        expectedCompletionDate = 'Invalid input values';
      });
      return;
    }

    revenueSharePercentage =
        (0.156 / 6.2055 / revenueAmount) * (fundingAmount * 10);

    double fees = fundingAmount * feePercentage;
    totalRevenueShare = fundingAmount + fees;

    if (revenueShareFrequency == 'weekly') {
      expectedTransfers =
          ((totalRevenueShare * 52) / (revenueAmount * revenueSharePercentage))
              .ceil();
    } else if (revenueShareFrequency == 'monthly') {
      expectedTransfers =
          ((totalRevenueShare * 12) / (revenueAmount * revenueSharePercentage))
              .ceil();
    }

    DateTime currentDate = DateTime.now();
    DateTime expectedDate = currentDate.add(Duration(
        days: expectedTransfers * (revenueShareFrequency == 'weekly' ? 7 : 30) +
            int.parse(repaymentDelay.split(' ')[0])));
    expectedCompletionDate =
        '${expectedDate.month}/${expectedDate.day}/${expectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Add the `build` method implementation here

    double minLoanAmount = 0.0;
    double maxLoanAmount = (revenueAmount > 0) ? (revenueAmount / 3) : 0.0;
    if (maxLoanAmount < minLoanAmount) {
      maxLoanAmount = minLoanAmount;
    }

    int divisions = (maxLoanAmount > 0) ? maxLoanAmount.toInt() : 1;

    if (fundingAmount < minLoanAmount) {
      fundingAmount = minLoanAmount;
    }
    if (fundingAmount > maxLoanAmount) {
      fundingAmount = maxLoanAmount;
    }

    double calculatedRevenueSharePercentage =
        (0.156 / 6.2055 / revenueAmount) * (fundingAmount * 10);
    setState(() {
      revenueSharePercentage = calculatedRevenueSharePercentage * 100;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Calculator',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
                "What is your annual business revenue?",
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter revenue",
                  ),
                  onChanged: (value) {
                    setState(() {
                      revenueAmount = double.tryParse(value) ?? 0.0;
                      calculateResults();
                    });
                  },
                )),
            _buildCard(
                "What is your desired loan amount?",
                Slider(
                  value: fundingAmount,
                  min: minLoanAmount,
                  max: maxLoanAmount,
                  divisions: divisions,
                  label: "\$${fundingAmount.round()}",
                  onChanged: (value) {
                    setState(() {
                      fundingAmount = value;
                      calculateResults();
                    });
                  },
                )),
            _buildCard(
                "Revenue Share Percentage",
                Text(
                  "${revenueSharePercentage.toStringAsFixed(2)}%",
                  style: TextStyle(fontWeight: FontWeight.bold),
                )),
            _buildCard(
                "Revenue Share Frequency",
                Column(
                  children: [
                    RadioListTile(
                      title: const Text("Monthly"),
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
                      title: const Text("Weekly"),
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
            _buildCard(
                "Desired Repayment Delay",
                DropdownButtonFormField<String>(
                  value: repaymentDelay,
                  decoration: InputDecoration(hintText: "Select delay"),
                  items: config['desired_repayment_delay'] != null
                      ? config['desired_repayment_delay']['value']
                          .split('*')
                          .map((String delay) {
                          return DropdownMenuItem<String>(
                            value: delay,
                            child: Text(delay),
                          );
                        }).toList()
                      : [
                          DropdownMenuItem(
                              value: '30 days', child: Text('30 days')),
                          DropdownMenuItem(
                              value: '60 days', child: Text('60 days')),
                          DropdownMenuItem(
                              value: '90 days', child: Text('90 days')),
                        ],
                  onChanged: (value) {
                    setState(() {
                      repaymentDelay = value!;
                      calculateResults();
                    });
                  },
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
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: fund['fundType'],
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
                            Expanded(
                              child: TextField(
                                decoration:
                                    InputDecoration(hintText: "Description"),
                                onChanged: (value) =>
                                    setState(() => fund['description'] = value),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(hintText: "Amount"),
                                onChanged: (value) => setState(() =>
                                    fund['amount'] =
                                        double.tryParse(value) ?? 0.0),
                              ),
                            ),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          child
        ]),
      ),
    );
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

  void _showResults() {
    double fees = fundingAmount * feePercentage;
    double totalRevenueShare = fundingAmount + fees;
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
                  'Annual Business Revenue: \$${revenueAmount.toStringAsFixed(2)}'),
              Text('Loan Amount: \$${fundingAmount.toStringAsFixed(2)}'),
              Text('Fees: \$${fees.toStringAsFixed(2)}'),
              Text(
                  'Total Revenue Share: \$${totalRevenueShare.toStringAsFixed(2)}'),
              Text(
                  'Revenue Share Percentage: ${revenueSharePercentage.toStringAsFixed(2)}%'),
              Text('Expected Transfers: $expectedTransfers'),
              Text('Expected Completion Date: $formattedCompletionDate'),
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
}
