import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import 'package:openfood_models/openfood_models.dart';
import 'upsell_modal.dart';
import '../utils/cart_handler.dart';

class PersoModal extends StatefulWidget {
  final ProductModel product;
  final String emoji;
  final List<Color>? gradient;

  const PersoModal({
    super.key,
    required this.product,
    required this.emoji,
    this.gradient,
  });

  static void show(BuildContext context, {required ProductModel product, required String emoji, List<Color>? gradient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PersoModal(
        product: product,
        emoji: emoji,
        gradient: gradient,
      ),
    );
  }

  @override
  State<PersoModal> createState() => _PersoModalState();
}

class _PersoModalState extends State<PersoModal> {
  int _qty = 1;
  final Map<int, List<int>> _selections = {};
  bool _hasAttemptedSubmit = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize selections for each modifier group
    for (int i = 0; i < widget.product.modifierGroups.length; i++) {
      _selections[i] = [];
      final group = widget.product.modifierGroups[i];
      if (group.minSelections > 0 && group.options.isNotEmpty) {
        // Auto-select first available option if required
        int firstAvailableIndex = group.options.indexWhere((opt) => opt.isAvailable);
        if (firstAvailableIndex != -1) {
          _selections[i]!.add(firstAvailableIndex);
        }
      }
    }
  }

  double get _totalExtrasHT {
    double t = 0;
    for (int i = 0; i < widget.product.modifierGroups.length; i++) {
      final group = widget.product.modifierGroups[i];
      final sel = _selections[i]!;
      for (var idx in sel) {
        t += group.options[idx].extraPrice;
      }
    }
    return t;
  }

  double get _finalTotalHT => (widget.product.priceHT + _totalExtrasHT) * _qty;
  double get _finalTotalTTC => _finalTotalHT * (1 + widget.product.vatRate / 100);

  bool _isSelectionValid() {
    for (int i = 0; i < widget.product.modifierGroups.length; i++) {
      final group = widget.product.modifierGroups[i];
      if (_selections[i]!.length < group.minSelections) {
        return false;
      }
    }
    return true;
  }

  void _addAndUpsell() {
    if (!_isSelectionValid()) {
      setState(() {
        _hasAttemptedSubmit = true;
      });
      // Find first missing group to scroll to
      for (int i = 0; i < widget.product.modifierGroups.length; i++) {
        final group = widget.product.modifierGroups[i];
        if (_selections[i]!.length < group.minSelections) {
          // Estimation de la position (150 header + ~100 par section)
          _scrollController.animateTo(
            150.0 + (i * 150.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          break;
        }
      }
      return;
    }

    List<Map<String, dynamic>> resOptions = [];
    for (int i = 0; i < widget.product.modifierGroups.length; i++) {
      final group = widget.product.modifierGroups[i];
      for (var idx in _selections[i]!) {
        final opt = group.options[idx];
        resOptions.add({
          "name": opt.name,
          "priceHT": opt.extraPrice,
          "groupId": group.id,
          "groupName": group.name,
        });
      }
    }

    // Build unique ID based on options to avoid merging different variants
    String optSignature = "";
    if (resOptions.isNotEmpty) {
      final sortedOpts = resOptions.map((e) => e['name'].toString()).toList()..sort();
      optSignature = "_${sortedOpts.join('_').replaceAll(' ', '_')}";
    }

    CartHandler.addItem(
      context,
      CartItem(
        id: "${widget.product.id}$optSignature",
        name: widget.product.name,
        priceHT: widget.product.priceHT + _totalExtrasHT,
        vatRate: widget.product.vatRate,
        quantity: _qty,
        category: widget.product.category,
        restaurantId: widget.product.restaurantId,
        restaurantName: widget.product.restaurantName,
        selectedOptions: resOptions.isEmpty ? null : resOptions,
      ),
      onSuccess: () {
        Navigator.pop(context); // Fermer PersoModal
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            UpsellModal.show(context, productName: widget.product.name, restaurantId: widget.product.restaurantId, restaurantName: widget.product.restaurantName);
          }
        });
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isValid = _isSelectionValid();
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppTheme.border2),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                // Hero header
                Container(
                  width: double.infinity,
                  height: 150,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: widget.gradient != null ? LinearGradient(
                      colors: widget.gradient!,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ) : null,
                    color: widget.gradient == null ? AppTheme.surface2 : null,
                  ),
                  child: Center(
                    child: Text(widget.emoji, style: const TextStyle(fontSize: 76)),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.name, style: AppTheme.titleStyle.copyWith(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(widget.product.description, style: const TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.5)),
                      const SizedBox(height: 14),
                      Text(
                        "${(widget.product.priceHT * (1 + widget.product.vatRate/100)).toStringAsFixed(2).replaceAll('.', ',')} €",
                        style: const TextStyle(color: AppTheme.greenXl, fontSize: 24, fontWeight: FontWeight.w800),
                      ),const SizedBox(height: 18),
                      
                      // Options dynamiques
                      if (widget.product.modifierGroups.isNotEmpty)
                        ...List.generate(widget.product.modifierGroups.length, (sectionIndex) {
                          final group = widget.product.modifierGroups[sectionIndex];
                          final isRequired = group.minSelections > 0;
                          final isRadio = isRequired && group.maxSelections == 1; 
                          final isMissing = _hasAttemptedSubmit && _selections[sectionIndex]!.length < group.minSelections;
                          
                          Widget sectionContent = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(group.name, style: AppTheme.titleStyle.copyWith(fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(isRequired 
                                ? (group.maxSelections == 1 ? "Obligatoire • 1 seul choix" : "Obligatoire • 1 minimum, jusqu'à ${group.maxSelections}")
                                : "Optionnel • Jusqu'à ${group.maxSelections}", 
                                style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                              const SizedBox(height: 10),
                              
                              ...List.generate(group.options.length, (choiceIndex) {
                                final opt = group.options[choiceIndex];
                                
                                if (!opt.isAvailable) {
                                  return _buildUnavailableOption(opt.name, opt.extraPrice);
                                }
                                if (isRadio) {
                                  return _buildRadioOption(opt.name, sectionIndex, choiceIndex, opt.extraPrice);
                                } else {
                                  return _buildCheckOption(opt.name, sectionIndex, choiceIndex, opt.extraPrice, group.maxSelections);
                                }
                              }),
                              const SizedBox(height: 18),
                            ],
                          );

                          if (isMissing) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.redL.withValues(alpha: 0.1),
                                border: Border.all(color: AppTheme.redL, width: 1.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: sectionContent,
                            ).animate().shakeX(hz: 4, amount: 4);
                          }
                          return sectionContent;
                        }),
                      
                      const SizedBox(height: 6),
                      // Quantity
                      Row(
                        children: [
                          const Expanded(child: Text("Quantité", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() { if (_qty > 1) _qty--; }),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface2,
                                    border: Border.all(color: AppTheme.border2, width: 1.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(child: Text("−", style: TextStyle(color: AppTheme.cream, fontSize: 18))),
                                ),
                              ),
                              SizedBox(
                                width: 44,
                                child: Text(_qty.toString(), textAlign: TextAlign.center, style: AppTheme.titleStyle.copyWith(fontSize: 18)),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _qty++),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface2,
                                    border: Border.all(color: AppTheme.border2, width: 1.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(child: Text("+", style: TextStyle(color: AppTheme.cream, fontSize: 18))),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Submit Btn
                      GestureDetector(
                        onTap: isValid ? _addAndUpsell : () {
                          _addAndUpsell(); // Appelons la méthode pour gérer le visuel d'erreur
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: isValid ? const LinearGradient(
                              colors: [AppTheme.green, Color(0xFF145C26)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ) : null,
                            color: isValid ? null : AppTheme.surface3,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Ajouter au panier", style: AppTheme.titleStyle.copyWith(fontSize: 16, color: isValid ? AppTheme.cream : AppTheme.muted)),
                              Text(
                                "Total : ${_finalTotalTTC.toStringAsFixed(2).replaceAll('.', ',')} €",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isValid ? AppTheme.cream : AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label, int sectionIndex, int choiceIndex, double price) {
    bool isSel = _selections[sectionIndex]!.contains(choiceIndex);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selections[sectionIndex] = [choiceIndex];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1E8B3A).withValues(alpha: 0.10) : AppTheme.surface2,
          border: Border.all(color: isSel ? AppTheme.green : AppTheme.border, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSel ? AppTheme.greenXl : AppTheme.muted, width: 2),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: isSel ? Container(decoration: const BoxDecoration(color: AppTheme.greenXl, shape: BoxShape.circle)) : null,
                ),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            if (price > 0)
              Text("+${price.toStringAsFixed(2).replaceAll('.', ',')} €", style: const TextStyle(color: AppTheme.greenXl, fontSize: 12, fontWeight: FontWeight.w700))
            else
              const Text("Inclus", style: TextStyle(color: AppTheme.greenXl, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckOption(String label, int sectionIndex, int choiceIndex, double price, int maxChoice) {
    bool isSel = _selections[sectionIndex]!.contains(choiceIndex);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSel) {
            _selections[sectionIndex]!.remove(choiceIndex);
          } else {
            if (_selections[sectionIndex]!.length < maxChoice) {
              _selections[sectionIndex]!.add(choiceIndex);
            }
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1E8B3A).withValues(alpha: 0.10) : AppTheme.surface2,
          border: Border.all(color: isSel ? AppTheme.green : AppTheme.border, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isSel ? AppTheme.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: isSel ? AppTheme.green : AppTheme.muted, width: 2),
                  ),
                  child: isSel ? const Center(child: Icon(Icons.check, size: 12, color: Colors.white)) : null,
                ),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            if (price > 0)
              Text("+${price.toStringAsFixed(2).replaceAll('.', ',')} €", style: const TextStyle(color: AppTheme.greenXl, fontSize: 12, fontWeight: FontWeight.w700))
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableOption(String label, double price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        border: Border.all(color: AppTheme.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.border2, width: 2),
                  color: AppTheme.border2,
                ),
              ),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.muted, decoration: TextDecoration.lineThrough)),
            ],
          ),
          const Text("Épuisé", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
