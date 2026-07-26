/// Suggests SMS auto-detection keywords for a category based on its name.
///
/// Used by the add/edit category screen to help users populate
/// [Category.keywords] without having to know good merchant/SMS terms
/// themselves — the same dictionary that seeds keywords for the built-in
/// default categories (see `CategorySeeder.seedDefaultKeywords`), exposed
/// here as a fuzzy name → keywords lookup for arbitrary user-typed names.
class CategoryKeywordSuggestions {
  CategoryKeywordSuggestions._();

  /// Canonical name → suggested keywords. Keys are lowercase.
  /// Kept in sync with [CategorySeeder]'s default keyword map — if you
  /// add a new default category with keywords there, consider adding an
  /// entry here too (or a synonym pointing at it) so custom categories
  /// with similar names benefit as well.
  static const Map<String, List<String>> _byName = {
    'food': ['swiggy', 'zomato', 'food', 'dining', 'cafe', 'canteen', 'mess', 'tiffin'],
    'restaurant': ['restaurant', 'pizza', 'burger', 'bakery', 'biryani', 'diner', 'eatery'],
    'groceries': ['bigbasket', 'blinkit', 'zepto', 'grocery', 'supermarket', 'dmart', 'vegetables', 'fruits'],
    'transport': ['uber', 'ola', 'rapido', 'taxi', 'cab', 'auto', 'rickshaw', 'commute'],
    'fuel': ['petrol', 'diesel', 'cng', 'fuel', 'pump', 'indianoil', 'hpcl', 'bpcl', 'shell'],
    'public transport': ['metro', 'bus', 'train', 'railway', 'irctc', 'parking', 'toll'],
    'shopping': ['amazon', 'flipkart', 'myntra', 'mall', 'store', 'ajio', 'nykaa'],
    'clothing': ['clothes', 'shoes', 'fashion', 'apparel', 'footwear'],
    'electronics': ['electronics', 'mobile phone', 'laptop', 'gadget', 'croma', 'reliance digital'],
    'bills': ['bill', 'maintenance', 'society', 'apartment'],
    'electricity': ['electricity', 'power bill', 'discom'],
    'internet': ['internet', 'broadband', 'wifi', 'airtel', 'jio fiber', 'act fibernet'],
    'rent': ['house rent', 'rent paid', 'landlord', 'monthly rent'],
    'phone recharge': ['recharge', 'airtel', 'jio', 'vi', 'bsnl', 'postpaid', 'prepaid'],
    'entertainment': ['bookmyshow', 'games', 'concert', 'show', 'theatre', 'music'],
    'movies': ['movie', 'cinema', 'pvr', 'inox', 'multiplex'],
    'streaming': ['netflix', 'prime video', 'hotstar', 'spotify', 'youtube premium', 'disney'],
    'subscriptions': ['netflix', 'prime video', 'spotify', 'subscription', 'renewal'],
    'healthcare': ['hospital', 'clinic', 'dental', 'checkup', 'consultation', 'lab', 'apollo'],
    'doctor': ['doctor', 'physician', 'consultation fee', 'opd'],
    'medicines': ['pharmacy', 'medicine', 'medplus', 'netmeds', '1mg', 'pharmeasy', 'chemist'],
    'education': ['school', 'college', 'university', 'course', 'exam', 'coaching', 'udemy'],
    'tuition': ['tuition', 'fees', 'admission fee'],
    'books': ['books', 'stationery', 'bookstore'],
    'personal care': ['spa', 'parlour', 'facial', 'massage', 'beauty', 'cosmetics', 'grooming'],
    'salon': ['salon', 'barber', 'haircut'],
    'gym': ['gym', 'fitness', 'yoga', 'workout'],
    'pet': ['pet food', 'vet', 'veterinary', 'grooming', 'pet care', 'petshop'],
    'religious': ['temple', 'church', 'mosque', 'gurudwara'],
    'puja': ['puja', 'pooja', 'ritual', 'pandit'],
    'donations': ['donation', 'charity', 'dakshina'],
    'gifts': ['gift', 'present'],
    'wedding': ['wedding', 'marriage', 'shaadi'],
    'salary': ['salary', 'wages', 'payroll', 'payment received', 'bonus', 'incentive', 'allowance'],
    'business income': ['business income', 'consulting', 'freelance', 'commission', 'invoice paid'],
    'investment': ['mutual fund', 'stock', 'sip', 'dividend', 'interest credited', 'zerodha', 'groww'],
    'insurance': ['premium', 'policy', 'claim', 'lic'],
    'travel': ['flight', 'hotel', 'booking', 'makemytrip', 'goibibo', 'airbnb', 'oyo'],
    'home': ['furniture', 'decor', 'appliances', 'renovation', 'interior'],
    'maintenance': ['repair', 'plumber', 'electrician', 'carpenter', 'handyman'],
  };

  /// Synonym → canonical key in [_byName]. Lets a broader set of
  /// user-typed names resolve to the closest relevant dictionary entry.
  static const Map<String, String> _synonyms = {
    'dining': 'food',
    'takeout': 'food',
    'grocery': 'groceries',
    'supermarket': 'groceries',
    'car': 'fuel',
    'petrol': 'fuel',
    'diesel': 'fuel',
    'bike': 'fuel',
    'vehicle': 'fuel',
    'commute': 'transport',
    'cab': 'transport',
    'taxi': 'transport',
    'metro': 'public transport',
    'bus': 'public transport',
    'train': 'public transport',
    'clothes': 'clothing',
    'apparel': 'clothing',
    'fashion': 'clothing',
    'gadgets': 'electronics',
    'utilities': 'bills',
    'utility': 'bills',
    'power': 'electricity',
    'broadband': 'internet',
    'wifi': 'internet',
    'mobile recharge': 'phone recharge',
    'recharge': 'phone recharge',
    'ott': 'streaming',
    'netflix': 'streaming',
    'subscription': 'subscriptions',
    'hospital': 'healthcare',
    'medical': 'healthcare',
    'medicine': 'medicines',
    'pharmacy': 'medicines',
    'school': 'education',
    'college': 'education',
    'course': 'education',
    'spa': 'personal care',
    'skincare': 'personal care',
    'fitness': 'gym',
    'yoga': 'gym',
    'barber': 'salon',
    'haircut': 'salon',
    'vet': 'pet',
    'pets': 'pet',
    'temple': 'religious',
    'spiritual': 'religious',
    'charity': 'donations',
    'gift': 'gifts',
    'marriage': 'wedding',
    'wages': 'salary',
    'payroll': 'salary',
    'freelance': 'business income',
    'consulting': 'business income',
    'stocks': 'investment',
    'mutual fund': 'investment',
    'sip': 'investment',
    'flight': 'travel',
    'hotel': 'travel',
    'vacation': 'travel',
    'trip': 'travel',
    'furniture': 'home',
    'decor': 'home',
    'repair': 'maintenance',
  };

  /// Returns suggested keywords for a (partial) category name the user is
  /// typing. Matches on exact name, synonym, or substring in either
  /// direction — so "Fuel", "Petrol Expenses" and "Car Fuel" all resolve.
  /// Returns an empty list if nothing relevant is found.
  static List<String> suggest(String categoryName) {
    final query = categoryName.trim().toLowerCase();
    if (query.length < 2) return const [];

    // 1. Exact match on canonical name.
    final exact = _byName[query];
    if (exact != null) return exact;

    // 2. Exact match on a synonym.
    final synonymKey = _synonyms[query];
    if (synonymKey != null) return _byName[synonymKey] ?? const [];

    // 3. Substring match — query contains a known key/synonym, or vice
    // versa (e.g. "Petrol Expenses" contains "petrol" → fuel). Skip keys
    // shorter than 4 chars here (e.g. "pet", "gym") — too prone to
    // false positives as substrings of unrelated words ("carPET",
    // "comPETe"); those still work fine via the exact-match checks above.
    for (final entry in _synonyms.entries) {
      if (entry.key.length < 4) continue;
      if (query.contains(entry.key) || entry.key.contains(query)) {
        return _byName[entry.value] ?? const [];
      }
    }
    for (final key in _byName.keys) {
      if (key.length < 4) continue;
      if (query.contains(key) || key.contains(query)) {
        return _byName[key]!;
      }
    }

    return const [];
  }
}
