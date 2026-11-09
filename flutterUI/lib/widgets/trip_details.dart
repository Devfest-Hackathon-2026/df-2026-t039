import 'package:flutter/material.dart';

class TripDetails extends StatelessWidget {
  const TripDetails({super.key, required this.trip});

  final Map<String, dynamic> trip;
  
  String formatTravelMinutes(dynamic minutes) {
    if (minutes == null) return '';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '約 ${hours > 0 ? '$hours時間' : ''}${mins > 0 ? '$mins分' : ''}';
  }

  String parseToJapaneseDate(String date) {
    if (date.isEmpty) return '';
    final parts = date.split('-');
    if (parts.length != 3) return date;
    return '${parts[0]}年${parts[1]}月${parts[2]}日';
  }

  String parseTypeToJapaneseName(String type, String? movement_type) {
    switch(type){
      case "place_entertainment":
        return "観光";
      case "place_food":
        return "食事";
      case "place_accommodation":
        return "宿泊";
      case "movement":
        String tmp = "移動 ";
        switch(movement_type){
          case "walk":
            tmp += "（歩き）";
            break;
          case "train":
            tmp += "（電車）";
            break;
          case "bus":
            tmp += "（バス）";
            break;
          case "car":
            tmp += "（車）";
            break;
          case "taxi":
            tmp += "（タクシー）";
            break;
          case "airplane":
            tmp += "（飛行機）";
            break;
          case "boat":
            tmp += "（船）";
            break;
          default:
            tmp += "（その他）";
        }
        return tmp;
      default:
        return "ノータイプ";
    }
    
  }

  @override
  Widget build(BuildContext context) {
    final itinerary = (trip['itinerary'] as List).cast<List>();

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.lightBlue, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip['title'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.height * 0.03,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${trip['start_date']} ～ ${trip['end_date']} ',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * 0.020,
                        )
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('予算： ${trip['budget']}円',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: MediaQuery.of(context).size.height * 0.020,
                        )
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          spacing: 12,
          children: [
            for (final entry in itinerary.asMap().entries)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    '${entry.key + 1}日目',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  for (final item in entry.value.cast<Map<String, dynamic>>())
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.lightBlue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item['place'] != null) ...[
                            Text(
                              '${item['place']['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '${item['place']['location']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (item['type'] != null && item['type'] == 'movement') ...[
                            Text(
                              '${item['title']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              formatTravelMinutes(item['estimated_travel_minutes']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            
                          ],
                          Text(
                            parseTypeToJapaneseName(item["type"], item["movement_type"]),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item['from']} - ${item['to']}'),
                              if (item['price'] != null) ...[
                                Text('約 ${item['price']}円'),
                              ],
                            ],
                          ),
                          if(item['notes'] != null) ...[
                            Text(
                              item['notes'],
                              style: const TextStyle(
                                fontSize: 10,
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
