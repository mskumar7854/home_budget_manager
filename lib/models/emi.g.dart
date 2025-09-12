// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emi.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmiAdapter extends TypeAdapter<Emi> {
  @override
  final int typeId = 5;

  @override
  Emi read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Emi(
      name: fields[0] as String?,
      loanAmount: fields[1] as double?,
      emiAmount: fields[2] as double?,
      startDate: fields[3] as DateTime,
      tenureMonths: fields[4] as int,
      interestRate: fields[5] as double?,
      lender: fields[6] as String?,
      monthsPaid: fields[7] as int,
      isActive: fields[8] as bool,
      category: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Emi obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.loanAmount)
      ..writeByte(2)
      ..write(obj.emiAmount)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.tenureMonths)
      ..writeByte(5)
      ..write(obj.interestRate)
      ..writeByte(6)
      ..write(obj.lender)
      ..writeByte(7)
      ..write(obj.monthsPaid)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmiAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
