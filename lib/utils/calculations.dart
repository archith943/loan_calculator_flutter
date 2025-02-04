class Calculations {
  // Calculate Revenue Share Percentage
  static double calculateRevenuePercentage(double revenueAmount, double loanAmount) {
    return (0.156 / 6.2055 / revenueAmount) * (loanAmount * 10);
  }

  // Calculate Fees
  static double calculateFees(double loanAmount, double feePercentage) {
    return loanAmount * feePercentage;
  }

  // Calculate Total Revenue Share
  static double calculateTotalRevenueShare(double loanAmount, double fees) {
    return loanAmount + fees;
  }

  // Calculate Expected Transfers
  static int calculateExpectedTransfers(double totalRevenueShare, double revenueAmount, double revenuePercentage, String frequency) {
    if (frequency == "weekly") {
      return ((totalRevenueShare * 52) / (revenueAmount * revenuePercentage)).ceil();
    } else {
      return ((totalRevenueShare * 12) / (revenueAmount * revenuePercentage)).ceil();
    }
  }

  // Calculate Expected Completion Date
  static DateTime calculateExpectedCompletionDate(DateTime currentDate, int expectedTransfers, String repaymentDelay) {
    int delayInDays = int.parse(repaymentDelay.split(" ")[0]);
    return currentDate.add(Duration(days: delayInDays + (expectedTransfers * 7))); // Assuming weekly frequency
  }
}
