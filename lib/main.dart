import 'dart:async';
import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:flutter_background/flutter_background.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TorchHome(),
    );
  }
}

class TorchHome extends StatefulWidget {
  const TorchHome({super.key});

  @override
  State<TorchHome> createState() => _TorchHomeState();
}

class _TorchHomeState extends State<TorchHome> {
  bool _isTorchOn = false;
  int _selectedMinutes = 0;
  int _selectedSeconds = 0;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;

  void _toggleTorch() async {
    if (_isTorchOn) {
      _stopCountdown();
      await TorchLight.disableTorch();
    } else {
      await TorchLight.enableTorch();
      _startCountdown();
    }
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  void _startCountdown() {
    _remainingSeconds = (_selectedMinutes * 60) + _selectedSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopCountdown();
          _toggleTorch();
        }
      });
    });
  }

  void _stopCountdown() {
    if (_countdownTimer != null) {
      _countdownTimer!.cancel();
      _countdownTimer = null;
    }
  }

  Future<void> _enableBackgroundExecution() async {
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Torch App Running",
      notificationText: "Torch will turn off automatically after the timer.",
      notificationImportance: AndroidNotificationImportance.Default,
      notificationIcon: AndroidResource(name: 'background_icon', defType: 'drawable'), 
    );

    await FlutterBackground.initialize(androidConfig: androidConfig);
    await FlutterBackground.enableBackgroundExecution();
  }

  @override
  void initState() {
    super.initState();
    _enableBackgroundExecution();
  }

  @override
  void dispose() {
    _stopCountdown();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _showTimePicker(BuildContext context) async {
    int selectedMinutes = _selectedMinutes;
    int selectedSeconds = _selectedSeconds;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Timer Duration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text("Minutes:"),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: selectedMinutes,
                    items: List.generate(60, (index) => index).map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        selectedMinutes = newValue;
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const Text("Seconds:"),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: selectedSeconds,
                    items: List.generate(60, (index) => index).map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        selectedSeconds = newValue;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  _selectedMinutes = selectedMinutes;
                  _selectedSeconds = selectedSeconds;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torch App'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: _toggleTorch,
              child: Text(_isTorchOn ? 'Turn Off' : 'Turn On'),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showTimePicker(context),
            child: Text('Select Timer Duration: $_selectedMinutes min $_selectedSeconds sec'),
          ),
          const SizedBox(height: 20),
          if (_isTorchOn)
            Text(
              'Time Remaining: ${_formatTime(_remainingSeconds)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
