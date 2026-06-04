import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/payment_service.dart';
import '../../theme/payment_tokens.dart';
import '../../widgets/card_input_field.dart';

class CardNumberSpacedFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 19 ? digits.substring(0, 19) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(trimmed[i]);
    }
    final s = buf.toString();
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

class ExpiryMmYyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    var s = digits;
    if (digits.length >= 2) {
      s = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

class CvvDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final t = digits.length > 4 ? digits.substring(0, 4) : digits;
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

bool luhnCheck(String digitsOnly) {
  if (digitsOnly.length < 13 || digitsOnly.length > 19) return false;
  var sum = 0;
  var alternate = false;
  for (var i = digitsOnly.length - 1; i >= 0; i--) {
    var n = int.tryParse(digitsOnly[i]);
    if (n == null) return false;
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

bool expiryIsFuture(String mmYy) {
  final parts = mmYy.split('/');
  if (parts.length != 2) return false;
  final m = int.tryParse(parts[0]);
  var y = int.tryParse(parts[1]);
  if (m == null || y == null || m < 1 || m > 12) return false;
  if (y < 100) y += 2000;
  final now = DateTime.now();
  final exp = DateTime(y, m);
  final current = DateTime(now.year, now.month);
  return !exp.isBefore(current);
}

/// Enter new card — returns [SavedCardDisplay] on success.
class CardPaymentScreen extends StatefulWidget {
  const CardPaymentScreen({
    super.key,
    this.initialCard,
  });

  final SavedCardDisplay? initialCard;

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _number = TextEditingController();
  final _holder = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _n1 = FocusNode();
  final _n2 = FocusNode();
  final _n3 = FocusNode();
  final _n4 = FocusNode();

  String? _errNumber;
  String? _errHolder;
  String? _errExpiry;
  String? _errCvv;

  bool get _isEditMode => widget.initialCard != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCard;
    if (initial == null) return;
    _holder.text = initial.holderName;
    _expiry.text = initial.expiryMmYy;
  }

  @override
  void dispose() {
    _number.dispose();
    _holder.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _n1.dispose();
    _n2.dispose();
    _n3.dispose();
    _n4.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    setState(() {
      _errNumber = null;
      _errHolder = null;
      _errExpiry = null;
      _errCvv = null;
    });

    final digits = _number.text.replaceAll(RegExp(r'\D'), '');
    final hasTypedNumber = digits.isNotEmpty;
    if (hasTypedNumber && (digits.length < 13 || !luhnCheck(digits))) {
      setState(() => _errNumber = 'Enter a valid card number');
      return;
    }
    if (!hasTypedNumber && !_isEditMode) {
      setState(() => _errNumber = 'Enter a valid card number');
      return;
    }
    if (_holder.text.trim().length < 3) {
      setState(() => _errHolder = 'Enter cardholder name');
      return;
    }
    if (!expiryIsFuture(_expiry.text.trim())) {
      setState(() => _errExpiry = 'Enter a valid future expiry (MM/YY)');
      return;
    }
    final cvv = _cvv.text.trim();
    if (cvv.length < 3 || cvv.length > 4) {
      setState(() => _errCvv = 'CVV must be 3–4 digits');
      return;
    }

    final last4 = hasTypedNumber
        ? digits.substring(digits.length - 4)
        : widget.initialCard!.last4;
    final parts = _expiry.text.trim().split('/');
    final mm = parts[0].padLeft(2, '0');
    final yy = parts.length > 1 ? parts[1] : '';
    Navigator.of(context).pop(
      SavedCardDisplay(
        last4: last4,
        holderName: _holder.text.trim(),
        expiryMmYy: '$mm/$yy',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: PaymentTokens.pageBackgroundTop,
      appBar: AppBar(
        backgroundColor: PaymentTokens.pageBackgroundTop,
        elevation: 0,
        foregroundColor: PaymentTokens.textPrimary,
        title: const Text(
          'Card details',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PaymentTokens.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardInputField(
                label: 'Card number',
                controller: _number,
                hint: _isEditMode
                    ? 'Leave blank to keep ending ${widget.initialCard!.last4}'
                    : '0000 0000 0000 0000',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CardNumberSpacedFormatter(),
                ],
                errorText: _errNumber,
                focusNode: _n1,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _n2.requestFocus(),
              ),
              const SizedBox(height: 18),
              CardInputField(
                label: 'Card holder name',
                controller: _holder,
                hint: 'NAME ON CARD',
                errorText: _errHolder,
                focusNode: _n2,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _n3.requestFocus(),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CardInputField(
                      label: 'Expiry date',
                      controller: _expiry,
                      hint: 'MM/YY',
                      keyboardType: TextInputType.number,
                      inputFormatters: [ExpiryMmYyFormatter()],
                      errorText: _errExpiry,
                      focusNode: _n3,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _n4.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CardInputField(
                      label: 'CVV',
                      controller: _cvv,
                      hint: '•••',
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CvvDigitsFormatter()],
                      errorText: _errCvv,
                      focusNode: _n4,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _validateAndSave(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _validateAndSave,
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Save card',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
