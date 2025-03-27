import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';

Future<void> uploadCafesFromCSV() async {
  final rawData = await rootBundle.loadString('assets/locations.csv');
  List<List<dynamic>> rows = const CsvToListConverter().convert(rawData);

  final cafesCollection = FirebaseFirestore.instance.collection('cafes');

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    final postcode = row[0].toString();
    final name = row[1];
    final hours = row[2];
    final lat = double.parse(row[3].toString());
    final lon = double.parse(row[4].toString());

    final docId = '${lat}_${lon}'; // Unique doc ID

    await cafesCollection.doc(docId).set({
      'name': name,
      'postcode': postcode,
      'hours': hours,
      'latitude': lat,
      'longitude': lon,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('✅ Uploaded: $name');
  }

  print('🎉 All cafes uploaded to Firestore!');
}
