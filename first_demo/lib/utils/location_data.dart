// lib/utils/location_data.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

class LocationData {
  static const String defaultCountry = 'India';

  static const List<String> countries = [
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'United Arab Emirates',
  ];

  static const Map<String, List<String>> statesByCountry = {
    'India': [
      'Maharashtra',
      'Gujarat',
      'Karnataka',
      'Tamil Nadu',
      'Uttar Pradesh',
      'Rajasthan',
      'Madhya Pradesh',
      'Delhi',
      'Kerala',
      'Telangana',
      'Andhra Pradesh',
      'Punjab',
      'Haryana',
      'Bihar',
      'West Bengal',
      'Goa',
      'Himachal Pradesh',
      'Uttarakhand',
      'Jharkhand',
      'Odisha',
      'Assam',
      'Jammu & Kashmir',
    ],
    'United States': ['California', 'Texas', 'Florida', 'New York', 'Illinois'],
    'United Kingdom': ['England', 'Scotland', 'Wales', 'Northern Ireland'],
    'Canada': ['Ontario', 'Quebec', 'British Columbia', 'Alberta'],
    'Australia': ['New South Wales', 'Victoria', 'Queensland', 'Western Australia'],
    'United Arab Emirates': ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman'],
  };

  static const Map<String, List<String>> districtsByState = {
    'Maharashtra': [
      'Ahilyanagar',
      'Akola',
      'Amravati',
      'Beed',
      'Bhandara',
      'Buldhana',
      'Chandrapur',
      'Chhatrapati Sambhajinagar',
      'Dharashiv',
      'Dhule',
      'Gadchiroli',
      'Gondia',
      'Hingoli',
      'Jalgaon',
      'Jalna',
      'Kolhapur',
      'Latur',
      'Mumbai City',
      'Mumbai Suburban',
      'Nagpur',
      'Nanded',
      'Nandurbar',
      'Nashik',
      'Palghar',
      'Parbhani',
      'Pune',
      'Raigad',
      'Ratnagiri',
      'Sangli',
      'Satara',
      'Sindhudurg',
      'Solapur',
      'Thane',
      'Wardha',
      'Washim',
      'Yavatmal',
    ],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar', 'Gandhinagar'],
    'Karnataka': ['Bengaluru Urban', 'Bengaluru Rural', 'Mysuru', 'Mangaluru', 'Hubballi-Dharwad', 'Belagavi'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Varanasi', 'Agra', 'Noida', 'Ghaziabad', 'Prayagraj'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'East Delhi', 'West Delhi'],
  };

  static const Map<String, List<String>> talukasByDistrict = {
    'Mumbai City': ['Mumbai City'],
    'Mumbai Suburban': ['Andheri', 'Borivali', 'Kurla'],
    'Thane': ['Thane', 'Kalyan', 'Bhiwandi', 'Shahapur', 'Murbad', 'Ulhasnagar', 'Ambernath'],
    'Palghar': ['Palghar', 'Dahanu', 'Talasari', 'Jawhar', 'Mokhada', 'Vikramgad', 'Wada', 'Vasai'],
    'Raigad': ['Alibag', 'Pen', 'Panvel', 'Uran', 'Karjat', 'Khalapur', 'Roha', 'Mangaon', 'Tala', 'Murud', 'Mahad', 'Poladpur', 'Shrivardhan', 'Sudhagad', 'Mhasla'],
    'Ratnagiri': ['Ratnagiri', 'Sangameshwar', 'Chiplun', 'Guhagar', 'Dapoli', 'Khed', 'Mandangad', 'Lanja', 'Rajapur'],
    'Sindhudurg': ['Kankavli', 'Vaibhavwadi', 'Kudal', 'Malvan', 'Sawantwadi', 'Vengurla', 'Dodamarg', 'Devgad'],
    'Pune': ['Pune City', 'Haveli', 'Mawal', 'Maval', 'Mulshi', 'Khed', 'Shirur', 'Purandar', 'Bhor', 'Velhe', 'Junnar', 'Ambegaon', 'Daund', 'Indapur', 'Baramati'],
    'Satara': ['Satara', 'Jaoli', 'Koregaon', 'Wai', 'Mahabaleshwar', 'Khandala', 'Phaltan', 'Man', 'Khatav', 'Karad', 'Patan'],
    'Sangli': ['Miraj', 'Kavathe Mahankal', 'Jat', 'Tasgaon', 'Khanapur', 'Atpadi', 'Palus', 'Kadegaon', 'Walwa', 'Shirala'],
    'Kolhapur': ['Karvir', 'Panhala', 'Shahuwadi', 'Kagal', 'Hatkanangale', 'Shirol', 'Radhanagari', 'Gaganbawada', 'Bhudargad', 'Ajra', 'Chandgad'],
    'Solapur': ['North Solapur', 'South Solapur', 'Barshi', 'Akkalkot', 'Madha', 'Karmala', 'Mohol', 'Malshiras', 'Pandharpur', 'Sangole', 'Mangalvedhe'],
    'Nashik': ['Nashik', 'Igatpuri', 'Dindori', 'Peint', 'Trimbakeshwar', 'Kalwan', 'Deola', 'Baglan', 'Malegaon', 'Nandgaon', 'Chandwad', 'Niphad', 'Sinnar', 'Yeola', 'Surgana'],
    'Dhule': ['Dhule', 'Sakri', 'Shirpur', 'Shindkheda'],
    'Nandurbar': ['Nandurbar', 'Navapur', 'Shahada', 'Taloda', 'Akkalkuwa', 'Akrani'],
    'Jalgaon': ['Jalgaon', 'Jamner', 'Erandol', 'Dharangaon', 'Bhusawal', 'Raver', 'Muktainagar', 'Bodwad', 'Yawal', 'Amalner', 'Parola', 'Chopda', 'Pachora', 'Bhadgaon', 'Chalisgaon'],
    'Ahilyanagar': ['Ahilyanagar', 'Akole', 'Jamkhed', 'Karjat', 'Kopargaon', 'Nevasa', 'Parner', 'Pathardi', 'Rahata', 'Rahuri', 'Sangamner', 'Shevgaon', 'Shrigonda', 'Shrirampur'],
    'Ahmednagar': ['Ahilyanagar', 'Akole', 'Jamkhed', 'Karjat', 'Kopargaon', 'Nevasa', 'Parner', 'Pathardi', 'Rahata', 'Rahuri', 'Sangamner', 'Shevgaon', 'Shrigonda', 'Shrirampur'],
    'Chhatrapati Sambhajinagar': ['Chhatrapati Sambhajinagar', 'Kannad', 'Soegaon', 'Sillod', 'Phulambri', 'Khultabad', 'Vaijapur', 'Gangapur', 'Paithan'],
    'Aurangabad': ['Chhatrapati Sambhajinagar', 'Kannad', 'Soegaon', 'Sillod', 'Phulambri', 'Khultabad', 'Vaijapur', 'Gangapur', 'Paithan'],
    'Jalna': ['Jalna', 'Bhokardan', 'Jafrabad', 'Badnapur', 'Ambad', 'Ghansawangi', 'Partur', 'Mantha'],
    'Beed': ['Beed', 'Georai', 'Majalgaon', 'Dharur', 'Wadwani', 'Parli', 'Patoda', 'Ashti', 'Shirur Kasar', 'Ambajogai', 'Kaij'],
    'Dharashiv': ['Dharashiv', 'Tuljapur', 'Umarga', 'Lohara', 'Kalamb', 'Bhum', 'Paranda', 'Washi'],
    'Osmanabad': ['Dharashiv', 'Tuljapur', 'Umarga', 'Lohara', 'Kalamb', 'Bhum', 'Paranda', 'Washi'],
    'Latur': ['Latur', 'Ausa', 'Renapur', 'Nilanga', 'Deoni', 'Udgir', 'Ahmedpur', 'Jalkot', 'Shirur Anantpal', 'Chakur'],
    'Nanded': ['Nanded', 'Ardhapur', 'Mudkhed', 'Bhokar', 'Umri', 'Loha', 'Kandhar', 'Kinwat', 'Himayatnagar', 'Hadgaon', 'Mahur', 'Deglur', 'Mukhed', 'Dharmabad', 'Biloli', 'Naigaon'],
    'Parbhani': ['Parbhani', 'Sonpeth', 'Manwath', 'Pathri', 'Gangakhed', 'Palam', 'Purna', 'Selu', 'Sailu'],
    'Hingoli': ['Hingoli', 'Basmath', 'Kalamnuri', 'Sengaon', 'Aundha Nagnath'],
    'Amravati': ['Amravati', 'Bhatkuli', 'Nandgaon Khandeshwar', 'Dharni', 'Chikhaldara', 'Achalpur', 'Chandurbazar', 'Morshi', 'Warud', 'Daryapur', 'Anjangaon Surji', 'Chandur Railway', 'Dhamangaon Railway', 'Tiosa'],
    'Akola': ['Akola', 'Akot', 'Telhara', 'Balapur', 'Patur', 'Murtizapur', 'Barshitakli'],
    'Washim': ['Washim', 'Malegaon', 'Risod', 'Mangrulpir', 'Karanja', 'Manora'],
    'Buldhana': ['Buldhana', 'Chikhli', 'Deulgaon Raja', 'Jalgaon Jamod', 'Sangrampur', 'Malkapur', 'Motala', 'Nandura', 'Khamgaon', 'Shegaon', 'Mehkar', 'Sindkhed Raja', 'Lonar'],
    'Yavatmal': ['Yavatmal', 'Arni', 'Babhulgaon', 'Darwha', 'Digras', 'Ghatanji', 'Kalamb', 'Kelapur', 'Mahagaon', 'Maregaon', 'Ner', 'Pusad', 'Ralegaon', 'Umarkhed', 'Wani', 'Zari-Jamani'],
    'Wardha': ['Wardha', 'Seloo', 'Deoli', 'Hinganghat', 'Samudrapur', 'Arvi', 'Ashti', 'Karanja'],
    'Nagpur': ['Nagpur Urban', 'Nagpur Rural', 'Kamptee', 'Hingna', 'Katol', 'Narkhed', 'Saoner', 'Kalmeshwar', 'Ramtek', 'Parseoni', 'Kuhi', 'Umred', 'Bhiwapur', 'Mouda'],
    'Bhandara': ['Bhandara', 'Tumsar', 'Pauni', 'Mohadi', 'Sakoli', 'Lakhani', 'Lakhandur'],
    'Gondia': ['Gondia', 'Tirora', 'Goregaon', 'Arjuni Morgaon', 'Deori', 'Sadak Arjuni', 'Salekasa', 'Amgaon'],
    'Chandrapur': ['Chandrapur', 'Ballarpur', 'Warora', 'Chimur', 'Brahmapuri', 'Nagbhid', 'Sindewahi', 'Mul', 'Saoli', 'Gondpipri', 'Rajura', 'Korpana', 'Jiwati', 'Bhadravati', 'Pombhurna'],
    'Gadchiroli': ['Gadchiroli', 'Dhanora', 'Chamorshi', 'Mulchera', 'Desaiganj', 'Armori', 'Kurkheda', 'Korchi', 'Aheri', 'Etapalli', 'Bhamragad', 'Sironcha'],
  };

  static bool _jsonLoaded = false;
  static final Map<String, List<String>> _loadedDistrictsByState = {};
  static final Map<String, List<String>> _loadedTalukasByDistrict = {};
  static final Map<String, Map<String, List<String>>> _loadedRegionsByDistrict = {};
  static final Map<String, List<String>> _allAreasByDistrict = {};
  static final Map<String, String> _localityToDistrict = {};
  static final Map<String, String> _localityToTaluka = {};
  static final Map<String, String> _localityToArea = {};
  static final List<Map<String, String>> _allSearchableEntries = [];

  /// Loads Maharashtra location hierarchy from JSON asset
  static Future<void> loadFromJson() async {
    if (_jsonLoaded) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/maharashtra_locations.json');
      final data = jsonDecode(jsonStr);
      if (data is Map<String, dynamic>) {
        final stateName = data['state'] as String? ?? 'Maharashtra';
        final districtsMap = data['districts'] as Map<String, dynamic>? ?? {};
        final districtList = <String>[];
        _allSearchableEntries.clear();

        districtsMap.forEach((distName, distVal) {
          districtList.add(distName);
          _allSearchableEntries.add({
            'name': distName,
            'type': 'District',
            'state': stateName,
            'district': distName,
            'taluka': '',
            'area': '',
          });

          if (distVal is Map<String, dynamic>) {
            // talukas
            final tList = distVal['talukas'];
            if (tList is List) {
              final talukas = List<String>.from(tList);
              _loadedTalukasByDistrict[distName] = talukas;
              for (final t in talukas) {
                _localityToDistrict[t.toLowerCase()] = distName;
                _localityToTaluka[t.toLowerCase()] = t;
                _allSearchableEntries.add({
                  'name': t,
                  'type': 'Taluka',
                  'state': stateName,
                  'district': distName,
                  'taluka': t,
                  'area': '',
                });
              }
            }

            // regions and areas
            final rMap = distVal['regions'];
            if (rMap is Map<String, dynamic>) {
              final regionsParsed = <String, List<String>>{};
              final areasSet = <String>{};

              rMap.forEach((regionName, localitiesVal) {
                if (localitiesVal is List) {
                  final localities = List<String>.from(localitiesVal);
                  regionsParsed[regionName] = localities;
                  for (final loc in localities) {
                    areasSet.add(loc);
                    _localityToDistrict[loc.toLowerCase()] = distName;
                    _localityToArea[loc.toLowerCase()] = loc;

                    // Match probable taluka based on district & region
                    String assocTaluka = '';
                    if (distName == 'Pune') {
                      if (regionName == 'PMC') assocTaluka = 'Pune City';
                      else if (regionName == 'PCMC') assocTaluka = 'Haveli';
                      else assocTaluka = 'Haveli';
                    } else if (distName == 'Palghar') {
                      assocTaluka = 'Vasai';
                    } else if (distName == 'Raigad') {
                      assocTaluka = 'Panvel';
                    }

                    if (assocTaluka.isNotEmpty && !_localityToTaluka.containsKey(loc.toLowerCase())) {
                      _localityToTaluka[loc.toLowerCase()] = assocTaluka;
                    }

                    _allSearchableEntries.add({
                      'name': loc,
                      'type': 'Area',
                      'state': stateName,
                      'district': distName,
                      'taluka': assocTaluka,
                      'area': loc,
                      'region': regionName,
                    });
                  }
                }
              });

              _loadedRegionsByDistrict[distName] = regionsParsed;
              final sortedAreas = areasSet.toList()..sort();
              _allAreasByDistrict[distName] = sortedAreas;
            }
          }
        });

        districtList.sort();
        _loadedDistrictsByState[stateName] = districtList;
      }
      _jsonLoaded = true;
    } catch (e) {
      debugPrint('Error loading maharashtra_locations.json: $e');
    }
  }

  static List<String> getStates(String country) {
    return statesByCountry[country] ?? ['Central Region', 'State / Province 1', 'State / Province 2'];
  }

  static List<String> getDistricts(String state) {
    if (_loadedDistrictsByState.containsKey(state) && _loadedDistrictsByState[state]!.isNotEmpty) {
      return _loadedDistrictsByState[state]!;
    }
    return districtsByState[state] ?? [
      '$state Central',
      '$state North',
      '$state South',
      '$state East',
      '$state West',
    ];
  }

  static List<String> getTalukas(String district) {
    if (_loadedTalukasByDistrict.containsKey(district) && _loadedTalukasByDistrict[district]!.isNotEmpty) {
      return _loadedTalukasByDistrict[district]!;
    }
    return talukasByDistrict[district] ?? [
      '$district Central Taluka',
      '$district North Taluka',
      '$district South Taluka',
      '$district City',
    ];
  }

  /// Returns areas / localities for a given district
  static List<String> getAreas(String district, {String? region}) {
    if (region != null && _loadedRegionsByDistrict[district]?[region] != null) {
      return _loadedRegionsByDistrict[district]![region]!;
    }
    return _allAreasByDistrict[district] ?? [];
  }

  /// Returns map of region names -> list of localities for that district
  static Map<String, List<String>> getRegions(String district) {
    return _loadedRegionsByDistrict[district] ?? {};
  }

  /// Returns list of region names for that district (e.g. PMC, PCMC)
  static List<String> getRegionNames(String district) {
    return (_loadedRegionsByDistrict[district] ?? {}).keys.toList();
  }

  /// Searches across all districts, talukas, and areas
  static List<Map<String, String>> searchAll(String query, {String? districtFilter}) {
    if (query.trim().isEmpty) {
      if (districtFilter != null && districtFilter.isNotEmpty) {
        return _allSearchableEntries
            .where((e) => e['district']?.toLowerCase() == districtFilter.toLowerCase())
            .take(60)
            .toList();
      }
      return _allSearchableEntries.take(40).toList();
    }
    final q = query.trim().toLowerCase();
    final results = <Map<String, String>>[];

    for (final item in _allSearchableEntries) {
      if (districtFilter != null &&
          districtFilter.isNotEmpty &&
          item['district']?.toLowerCase() != districtFilter.toLowerCase()) {
        continue;
      }
      final name = (item['name'] ?? '').toLowerCase();
      final dist = (item['district'] ?? '').toLowerCase();
      final tal = (item['taluka'] ?? '').toLowerCase();
      final reg = (item['region'] ?? '').toLowerCase();

      if (name.contains(q) || dist.contains(q) || tal.contains(q) || reg.contains(q)) {
        results.add(item);
        if (results.length >= 60) break;
      }
    }
    return results;
  }

  /// Automatically matches district, taluka, and area from address text or locality
  static Map<String, String>? matchLocation(String text, {String? defaultState = 'Maharashtra'}) {
    if (text.isEmpty) return null;
    final lower = text.toLowerCase();

    // 1. Direct locality match from regions or areas
    for (final entry in _localityToArea.entries) {
      if (lower.contains(entry.key)) {
        final dist = _localityToDistrict[entry.key] ?? '';
        final taluka = _localityToTaluka[entry.key] ?? '';
        return {
          'district': dist,
          'taluka': taluka,
          'area': entry.value,
        };
      }
    }

    // 2. Direct locality match from talukas
    for (final entry in _localityToTaluka.entries) {
      if (lower.contains(entry.key)) {
        final dist = _localityToDistrict[entry.key] ?? '';
        return {
          'district': dist,
          'taluka': entry.value,
          'area': '',
        };
      }
    }

    // 3. District name match
    final districts = getDistricts(defaultState ?? 'Maharashtra');
    for (final d in districts) {
      if (lower.contains(d.toLowerCase())) {
        final talukas = getTalukas(d);
        for (final t in talukas) {
          if (lower.contains(t.toLowerCase())) {
            return {'district': d, 'taluka': t, 'area': ''};
          }
        }
        return {'district': d, 'taluka': talukas.isNotEmpty ? talukas.first : '', 'area': ''};
      }
    }

    return null;
  }
}
