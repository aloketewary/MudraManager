import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/category.dart';

import 'category_pack.dart';

class VehicleEnthusiastPack extends CategoryPack {
  static final instance = VehicleEnthusiastPack._();
  VehicleEnthusiastPack._();

  @override
  String get id => 'com.mudra.pack.vehicle_enthusiast';
  @override
  String get name => 'Vehicle Enthusiast';
  @override
  String get description => 'Track car & bike expenses — fuel, service, mods & more';
  @override
  String get icon => 'directions_car';
  @override
  int get color => 0xFF37474F;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        // Parent
        CategoryDef(name: 'Vehicle', icon: 'directions_car', color: 0xFF37474F),

        // Fuel & charging
        CategoryDef(name: 'Petrol', icon: 'gas', color: 0xFFFF9800, parent: 'Vehicle'),
        CategoryDef(name: 'Diesel', icon: 'gas', color: 0xFFFF6F00, parent: 'Vehicle'),
        CategoryDef(name: 'EV Charging', icon: 'gas', color: 0xFF4CAF50, parent: 'Vehicle'),

        // Maintenance
        CategoryDef(name: 'Service & Repair', icon: 'repair', color: 0xFF2196F3, parent: 'Vehicle'),
        CategoryDef(name: 'Tyres', icon: 'directions_car', color: 0xFF455A64, parent: 'Vehicle'),
        CategoryDef(name: 'Car Wash', icon: 'cleaning', color: 0xFF00BCD4, parent: 'Vehicle'),
        CategoryDef(name: 'Oil Change', icon: 'repair', color: 0xFF795548, parent: 'Vehicle'),

        // Ownership costs
        CategoryDef(name: 'Vehicle Insurance', icon: 'insurance', color: 0xFF673AB7, parent: 'Vehicle'),
        CategoryDef(name: 'EMI / Loan', icon: 'receipt', color: 0xFFF44336, parent: 'Vehicle'),
        CategoryDef(name: 'Road Tax / RTO', icon: 'toll', color: 0xFF607D8B, parent: 'Vehicle'),
        CategoryDef(name: 'Vehicle Parking', icon: 'parking', color: 0xFF9E9E9E, parent: 'Vehicle'),
        CategoryDef(name: 'Toll', icon: 'toll_booth', color: 0xFF8D6E63, parent: 'Vehicle'),
        CategoryDef(name: 'Challan / Fine', icon: 'receipt', color: 0xFFD32F2F, parent: 'Vehicle'),

        // Mods & accessories
        CategoryDef(name: 'Modifications', icon: 'repair', color: 0xFFE91E63, parent: 'Vehicle'),
        CategoryDef(name: 'Accessories', icon: 'shopping_bag', color: 0xFF9C27B0, parent: 'Vehicle'),

        // Bike specific
        CategoryDef(name: 'Riding Gear', icon: 'bike', color: 0xFF263238, parent: 'Vehicle'),

        // Income
        CategoryDef(name: 'Vehicle Sale', icon: 'directions_car', color: 0xFF4CAF50, type: CategoryType.income),
        CategoryDef(name: 'Insurance Claim', icon: 'insurance', color: 0xFF2196F3, type: CategoryType.income),
      ];
}
