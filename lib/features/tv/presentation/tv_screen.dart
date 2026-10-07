import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../data/tv_repository.dart';
import 'tv_player_screen.dart';

class TvScreen extends StatefulWidget {
  const TvScreen({super.key});

  @override
  State<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends State<TvScreen> {
  String _cat = 'সব';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('📺 ENJOY TV')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: TvRepository.channels(),
          builder: (context, snap) {
            if (!snap.hasData) return AppStates.loading();
            final all = snap.data!;
            final cats = <String>['সব', ...all.map((c) => c['category'] as String).toSet()];
            final list = _cat == 'সব'
                ? all
                : all.where((c) => c['category'] == _cat).toList();
            return Column(children: [
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (final c in cats)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: _cat == c,
                          onSelected: (_) => setState(() => _cat = c),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? AppStates.empty(title: 'চ্যানেল নেই')
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10),
                        itemCount: list.length,
                        itemBuilder: (_, i) => InkWell(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      TvPlayerScreen(channel: list[i]))),
                          borderRadius: BorderRadius.circular(14),
                          child: Card(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.live_tv,
                                      size: 40, color: AppColors.primary),
                                  const SizedBox(height: 8),
                                  Text('${list[i]['name']}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  Text('${list[i]['category']}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                ]),
                          ),
                        ),
                      ),
              ),
            ]);
          },
        ),
      );
}