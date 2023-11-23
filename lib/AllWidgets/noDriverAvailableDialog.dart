import 'package:flutter/material.dart';

class NoDriverAvailableDialog extends StatelessWidget {
  const NoDriverAvailableDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(0),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(4)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text('Водитель не найден',
                    style: TextStyle(fontSize: 22, fontFamily: 'Rowdies')),
                const SizedBox(height: 25),
                const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                        'Поблизости не найдено ни одного доступного драйвера, мы рекомендуем вам повторить попытку в ближайшее время',
                        textAlign: TextAlign.center)),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(17),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Закрыть',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Icon(Icons.car_repair, color: Colors.white, size: 26),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
