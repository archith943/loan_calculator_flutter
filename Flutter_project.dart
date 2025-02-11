import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
      home: LoanCalculatorPage(),
    );
  }
}

class LoanCalculatorPage extends StatefulWidget {
  @override
  _LoanCalculatorPageState createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  Map<String, dynamic> config = {};
  double revenueAmount = 0.0;
  double fundingAmount = 0.0;
  double revenueSharePercentage = 0.0;
  String revenueShareFrequency = '';
  String repaymentDelay = '';
  double feePercentage = 0.0;
  double totalRevenueShare = 0.0;
  int expectedTransfers = 0;
  String expectedCompletionDate = '';
  List<Map<String, dynamic>> useOfFunds = [];
  bool isLoading = true; // Add loading state
  String errorMessage = ''; // To display any error messages

  @override
  void initState() {
    super.initState();
    fetchConfig();
  }

  Future<void> fetchConfig() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://gist.githubusercontent.com/motgi/8fc373cbfccee534c820875ba20ae7b5/raw/7143758ff2caa773e651dc3576de57cc829339c0/config.json'),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        // Check if the response is a List
        if (data is List && data.isNotEmpty) {
          setState(() {
            // The data is an array. Use the first element of the array for configuration
            config = data[
                0]; // Assuming the needed data is the first element in the array
            feePercentage = config['desired_fee_percentage'] ?? 0.0;
            isLoading = false;
          });
        } else {
          throw Exception('Expected a List but got something else');
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
    double fees = fundingAmount * feePercentage;
    totalRevenueShare = fundingAmount + fees;

    // Calculate expected transfers based on frequency
    if (revenueShareFrequency == 'weekly') {
      expectedTransfers =
          ((totalRevenueShare * 52) / (revenueAmount * revenueSharePercentage))
              .ceil();
    } else if (revenueShareFrequency == 'monthly') {
      expectedTransfers =
          ((totalRevenueShare * 12) / (revenueAmount * revenueSharePercentage))
              .ceil();
    }

    // Calculate expected completion date
    DateTime currentDate = DateTime.now();
    DateTime expectedDate = currentDate.add(Duration(
        days: expectedTransfers * (revenueShareFrequency == 'weekly' ? 7 : 30) +
            int.parse(repaymentDelay)));
    expectedCompletionDate =
        '${expectedDate.month}/${expectedDate.day}/${expectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loan Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(
                child:
                    CircularProgressIndicator()) // Show loading indicator while waiting for API
            : config.isEmpty
                ? Center(
                    child: Text(errorMessage.isNotEmpty
                        ? errorMessage
                        : 'No data available.'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Annual Business Revenue:'),
                      TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            revenueAmount = double.tryParse(value) ?? 0.0;
                            fundingAmount =
                                0.0; // Reset funding amount when revenue changes
                          });
                        },
                        decoration: InputDecoration(
                          labelText: config['revenue_amount']['label'],
                          hintText: config['revenue_amount'][
                              'placeholder'], // Corrected placeholder to hintText
                        ),
                      ),
                      SizedBox(height: 10),
                      Text('Loan Amount:'),
                      Slider(
                        value: fundingAmount,
                        min: 0,
                        max: (revenueAmount / 3).toDouble(),
                        divisions: 10,
                        label: fundingAmount.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            fundingAmount = value;
                          });
                        },
                      ),
                      Text(fundingAmount.toStringAsFixed(2)),
                      SizedBox(height: 10),
                      Text('Revenue Share Percentage:'),
                      Slider(
                        value: revenueSharePercentage,
                        min: config['revenue_percentage_min'],
                        max: config['revenue_percentage_max'],
                        divisions: 10,
                        label: revenueSharePercentage.toStringAsFixed(2),
                        onChanged: (value) {
                          setState(() {
                            revenueSharePercentage = value;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      Text('Revenue Share Frequency:'),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'weekly',
                            groupValue: revenueShareFrequency,
                            onChanged: (value) {
                              setState(() {
                                revenueShareFrequency = value ?? '';
                              });
                            },
                          ),
                          Text('Weekly'),
                          Radio<String>(
                            value: 'monthly',
                            groupValue: revenueShareFrequency,
                            onChanged: (value) {
                              setState(() {
                                revenueShareFrequency = value ?? '';
                              });
                            },
                          ),
                          Text('Monthly'),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text('Desired Repayment Delay (Days):'),
                      TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            repaymentDelay = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Repayment Delay',
                        ),
                      ),
                      SizedBox(height: 10),
                      Text('Use of Funds:'),
                      // Example: List of funds - You can modify it to take dynamic inputs
                      TextField(
                        onChanged: (value) {
                          // Placeholder: You can implement functionality to add multiple funds
                        },
                        decoration: InputDecoration(
                          labelText: 'Use of Funds Type, Description, Amount',
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          calculateResults();
                        },
                        child: Text('Calculate'),
                      ),
                      SizedBox(height: 20),
                      Text('Results:'),
                      Text(
                          'Annual Business Revenue: \$${revenueAmount.toStringAsFixed(2)}'),
                      Text(
                          'Loan Amount: \$${fundingAmount.toStringAsFixed(2)}'),
                      Text(
                          'Fees: \$${(fundingAmount * feePercentage).toStringAsFixed(2)}'),
                      Text(
                          'Total Revenue Share: \$${totalRevenueShare.toStringAsFixed(2)}'),
                      Text('Expected Transfers: $expectedTransfers'),
                      Text('Expected Completion Date: $expectedCompletionDate'),
                    ],
                  ),
      ),
    );
  }
}
