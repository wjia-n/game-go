import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../audio/sound.dart';
import '../services/store_service.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/wood.dart';

/// Go PRO: Free-vs-Pro comparison, real purchase, restore, and tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
class ProScreen extends StatefulWidget {
  final SoundService audio;
  final GoSettings settings;
  final StoreService store;
  final VoidCallback onBack;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
    required this.onBack,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  @override
  void initState() {
    super.initState();
    GoTheme.use(widget.settings.activeTheme);
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      widget.audio.playWin();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — the whole dojo is yours!',
              style: GoTheme.body(15, color: Colors.white)),
          backgroundColor: GoTheme.kayaDeep,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.playWin();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoTheme.body(15, color: Colors.white)),
        backgroundColor: GoTheme.kayaDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GoTheme.use(widget.settings.activeTheme);
    final s = widget.settings;
    final store = widget.store;
    return Scaffold(
      backgroundColor: GoTheme.tatami,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: GoTheme.kayaDeep),
          onPressed: () {
            widget.audio.playTap();
            widget.onBack();
          },
        ),
        title: Text('Go PRO', style: GoTheme.display(22)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: s,
          builder: (_, _) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Column(
              children: [
                _ComparisonCard(isPro: s.isPro),
                const SizedBox(height: 16),
                _BuyCard(
                  settings: s,
                  store: store,
                  audio: widget.audio,
                ),
                const SizedBox(height: 16),
                _TipsCard(store: store, audio: widget.audio),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Free vs Pro comparison table — buyers see the big difference.
class _ComparisonCard extends StatelessWidget {
  final bool isPro;
  const _ComparisonCard({required this.isPro});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Complete Go game', true, true),
      ('9×9 · 13×13 · 19×19 boards', true, true),
      ('Full rules: ko, superko, scoring', true, true),
      ('Easy & Medium bots', true, true),
      ('Two-player pass-and-play', true, true),
      ('Renameable players', true, true),
      ('Music & sound effects', true, true),
      ('Zen themes', '4', '12+'),
      ('Stone styles', '4', '8'),
      ('Board woods', '2', '8'),
      ('Custom theme creator', false, true),
      ('Hard bot', false, true),
    ];
    return WoodCard(
      child: Column(
        children: [
          Text('Free vs PRO', style: GoTheme.display(20)),
          const SizedBox(height: 4),
          Text(
            'One purchase. Yours forever.',
            style: GoTheme.body(13, color: GoTheme.inkGrey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(
                  flex: 2,
                  child: Text('FREE',
                      style: GoTheme.label(12), textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('PRO',
                      style: GoTheme.label(12), textAlign: TextAlign.center)),
            ],
          ),
          Divider(color: GoTheme.carved, height: 14),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(r.$1, style: GoTheme.body(13)),
                  ),
                  Expanded(flex: 2, child: _Cell(value: r.$2)),
                  Expanded(flex: 2, child: _Cell(value: r.$3)),
                ],
              ),
            ),
          if (isPro)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: GoTheme.kayaHoney.withValues(alpha: 0.25),
                  border: Border.all(color: GoTheme.kayaDeep),
                ),
                child: Text('✦ PRO ACTIVE ✦',
                    style: GoTheme.label(14, color: GoTheme.kayaDeep)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Object value; // bool | String
  const _Cell({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value is bool) {
      final v = value as bool;
      return Text(
        v ? '✓' : '—',
        style: GoTheme.body(15,
            color: v ? GoTheme.kayaDeep : GoTheme.inkGrey.withValues(alpha: 0.4)),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      value as String,
      style: GoTheme.label(12),
      textAlign: TextAlign.center,
    );
  }
}

// ---------------------------------------------------------------------------
class _BuyCard extends StatelessWidget {
  final GoSettings settings;
  final StoreService store;
  final SoundService audio;
  const _BuyCard({
    required this.settings,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final pro = store.proProduct;
    return WoodCard(
      child: Column(
        children: [
          Text('Unlock PRO', style: GoTheme.display(20)),
          const SizedBox(height: 8),
          if (settings.isPro)
            Text('You already own PRO — thank you!',
                style: GoTheme.body(14), textAlign: TextAlign.center)
          else if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: GoTheme.body(14, color: GoTheme.inkGrey),
              textAlign: TextAlign.center,
            )
          else if (pro != null) ...[
            Text(
                pro.description.isNotEmpty
                    ? pro.description
                    : 'Unlock everything in Go, forever.',
                style: GoTheme.body(14),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: store.purchaseInProgress,
              builder: (_, busy, _) => WoodButton(
                label: busy ? 'Working…' : 'Get PRO — ${pro.price}',
                width: 260,
                onTap: busy
                    ? null
                    : () {
                        audio.playTap();
                        store.buyPro();
                      },
              ),
            ),
          ],
          ValueListenableBuilder<String?>(
            valueListenable: store.purchaseError,
            builder: (_, err, _) => err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(err,
                        style: GoTheme.body(13, color: GoTheme.error),
                        textAlign: TextAlign.center),
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              audio.playTap();
              store.restore();
            },
            child: Text('Restore purchases',
                style: GoTheme.label(13, color: GoTheme.kayaDeep)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Consumable tips — pure support, with real store prices.
class _TipsCard extends StatelessWidget {
  final StoreService store;
  final SoundService audio;
  const _TipsCard({required this.store, required this.audio});

  @override
  Widget build(BuildContext context) {
    final tips = [
      store.coffeeProduct,
      store.chocolateProduct,
    ].whereType<ProductDetails>().toList();
    return WoodCard(
      child: Column(
        children: [
          Text('Tip the Maker', style: GoTheme.display(20)),
          const SizedBox(height: 8),
          Text(
            'Go is free forever. A small tip keeps new games coming!',
            style: GoTheme.body(14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: GoTheme.body(13, color: GoTheme.inkGrey),
              textAlign: TextAlign.center,
            )
          else if (tips.isEmpty)
            Text('Tips coming soon.',
                style: GoTheme.body(13, color: GoTheme.inkGrey))
          else
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  _TipChip(
                    label:
                        '${p.id == StoreService.chocolateId ? '🍫' : '🍵'} ${p.price}',
                    onTap: () {
                      audio.playTap();
                      store.buyTip(p);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TipChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: GoTheme.kayaHoney.withValues(alpha: 0.18),
          border: Border.all(
              color: GoTheme.kayaDeep.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Text(label, style: GoTheme.label(14)),
      ),
    );
  }
}
