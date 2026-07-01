import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets.dart';
import '../../data/repositories.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});
  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  bool _erreur = false;
  bool _loading = false;

  Future<void> _valider() async {
    setState(() => _loading = true);
    final op = await ref.read(authRepoProvider).loginParPin(_pin);
    if (!mounted) return;
    if (op == null) {
      setState(() {
        _erreur = true;
        _pin = '';
        _loading = false;
      });
      buzz(200);
      return;
    }
    ref.read(operateurCourantProvider.notifier).state = op;
    ref.read(sessionPinProvider.notifier).state = _pin;
    buzzSuccess();
    context.go('/home');
  }

  void _tape(String d) {
    if (_pin.length >= 4 || _loading) return;
    buzz();
    setState(() {
      _erreur = false;
      _pin += d;
    });
    if (_pin.length == 4) _valider();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dim.pad),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: Shadows.soft,
                  ),
                  child: Image.asset('assets/images/logo.png', height: 66),
                ),
                const SizedBox(height: 20),
                const Text("Stock'ESAT",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(_erreur ? 'Code faux, réessayez' : 'Tapez votre code',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: _erreur ? AppColors.rupture : AppColors.textSoft)),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final rempli = i < _pin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: rempli ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                            color: _erreur ? AppColors.rupture : AppColors.primary,
                            width: 3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                SizedBox(
                    height: 34,
                    child: _loading
                        ? const CircularProgressIndicator(strokeWidth: 3)
                        : null),
                const Spacer(),
                _pave(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pave() {
    final touches = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '⌫', '0', ''];
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: touches.map((t) {
        if (t.isEmpty) return const SizedBox();
        final isBack = t == '⌫';
        return Container(
          decoration: BoxDecoration(
            color: isBack ? Colors.transparent : AppColors.surface,
            borderRadius: BorderRadius.circular(Dim.radius),
            boxShadow: isBack ? null : Shadows.soft,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(Dim.radius),
              onTap: () {
                if (isBack) {
                  if (_pin.isNotEmpty) {
                    buzz();
                    setState(() => _pin = _pin.substring(0, _pin.length - 1));
                  }
                } else {
                  _tape(t);
                }
              },
              child: Center(
                child: isBack
                    ? const Icon(Icons.backspace_outlined,
                        size: 28, color: AppColors.textSoft)
                    : Text(t,
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
