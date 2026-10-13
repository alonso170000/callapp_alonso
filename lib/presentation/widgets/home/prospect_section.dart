import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/home_models.dart';

import 'home_card_components.dart';
import 'prospect_tile.dart';

class ProspectSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<ProspectItem> prospects;
  final bool showAddButton;
  final double height;
  final VoidCallback? onOpen;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onProspect;

  const ProspectSection({
    super.key,
    required this.title,
    required this.color,
    required this.prospects,
    this.showAddButton = false,
    this.height = 166,
    this.onOpen,
    this.onAdd,
    this.onProspect,
  });

  @override
  Widget build(BuildContext context) {
    return HomeTappableCard(
      color: color,
      onTap: onOpen,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'SulphurPoint',
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ),
                  const HomeCardArrow(),
                ],
              ),
              
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 9,
                  children: [
                    if (showAddButton) _AddProspectTile(onTap: onAdd),
                    if (prospects.isEmpty) const Text('Sin prospectos'),
                    for (var i = 0; i < prospects.length; i++)
                      InkWell(
                        onTap: onProspect == null ? null : () => onProspect!(i),
                        child: ProspectTile(item: prospects[i]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddProspectTile extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddProspectTile({this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: const SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.add_rounded, color: Colors.black, size: 42),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agregar',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'SulphurPoint',
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
