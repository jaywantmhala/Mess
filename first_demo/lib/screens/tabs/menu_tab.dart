import 'package:flutter/material.dart';

class MenuItemModel {
  final String name;
  final bool isVeg;
  final String calories;
  final String protein;
  final double rating;
  final List<String> tags;
  bool isLiked;
  bool notifyMe;

  MenuItemModel({
    required this.name,
    required this.isVeg,
    required this.calories,
    required this.protein,
    required this.rating,
    required this.tags,
    this.isLiked = false,
    this.notifyMe = false,
  });
}

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  int _selectedDayIndex = 0;
  String _selectedMealSession = 'Lunch';

  final List<Map<String, String>> _weekDays = [
    {'day': 'Fri', 'date': '03'},
    {'day': 'Sat', 'date': '04'},
    {'day': 'Sun', 'date': '05'},
    {'day': 'Mon', 'date': '06'},
    {'day': 'Tue', 'date': '07'},
    {'day': 'Wed', 'date': '08'},
    {'day': 'Thu', 'date': '09'},
  ];

  final List<String> _mealSessions = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];

  // Dummy menus database
  final Map<String, Map<String, List<MenuItemModel>>> _menuDatabase = {
    'Breakfast': {
      'default': [
        MenuItemModel(name: 'Aloo Paratha with Curd', isVeg: true, calories: '350 kcal', protein: '8g', rating: 4.5, tags: ['Popular', 'North Indian']),
        MenuItemModel(name: 'Boiled Eggs (2)', isVeg: false, calories: '155 kcal', protein: '13g', rating: 4.8, tags: ['High Protein']),
        MenuItemModel(name: 'Idli Vada with Sambar', isVeg: true, calories: '280 kcal', protein: '6g', rating: 4.3, tags: ['South Indian', 'Light']),
        MenuItemModel(name: 'Masala Tea / Filter Coffee', isVeg: true, calories: '90 kcal', protein: '2g', rating: 4.7, tags: ['Beverage']),
      ]
    },
    'Lunch': {
      'default': [
        MenuItemModel(name: 'Paneer Butter Masala', isVeg: true, calories: '380 kcal', protein: '12g', rating: 4.7, tags: ['Chef Special', 'Spicy']),
        MenuItemModel(name: 'Kadhai Chicken (Premium Canteen)', isVeg: false, calories: '450 kcal', protein: '28g', rating: 4.9, tags: ['Non-Veg', 'High Protein']),
        MenuItemModel(name: 'Dal Makhani & Butter Naan', isVeg: true, calories: '420 kcal', protein: '10g', rating: 4.6, tags: ['Classic']),
        MenuItemModel(name: 'Jeera Rice & Green Salad', isVeg: true, calories: '210 kcal', protein: '4g', rating: 4.2, tags: ['Daily']),
      ],
      'Sun': [ // Special Sunday lunch
        MenuItemModel(name: 'Hyderabadi Dum Biryani', isVeg: false, calories: '650 kcal', protein: '24g', rating: 4.9, tags: ['Weekend Special', 'Spicy']),
        MenuItemModel(name: 'Shahi Paneer Biryani', isVeg: true, calories: '580 kcal', protein: '16g', rating: 4.8, tags: ['Weekend Special']),
        MenuItemModel(name: 'Mixed Raita & Double Ka Meetha', isVeg: true, calories: '250 kcal', protein: '5g', rating: 4.6, tags: ['Dessert']),
      ]
    },
    'Snacks': {
      'default': [
        MenuItemModel(name: 'Samosa with Mint Chutney', isVeg: true, calories: '260 kcal', protein: '4g', rating: 4.4, tags: ['Fried', 'Hot']),
        MenuItemModel(name: 'Pav Bhaji', isVeg: true, calories: '390 kcal', protein: '8g', rating: 4.6, tags: ['Mumbai Style']),
        MenuItemModel(name: 'Hot Milk / Tea', isVeg: true, calories: '110 kcal', protein: '5g', rating: 4.2, tags: ['Daily']),
      ]
    },
    'Dinner': {
      'default': [
        MenuItemModel(name: 'Tandoori Roti & Mix Veg', isVeg: true, calories: '290 kcal', protein: '7g', rating: 4.1, tags: ['Healthy', 'Low Calorie']),
        MenuItemModel(name: 'Egg Curry & Rice', isVeg: false, calories: '380 kcal', protein: '18g', rating: 4.5, tags: ['Non-Veg']),
        MenuItemModel(name: 'Moong Dal Halwa', isVeg: true, calories: '240 kcal', protein: '3g', rating: 4.8, tags: ['Dessert', 'Sweet']),
      ]
    }
  };

  List<MenuItemModel> _getCurrentMenu() {
    final dayName = _weekDays[_selectedDayIndex]['day'];
    final sessionMap = _menuDatabase[_selectedMealSession];
    if (sessionMap == null) return [];

    // Sunday Special Lunch
    if (_selectedMealSession == 'Lunch' && dayName == 'Sun') {
      return sessionMap['Sun'] ?? sessionMap['default'] ?? [];
    }
    return sessionMap['default'] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final currentMenu = _getCurrentMenu();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Title Header
            const Text(
              'Weekly Menu Book',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Plan your meals and set notification alerts.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Horizontal Calendar Date Selector
            SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _weekDays.length,
                itemBuilder: (context, index) {
                  final item = _weekDays[index];
                  final isSelected = _selectedDayIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                    },
                    child: Container(
                      width: 55,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF9000FF), Color(0xFF00C6FF)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isSelected ? null : const Color(0xFF080F1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00C6FF).withOpacity(0.5)
                              : Colors.white.withOpacity(0.04),
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00C6FF).withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['day']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['date']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),

            // 3. Meal Session Filter Selector (Breakfast, Lunch, etc.)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _mealSessions.map((session) {
                final isSelected = _selectedMealSession == session;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMealSession = session;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0F2042) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00C6FF) : Colors.white.withOpacity(0.1),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      session,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // 4. Food Menu List
            Expanded(
              child: currentMenu.isEmpty
                  ? Center(
                      child: Text(
                        'No menu items updated for this slot.',
                        style: TextStyle(color: Colors.white.withOpacity(0.4)),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: currentMenu.length,
                      padding: const EdgeInsets.only(bottom: 90),
                      itemBuilder: (context, index) {
                        final item = currentMenu[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF080F1E).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.04),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Veg / Non-Veg Indicator Circle Dot
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: item.isVeg ? Colors.green : Colors.red,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: item.isVeg ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Main content (Name, nutrition, tags)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '${item.calories}  •  Protein ${item.protein}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white.withOpacity(0.4),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.star_rounded, size: 12, color: Colors.amber[600]),
                                        const SizedBox(width: 2),
                                        Text(
                                          item.rating.toString(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      children: item.tags.map((tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D1B2A),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            tag,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFF00C6FF),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),

                              // Interactive Action Buttons (Like / Notify)
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      item.isLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_off_alt_rounded,
                                      size: 18,
                                      color: item.isLiked ? const Color(0xFF00C6FF) : Colors.white.withOpacity(0.3),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        item.isLiked = !item.isLiked;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      item.notifyMe ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                                      size: 18,
                                      color: item.notifyMe ? const Color(0xFF9000FF) : Colors.white.withOpacity(0.3),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        item.notifyMe = !item.notifyMe;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: const Color(0xFF0D1B2A),
                                          content: Text(
                                            item.notifyMe
                                                ? 'Reminder set for ${item.name}!'
                                                : 'Reminder removed.',
                                            style: const TextStyle(color: Color(0xFF00C6FF)),
                                          ),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
