// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ripple_effect_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RippleEffectParams _$RippleEffectParamsFromJson(Map<String, dynamic> json) =>
    RippleEffectParams(
      color: json['color'] as String?,
      amount: (json['amount'] as num?)?.toInt(),
      radius: (json['radius'] as num?)?.toDouble(),
      scale: (json['scale'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RippleEffectParamsToJson(RippleEffectParams instance) =>
    <String, dynamic>{
      'color': instance.color,
      'amount': instance.amount,
      'radius': instance.radius,
      'scale': instance.scale,
      'duration': instance.duration,
    };
