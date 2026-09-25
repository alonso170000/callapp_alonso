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

  const ProspectSection({
    super.key,
    required this.title,
    required this.color,
    required this.prospects,
    this.showAddButton = false,
    this.height = 166,
    this.onOpen,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return HomeTappableCard(
      color: color,
      height: height,
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Column(
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
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
                const HomeCardArrow(),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  if (showAddButton && index == 0) {
                    return _AddProspectTile(onTap: onAdd);
                  }

                  final prospectIndex = showAddButton ? index - 1 : index;
                  return ProspectTile(item: prospects[prospectIndex]);
                },
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemCount: prospects.length + (showAddButton ? 1 : 0),
              ),
            ),
          ],
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
