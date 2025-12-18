//reschedule1.dart
import 'package:flutter/material.dart';
import 'reschedule2.dart';

class Reschedule1Page extends StatefulWidget {
  final String appointmentId;
  final DateTime appointmentDate; // jadwal lama
  final String doctorName;

  const Reschedule1Page({
    super.key,
    required this.appointmentId,
    required this.appointmentDate,
    required this.doctorName,
  });

  @override
  State<Reschedule1Page> createState() => _Reschedule1PageState();
}

class _Reschedule1PageState extends State<Reschedule1Page> {
  DateTime? selectedDate;
  String? selectedTime;

  final List<String> timeSlots = const [
    '09.00 AM',
    '09.30 AM',
    '10.00 AM',
    '10.30 AM',
    '11.00 AM',
    '11.30 AM',
    '03.00 PM',
    '03.30 PM',
    '04.00 PM',
    '04.30 PM',
    '05.00 PM',
    '05.30 PM',
  ];

  @override
  void initState() {
    super.initState();
    final old = widget.appointmentDate;
    selectedDate = DateTime(old.year, old.month, old.day);
    selectedTime = _formatTime(old);
  }

  String _formatTime(DateTime dt) {
    int hour = dt.hour;
    final minute = dt.minute;
    final isPm = hour >= 12;
    final suffix = isPm ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '${hour.toString()}.${minute.toString().padLeft(2, '0')} $suffix';
  }

  DateTime _combineDateAndTime(DateTime date, String timeLabel) {
    final parts = timeLabel.split(' ');
    final hm = parts[0];
    final ampm = parts[1];
    final hmParts = hm.split('.');

    int hour = int.parse(hmParts[0]);
    final minute = int.parse(hmParts[1]);

    if (ampm == 'PM' && hour != 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  bool _isTimeSelectable(String time) {
    if (selectedDate == null) return false;

    // Parse time to check if it's selectable
    final timeParts = time.split(' ');
    final hourMinute = timeParts[0].split('.');
    int hour = int.parse(hourMinute[0]);
    int minute = int.parse(hourMinute[1]);

    if (timeParts[1] == 'PM' && hour != 12) {
      hour += 12;
    } else if (timeParts[1] == 'AM' && hour == 12) {
      hour = 0;
    }

    DateTime now = DateTime.now();
    DateTime todayOnly = DateTime(now.year, now.month, now.day);
    DateTime selectedDateOnly = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);

    bool isSelectable = true;
    if (selectedDateOnly.isAtSameMomentAs(todayOnly)) {
      // If selected date is today, check if time is after now
      DateTime slotTime = DateTime(now.year, now.month, now.day, hour, minute);
      isSelectable = slotTime.isAfter(now) || slotTime.isAtSameMomentAs(DateTime(now.year, now.month, now.day, now.hour, now.minute));
    } else if (selectedDateOnly.isBefore(todayOnly)) {
      // If selected date is before today, only allow if it's the selected time (for editing)
      isSelectable = selectedTime == time;
    }
    // If selected date is after today, all times are selectable

    return isSelectable;
  }

  Future<void> _confirm() async {
    if (selectedDate == null || selectedTime == null) return;

    final newDateTime =
        _combineDateAndTime(selectedDate!, selectedTime!);

    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RescheduleAppointmentScreen(
          appointmentId: widget.appointmentId,
          newDateTime: newDateTime,
          currentDate: widget.appointmentDate,
          currentTime: _formatTime(widget.appointmentDate),
          newDate: selectedDate!,
          newTime: selectedTime!,
          doctorName: widget.doctorName,
        ),
      ),
    );

    if (ok == true && mounted) {
      Navigator.pop(context, true); // ✅ balik ke BookHistory bawa signal
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmEnabled =
        selectedDate != null && selectedTime != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          'Reschedule Appointment',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _pickDate,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1C2833),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    selectedDate == null
                        ? 'Pick a date'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Hour',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: timeSlots.map((t) {
                final isSelected = selectedTime == t;
                final isSelectable = _isTimeSelectable(t);

                return SizedBox(
                  width: 110,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: isSelectable ? () =>
                        setState(() => selectedTime = t) : null,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected
                          ? const Color(0xFF1C2833)
                          : Colors.white,
                      foregroundColor:
                          isSelected ? Colors.white : (isSelectable ? Colors.black : Colors.grey.shade400),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF1C2833)
                            : (isSelectable ? Colors.grey.shade300 : Colors.grey.shade200),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: confirmEnabled ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C2833),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
