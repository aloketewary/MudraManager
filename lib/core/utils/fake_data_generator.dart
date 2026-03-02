import 'dart:math';

class FakeDataGenerator {
  static final Random _random = Random();

  static double generateFakeBalance() {
    return (5000 + _random.nextInt(45000)).toDouble();
  }

  static double generateFakeSpent() {
    return (500 + _random.nextInt(4500)).toDouble();
  }

  static double generateFakeBudget() {
    return (10000 + _random.nextInt(40000)).toDouble();
  }

  static double generateFakeAmount() {
    return (100 + _random.nextInt(5000)).toDouble();
  }

  static double generateFakeDailyAverage() {
    return (200 + _random.nextInt(1000)).toDouble();
  }

  static double generateFakeProjected() {
    return (5000 + _random.nextInt(25000)).toDouble();
  }

  static String generateFakeMerchant() {
    const merchants = [
      'Starbucks',
      'Amazon',
      'Flipkart',
      'Swiggy',
      'Zomato',
      'Uber',
      'Ola',
      'Netflix',
      'Spotify',
      'Gym',
      'Grocery Store',
      'Pharmacy',
      'Restaurant',
      'Fuel Station',
      'Shopping Mall',
    ];
    return merchants[_random.nextInt(merchants.length)];
  }
}
