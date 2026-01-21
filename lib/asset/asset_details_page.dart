import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/messages.dart';
import 'package:thingsboard_app/core/context/tb_context.dart';
import 'package:thingsboard_app/core/entity/entity_details_page.dart';
import 'package:thingsboard_app/thingsboard_client.dart';

class AssetDetailsPage extends EntityDetailsPage<AssetInfo> {
  AssetDetailsPage(TbContext tbContext, String assetId, {super.key})
      : super(
          tbContext,
          entityId: assetId,
          defaultTitle: 'Activo',
          subTitle: 'Detalles del activo',
        );

  @override
  Future<AssetInfo?> fetchEntity(String id) {
    return tbClient.getAssetService().getAssetInfo(id);
  }

  @override
  Widget buildEntityDetails(BuildContext context, AssetInfo entity) {
    return Container(
      color: Color(0xFF0D2743),
      //color: Colors.black,
      child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(S.of(context).assetName, style: labelTextStyle),
          Text(entity.name,
              style: valueTextStyle.copyWith(
                color: Colors.lime,
              ),
              //style: valueTextStyle
          ),
          const SizedBox(height: 16),
          Text(S.of(context).type, style: labelTextStyle),
          Text(entity.type,
              style: valueTextStyle.copyWith(
                color: Colors.lime,
              ),
              //style: valueTextStyle
          ),
          const SizedBox(height: 16),
          Text(S.of(context).label, style: labelTextStyle),
          Text(entity.label ?? '',
              style: valueTextStyle.copyWith(
                color: Colors.lime,
              ),
              //style: valueTextStyle
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).assignedToCustomer,
            style: labelTextStyle,
          ),
          Text(entity.customerTitle ?? '',
              style: valueTextStyle.copyWith(
                color: Colors.lime,
              ),
              //style: valueTextStyle
          ),
        ],
      ),
    ),
    );
  }
}
