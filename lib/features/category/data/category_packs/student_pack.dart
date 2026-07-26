import 'category_pack.dart';

class StudentPack extends CategoryPack {
  static final instance = StudentPack._();
  StudentPack._();

  @override
  String get id => 'com.mudra.pack.student';
  @override
  String get name => 'Student';
  @override
  String get description => 'Campus, hostel & college life';
  @override
  String get icon => 'school';
  @override
  int get color => 0xFF2196F3;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(
          name: 'Mess/PG Food',
          icon: 'restaurant',
          color: 0xFF4CAF50,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Canteen',
          icon: 'fastfood',
          color: 0xFFFF9800,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'College Bus',
          icon: 'bus',
          color: 0xFF9C27B0,
          parent: 'Transport',
        ),
        CategoryDef(
          name: 'Hostel Rent',
          icon: 'home',
          color: 0xFF607D8B,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Stationery',
          icon: 'stationery',
          color: 0xFF2196F3,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Books & Copies',
          icon: 'book',
          color: 0xFF3F51B5,
          parent: 'Education',
        ),
        CategoryDef(
          name: 'Printing/Xerox',
          icon: 'print',
          color: 0xFF795548,
          parent: 'Education',
        ),
        CategoryDef(
          name: 'Exam Fees',
          icon: 'exam',
          color: 0xFF009688,
          parent: 'Education',
        ),
        CategoryDef(
          name: 'Coaching/Tuition',
          icon: 'tutor',
          color: 0xFF00BCD4,
          parent: 'Education',
        ),
        CategoryDef(
          name: 'Online Courses',
          icon: 'online_course',
          color: 0xFF3F51B5,
          parent: 'Education',
        ),
      ];
}
