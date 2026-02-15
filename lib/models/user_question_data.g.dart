// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_question_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserQuestionDataAdapter extends TypeAdapter<UserQuestionData> {
  @override
  final int typeId = 0;

  @override
  UserQuestionData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserQuestionData(
      questionId: fields[0] as String,
      streak: fields[1] as int,
      easeFactor: fields[2] as double,
      interval: fields[3] as int,
      lastReviewed: fields[4] as DateTime?,
      nextReview: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserQuestionData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.questionId)
      ..writeByte(1)
      ..write(obj.streak)
      ..writeByte(2)
      ..write(obj.easeFactor)
      ..writeByte(3)
      ..write(obj.interval)
      ..writeByte(4)
      ..write(obj.lastReviewed)
      ..writeByte(5)
      ..write(obj.nextReview);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserQuestionDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
