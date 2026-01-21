import 'package:json_annotation/json_annotation.dart';

part 'ripple_effect_params.g.dart';

@JsonSerializable(explicitToJson: true)
class RippleEffectParams {
  const RippleEffectParams({
    this.color,
    this.amount,
    this.radius,
    this.scale,
    this.duration,
  });

  @JsonKey(name: 'color')
  final String? color;

  @JsonKey(name: 'amount')
  final int? amount;

  @JsonKey(name: 'radius')
  final double? radius;

  @JsonKey(name: 'scale')
  final double? scale;

  @JsonKey(name: 'duration')
  final int? duration;

  factory RippleEffectParams.fromJson(Map<String, dynamic> json) =>
      _$RippleEffectParamsFromJson(json);

  Map<String, dynamic> toJson() => _$RippleEffectParamsToJson(this);
}
