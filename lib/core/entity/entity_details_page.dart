import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/messages.dart';
import 'package:thingsboard_app/core/context/tb_context.dart';
import 'package:thingsboard_app/core/context/tb_context_widget.dart';
import 'package:thingsboard_app/thingsboard_client.dart';
import 'package:thingsboard_app/widgets/tb_app_bar.dart';
import 'package:thingsboard_app/widgets/tb_progress_indicator.dart';

abstract class EntityDetailsPage<T extends BaseData> extends TbPageWidget {
  final labelTextStyle =
      const TextStyle(color: Color(0xFF757575), fontSize: 14, height: 20 / 14);

  final valueTextStyle =
      const TextStyle(color: Color(0xFF282828), fontSize: 14, height: 20 / 14);

  final String _defaultTitle;
  final String _entityId;
  final String? _subTitle;
  final bool _showLoadingIndicator;
  final bool _hideAppBar;
  final double? _appBarElevation;

  EntityDetailsPage(
    TbContext tbContext, {
    required String defaultTitle,
    required String entityId,
    String? subTitle,
    bool showLoadingIndicator = true,
    bool hideAppBar = false,
    double? appBarElevation,
    super.key,
  })  : _defaultTitle = defaultTitle,
        _entityId = entityId,
        _subTitle = subTitle,
        _showLoadingIndicator = showLoadingIndicator,
        _hideAppBar = hideAppBar,
        _appBarElevation = appBarElevation,
        super(tbContext);

  @override
  State<StatefulWidget> createState() => _EntityDetailsPageState();

  Future<T?> fetchEntity(String id);

  ValueNotifier<String>? detailsTitle() {
    return null;
  }

  Widget buildEntityDetails(BuildContext context, T entity);
}

class _EntityDetailsPageState<T extends BaseData>
    extends TbPageState<EntityDetailsPage<T>> {
  late Future<T?> entityFuture;
  late ValueNotifier<String> titleValue;

  @override
  void initState() {
    super.initState();
    entityFuture = widget.fetchEntity(widget._entityId);
    ValueNotifier<String>? detailsTitle = widget.detailsTitle();
    if (detailsTitle == null) {
      titleValue = ValueNotifier(widget._defaultTitle);
      entityFuture.then((value) {
        if (value is HasName) {
          titleValue.value = (value as HasName).getName();
        }
      });
    } else {
      titleValue = detailsTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF091D30),
      //backgroundColor: Colors.white,
      appBar: widget._hideAppBar
          ? null
          : TbAppBar(
              tbContext,
              showLoadingIndicator: widget._showLoadingIndicator,
              elevation: widget._appBarElevation,
              title: ValueListenableBuilder<String>(
                valueListenable: titleValue,
                builder: (context, title, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: widget._subTitle != null
                              ? Theme.of(context)
                                  .primaryTextTheme
                                  .titleLarge!
                                  .copyWith(fontSize: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                      if (widget._subTitle != null)
                        Text(
                          widget._subTitle!,
                          style: TextStyle(
                            /*
                            color: Theme.of(context)
                                .primaryTextTheme
                                .titleLarge!
                                .color!
                                .withAlpha((0.38 * 255).ceil()),
                             */
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            height: 16 / 12,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
      body: FutureBuilder<T?>(
        future: entityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            var entity = snapshot.data;
            if (entity != null) {
              return widget.buildEntityDetails(context, entity);
            } else {
              return const Center(
                child: Text('Requested entity does not exists.'),
              );
            }
          } else {
            return const Center(
              child: TbProgressIndicator(
                size: 50.0,
              ),
            );
          }
        },
      ),
    );
  }
}

abstract class ContactBasedDetailsPage<T extends ContactBased>
    extends EntityDetailsPage<T> {
  ContactBasedDetailsPage(
    TbContext tbContext, {
    required String defaultTitle,
    required String entityId,
    String? subTitle,
    bool showLoadingIndicator = true,
    bool hideAppBar = false,
    double? appBarElevation,
    super.key,
  }) : super(
          tbContext,
          defaultTitle: defaultTitle,
          entityId: entityId,
          subTitle: subTitle,
          showLoadingIndicator: showLoadingIndicator,
          hideAppBar: hideAppBar,
          appBarElevation: appBarElevation,
        );

  @override
  Widget buildEntityDetails(BuildContext context, T entity) {
    return Container(
      color: Color(0xFF0D2743),
      //color: Colors.black,
      child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(S.of(context).title, style: labelTextStyle),
          //Text('Title', style: labelTextStyle),
          Text(entity.getName(),
              style: valueTextStyle.copyWith(
                color: Colors.lime,
              ),
              //style: valueTextStyle
          ),
          const SizedBox(height: 16),
          Text(S.of(context).country, style: labelTextStyle),
          //Text('Country', style: labelTextStyle),
          Text(entity.country ?? '',
              style: valueTextStyle.copyWith(
                color: Colors.lime,
              ),
              //style: valueTextStyle
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                fit: FlexFit.tight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(S.of(context).city, style: labelTextStyle),
                    //Text('City', style: labelTextStyle),
                    Text(entity.city ?? '',
                        style: valueTextStyle.copyWith(
                          color: Colors.lime,
                        ),
                        //style: valueTextStyle
                    ),
                  ],
                ),
              ),
              Flexible(
                fit: FlexFit.tight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(S.of(context).stateOrProvince, style: labelTextStyle),
                    //Text('State / Province', style: labelTextStyle),
                    Text(entity.state ?? '',
                        style: valueTextStyle.copyWith(
                          color: Colors.lime,
                        ),
                        //style: valueTextStyle
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(S.of(context).postalCode, style: labelTextStyle),
          //Text('Zip / Postal Code', style: labelTextStyle),
          Text(entity.zip ?? '',
              style: valueTextStyle.copyWith(
                color: Colors.lime,
              ),
              //style: valueTextStyle
          ),
          const SizedBox(height: 16),
          Text(S.of(context).address, style: labelTextStyle),
          //Text('Address', style: labelTextStyle),
          Text(entity.address ?? '',
              style: valueTextStyle.copyWith(
                color: Colors.lime,
              ),
              //style: valueTextStyle
          ),
          const SizedBox(height: 16),
          Text(S.of(context).address2, style: labelTextStyle),
          //Text('Address 2', style: labelTextStyle),
          Text(entity.address2 ?? '',
              style: valueTextStyle.copyWith(
                color: Colors.lime,
              ),
              //style: valueTextStyle
          ),
          const SizedBox(height: 16),
          Text(S.of(context).phone, style: labelTextStyle),
          //Text('Phone', style: labelTextStyle),
          Text(entity.phone ?? '',
              style: valueTextStyle.copyWith(
                color: Colors.lime,
              ),
              //style: valueTextStyle
          ),
          const SizedBox(height: 16),
          Text(S.of(context).email, style: labelTextStyle),
          //Text('Email', style: labelTextStyle),
          Text(entity.email ?? '',
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
