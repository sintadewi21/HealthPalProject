//book_appointment_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'all_doctors_screen.dart'; // Import the Doctor model
import 'reschedule1.dart'; // Import the RescheduleAppointmentPage

class BookAppointmentPage extends StatefulWidget {
  final Doctor doctor;
  final String? appointmentId; // Optional for editing existing appointment

  const BookAppointmentPage({Key? key, required this.doctor, this.appointmentId}) : super(key: key);

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  DateTime selectedDate = DateTime(2025, 12, 1);
  DateTime displayedMonth = DateTime(2025, 12);
  String selectedTime = '10.00 AM';
  String? _createdAppointmentId; // Store the ID of the newly created appointment

  @override
  void initState() {
    super.initState();
    if (widget.appointmentId != null) {
      _loadAppointmentData();
    }
  }

  Future<void> _loadAppointmentData() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('appointments')
          .select('appointment_date')
          .eq('appointment_id', widget.appointmentId!)
          .single();

      final appointmentDate = DateTime.parse(response['appointment_date'] as String);
      setState(() {
        selectedDate = appointmentDate;
        displayedMonth = DateTime(appointmentDate.year, appointmentDate.month);
        selectedTime = _formatTime(appointmentDate);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load appointment data: $e')),
      );
    }
  }

Future<bool> _saveAppointment() async {
  try {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      // Handle not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book an appointment')),
      );
      return false;
    }

    // Fetch clinic_id from doctors table using doctor_id
    final doctorResponse = await supabase
        .from('doctors')
        .select('clinic_id')
        .eq('doctor_id', widget.doctor.id)
        .single();

    final clinicId = doctorResponse['clinic_id'] as String;

    // Combine date and time
    final timeParts = selectedTime.split(' ');
    final hourMinute = timeParts[0].split('.');
    int hour = int.parse(hourMinute[0]);
    int minute = int.parse(hourMinute[1]);

    if (timeParts[1] == 'PM' && hour != 12) {
      hour += 12;
    } else if (timeParts[1] == 'AM' && hour == 12) {
      hour = 0;
    }

    final appointmentDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour,
      minute,
    );

    if (widget.appointmentId != null) {
      // Update existing appointment
      await supabase
          .from('appointments')
          .update({
            'appointment_date': appointmentDateTime.toIso8601String(),
          })
          .eq('appointment_id', widget.appointmentId!);
    } else {
      // Insert new appointment (INI PENTING: pakai user.id)
      final response = await supabase
          .from('appointments')
          .insert({
            'user_id': user.id,                    // <- id user yang login
            'doctor_id': widget.doctor.id,
            'clinic_id': clinicId,
            'appointment_date': appointmentDateTime.toIso8601String(),
            'status': 'active',
          })
          .select('appointment_id')
          .single();

      _createdAppointmentId = response['appointment_id'] as String;
    }

    return true; // sukses
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to ${widget.appointmentId != null ? 'update' : 'book'} appointment: $e',
        ),
      ),
    );
    return false; // gagal
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Calendar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              int newMonth = displayedMonth.month - 1;
                              int newYear = displayedMonth.year;
                              if (newMonth < 1) {
                                newMonth = 12;
                                newYear--;
                              }
                              displayedMonth = DateTime(newYear, newMonth, 1);
                            });
                          },
                        ),
                        Text(
                          "${_monthName(displayedMonth.month)} ${displayedMonth.year}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setState(() {
                              int newMonth = displayedMonth.month + 1;
                              int newYear = displayedMonth.year;
                              if (newMonth > 12) {
                                newMonth = 1;
                                newYear++;
                              }
                              displayedMonth = DateTime(newYear, newMonth, 1);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCalendar(),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Select Hour',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Time Slots
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  '09.00 AM', '09.30 AM', '10.00 AM',
                  '10.30 AM', '11.00 AM', '11.30 AM',
                  '3.00 PM', '3.30 PM', '4.00 PM',
                  '4.30 PM', '5.00 PM', '5.30 PM',
                ].map((time) => _buildTimeSlot(time)).toList(),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            await _saveAppointment();
            _showSuccessDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E2A3B),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Confirm',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // SUCCESS DIALOG
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.teal[100],
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your appointment is confirmed for ${_formatDate(selectedDate)}, at $selectedTime.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Back to previous page
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2A3B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    if (_createdAppointmentId != null) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => BookAppointmentPage(
                            doctor: widget.doctor,
                            appointmentId: _createdAppointmentId!,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Edit your appointment',
                    style: TextStyle(
                      color: Color(0xFF1E2A3B),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // CALENDAR BUILDER
  Widget _buildCalendar() {
    final daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    int year = displayedMonth.year;
    int month = displayedMonth.month;

    DateTime firstDay = DateTime(year, month, 1);
    int daysInMonth = DateTime(year, month + 1, 0).day;

    int startWeekday = firstDay.weekday == 7 ? 0 : firstDay.weekday;

    DateTime today = DateTime.now();

    // Calculate start of grid: Sunday of the week containing the first day
    DateTime startOfGrid = firstDay.subtract(Duration(days: startWeekday));

    // Calculate total cells: startWeekday + daysInMonth, then fill to end of week if needed
    int totalCells = startWeekday + daysInMonth;
    int remaining = totalCells % 7;
    if (remaining > 0) {
      totalCells += (7 - remaining);
    }

    return Column(
      children: [
        // Weekday labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: daysOfWeek.map((d) => Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        // Calendar Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            DateTime thisDate = startOfGrid.add(Duration(days: index));
            bool isCurrentMonth = thisDate.year == year && thisDate.month == month;
            bool isSelected = isCurrentMonth && selectedDate.year == year &&
                selectedDate.month == month &&
                selectedDate.day == thisDate.day;
            bool isToday = isCurrentMonth && today.year == year &&
                today.month == month &&
                today.day == thisDate.day;

            return GestureDetector(
              onTap: isCurrentMonth ? () {
                setState(() {
                  selectedDate = thisDate;
                });
              } : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E2A3B)
                      : isToday
                          ? Colors.blue.shade100
                          : Colors.transparent,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "${thisDate.day}",
                    style: TextStyle(
                      fontSize: 14.0,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? Colors.blue.shade800
                              : isCurrentMonth
                                  ? Colors.black
                                  : Colors.grey.withOpacity(0.6),
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  
  // TIME SLOT WIDGET
  Widget _buildTimeSlot(String time) {
    final isSelected = time == selectedTime;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTime = time;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2A3B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E2A3B) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // HELPERS
  String _monthName(int month) {
    const names = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return names[month - 1];
  }

  String _formatDate(DateTime d) {
    return "${_monthName(d.month)} ${d.day}, ${d.year}";
  }

  String _formatTime(DateTime d) {
    int hour = d.hour;
    String period = 'AM';
    if (hour >= 12) {
      period = 'PM';
      if (hour > 12) hour -= 12;
    }
    if (hour == 0) hour = 12;
    return "${hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')} $period";
  }
}