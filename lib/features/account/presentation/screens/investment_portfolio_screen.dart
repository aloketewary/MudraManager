import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/investment_holding.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/investment_portfolio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';

class InvestmentPortfolioScreen extends ConsumerStatefulWidget {
  final Account account;

  const InvestmentPortfolioScreen({
    super.key,
    required this.account,
  });

  @override
  ConsumerState<InvestmentPortfolioScreen> createState() =>
      _InvestmentPortfolioScreenState();
}

class _InvestmentPortfolioScreenState extends ConsumerState<InvestmentPortfolioScreen> {
  late Future<List<InvestmentHolding>> _holdingsFuture;
  late Future<Map<String, double>> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _holdingsFuture =
          InvestmentPortfolioService.instance.getPortfolio(widget.account.id);
      _metricsFuture = InvestmentPortfolioService.instance
          .getPortfolioMetrics(widget.account.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.account.name} - Portfolio'),
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _metricsFuture,
        builder: (context, metricsSnapshot) {
          if (metricsSnapshot.hasError) {
            return Center(child: Text(BuddyMessages.genericError));
          }
          if (!metricsSnapshot.hasData) {
            return ListView(children: List.generate(3, (_) => DashboardCardSkeleton()));
          }

          final metrics = metricsSnapshot.data!;
          final gainLoss = metrics['gainLoss'] ?? 0;
          final gainLossPercent = metrics['gainLossPercent'] ?? 0;

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Value',
                                      style: textTheme.labelMedium,),
                                  Text(
                                    '${formatCurrency(GuestModeUtil.applyGuestMode(metrics['totalValue'] ?? 0, isGuestMode), decimals: 0)}',
                                    style: textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Gain/Loss',
                                      style: textTheme.labelMedium,),
                                  Text(
                                    '${formatCurrency(GuestModeUtil.applyGuestMode(gainLoss, isGuestMode), decimals: 0)} (${GuestModeUtil.applyGuestMode(gainLossPercent, isGuestMode).toStringAsFixed(2)}%)',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: gainLoss >= 0
                                          ? color.primary
                                          : color.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Cost: ${formatCurrency(GuestModeUtil.applyGuestMode(metrics['totalCost'] ?? 0, isGuestMode), decimals: 0)}',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Holdings',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),),
                ),
                FutureBuilder<List<InvestmentHolding>>(
                  future: _holdingsFuture,
                  builder: (context, holdingsSnapshot) {
                    if (holdingsSnapshot.hasError) {
                      return Center(child: Text(BuddyMessages.genericError));
                    }
                    if (!holdingsSnapshot.hasData) {
                      return Column(children: List.generate(3, (_) => DashboardCardSkeleton()));
                    }

                    final holdings = holdingsSnapshot.data!;
                    if (holdings.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(BuddyMessages.noTransactions),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: holdings.length,
                      itemBuilder: (context, index) {
                        final holding = holdings[index];
                        final gainLoss = holding.gainLoss;
                        final isGain = gainLoss >= 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(holding.symbol,
                                          style: textTheme.titleSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold,),),
                                      Text(holding.name,
                                          style: textTheme.bodySmall,),
                                      Text(
                                          '${holding.quantity} @ ${formatCurrency(holding.currentPrice, decimals: 2)}',
                                          style: textTheme.labelSmall,),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${formatCurrency(GuestModeUtil.applyGuestMode(holding.currentValue, isGuestMode), decimals: 0)}',
                                      style: textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold,),
                                    ),
                                    Text(
                                      '${isGain ? '+' : ''}${formatCurrency(GuestModeUtil.applyGuestMode(gainLoss, isGuestMode), decimals: 0)}',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: isGain
                                            ? color.primary
                                            : color.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHoldingBottomSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddHoldingBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final symbolController = TextEditingController();
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final buyPriceController = TextEditingController();
    final currentPriceController = TextEditingController();
    HoldingType? selectedType = HoldingType.stock;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add Holding',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: symbolController,
                    decoration:
                        const InputDecoration(labelText: 'Symbol (e.g., INFY)'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Symbol is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<HoldingType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Type is required';
                      }
                      return null;
                    },
                    items: HoldingType.values
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.name),
                            ),)
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Quantity is required';
                      }
                      if (double.tryParse(value!) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: buyPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Buy Price'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Buy Price is required';
                      }
                      if (double.tryParse(value!) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: currentPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Current Price'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Current Price is required';
                      }
                      if (double.tryParse(value!) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ctx.pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
                            try {
                              final holding = InvestmentHolding.create(
                                symbol: symbolController.text,
                                name: nameController.text,
                                type: selectedType!,
                                quantity:
                                    double.tryParse(quantityController.text) ?? 0,
                                buyPrice:
                                    double.tryParse(buyPriceController.text) ?? 0,
                                currentPrice: double.tryParse(
                                        currentPriceController.text,) ??
                                    0,
                                purchaseDate: DateTime.now(),
                              );
                              await InvestmentPortfolioService.instance
                                  .addHolding(holding, widget.account.id);
                              _loadData();
                              SnackbarService.info(BuddyMessages.txnAdded);
                              if (mounted) context.pop();
                            } catch (e) {
                              SnackbarService.error(BuddyMessages.errorWith('$e'));
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
