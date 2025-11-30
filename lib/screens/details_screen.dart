import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/food_item.dart';
import '../widgets/elastic_button.dart';
import '../core/cart.dart';

class DetailsScreen extends StatefulWidget {
  final FoodItem item;
  const DetailsScreen({super.key, required this.item});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> with SingleTickerProviderStateMixin {
  late final TextEditingController _qtyController;
  bool _initialized = false;
  late final AnimationController _rotController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '1');
    _rotController = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _rotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cart = CartProvider.of(context);
    if (!_initialized) {
      final existing = cart.quantityFor(widget.item.id);
      _qtyController.text = (existing > 0 ? existing : 1).toString();
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطبق')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Hero(
                  tag: widget.item.id,
                  child: RotationTransition(
                    turns: _rotController,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.58,
                      height: MediaQuery.of(context).size.width * 0.58,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        widget.item.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stack) {
                          return Container(
                            color: Colors.black26,
                            child: const Center(child: Icon(Icons.broken_image)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.item.price % 1 == 0 ? widget.item.price.toInt() : widget.item.price} IQD',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: cs.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.item.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'الكمية',
                            hintText: 'اكتب العدد المطلوب',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElasticButton(
                          onPressed: () {
                            final qty = int.tryParse(_qtyController.text) ?? 1;
                            final finalQty = qty < 1 ? 1 : qty;
                            cart.setQuantity(widget.item, finalQty);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'أضف إلى السلة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
