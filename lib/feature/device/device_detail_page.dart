import 'package:flutter/material.dart';

class DeviceDetailPage extends StatelessWidget {
  final String deviceName;
  const DeviceDetailPage({super.key, required this.deviceName});

  @override
  Widget build(BuildContext context) {
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final times = ['Morning', 'Afternoon', 'Evening'];
    return Scaffold(
      appBar: AppBar(title: Text(deviceName)),
      body: ListView.builder(
        itemCount: days.length,
        itemBuilder: (context, dayIndex) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(days[dayIndex], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ...times.map((time) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(time, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Enter value',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
