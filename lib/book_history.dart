import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'all_doctors_screen.dart'; // Sesuaikan path-nya

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://twvktwrplxoduzawsyin.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3dmt0d3JwbHhvZHV6YXdzeWluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNzYxOTIsImV4cCI6MjA3OTY1MjE5Mn0.Rqb2PxiaKOZCd8cy1-DqrMlZz2nXn9m7BP-aZEV9rFg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Bookings',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyBookingsScreen(),
    );
  }
}

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _reloadKey = 0; // untuk force reload CanceledView

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Canceled'),
            ],
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                UpcomingView(
                  onStatusChanged: () {
                    // kalau ada appointment di-cancel, naikkan reloadKey
                    setState(() {
                      _reloadKey++;
                    });
                  },
                ),
                const CompletedView(),
                CanceledView(
                  key: ValueKey(_reloadKey),
                  onStatusChanged: () {
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AllDoctorsScreen(),
            ),
          ).then((_) {
            _tabController.animateTo(0);
            setState(() {});
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ======================= UPCOMING =======================

class UpcomingView extends StatefulWidget {
  final VoidCallback onStatusChanged;

  const UpcomingView({Key? key, required this.onStatusChanged})
      : super(key: key);

  @override
  State<UpcomingView> createState() => _UpcomingViewState();
}

class _UpcomingViewState extends State<UpcomingView> {
  late Future<List<AppointmentData>> futureAppointments;

  @override
  void initState() {
    super.initState();
    futureAppointments = fetchUpcomingAppointments();
  }

  Future<List<AppointmentData>> fetchUpcomingAppointments() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      debugPrint('No user session');
      return [];
    }

    final now = DateTime.now().toUtc();

    final response = await supabase
        .from('appointments')
        .select('appointment_id, appointment_date, doctor_id, clinic_id')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .gte('appointment_date', now.toIso8601String())
        .order('appointment_date', ascending: true);

    final List data = response as List;

    final appointments = <AppointmentData>[];

    for (final row in data) {
      final doctorId = row['doctor_id'] as String;
      final clinicId = row['clinic_id'] as String;

      final doctor = await supabase
          .from('doctors')
          .select('name, specialization, profile_picture')
          .eq('doctor_id', doctorId)
          .maybeSingle();

      final clinic = await supabase
          .from('clinics')
          .select('clinic_name')
          .eq('clinic_id', clinicId)
          .maybeSingle();

      if (doctor == null || clinic == null) continue;

      appointments.add(
        AppointmentData(
          appointmentId: row['appointment_id'] as String,
          doctorName: doctor['name'] as String? ?? 'Unknown Doctor',
          specialization: doctor['specialization'] as String? ?? 'Unknown',
          clinic: clinic['clinic_name'] as String? ?? 'Unknown Clinic',
          doctorImage: doctor['profile_picture'] as String? ?? '',
          appointmentDate: DateTime.parse(row['appointment_date'] as String),
        ),
      );
    }
    return appointments;
  }

  void _refreshAppointments() {
    setState(() {
      futureAppointments = fetchUpcomingAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refreshAppointments(),
      child: FutureBuilder<List<AppointmentData>>(
        future: futureAppointments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No upcoming appointments'),
            );
          }

          final appointments = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              return AppointmentCard(
                appointment: appointments[index],
                onCancel: () => _showCancelDialog(context, appointments[index]),
                onReschedule: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reschedule appointment')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, AppointmentData appointment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AppointmentCancellationDialog(
          onConfirm: () async {
            await cancelAppointment(appointment.appointmentId);

            if (!mounted) return;

            Navigator.of(dialogContext).pop(); // tutup dialog
            _refreshAppointments(); // refresh upcoming
            widget.onStatusChanged(); // trigger parent (untuk CanceledView reload)

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appointment cancelled successfully'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> cancelAppointment(String appointmentId) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('appointments')
        .update({'status': 'canceled'})
        .eq('appointment_id', appointmentId);
  }
}

// ======================= COMPLETED =======================

class CompletedView extends StatefulWidget {
  const CompletedView({Key? key}) : super(key: key);

  @override
  State<CompletedView> createState() => _CompletedViewState();
}

class _CompletedViewState extends State<CompletedView> {
  late Future<List<AppointmentData>> futureCompletedAppointments;

  @override
  void initState() {
    super.initState();
    futureCompletedAppointments = fetchCompletedAppointments();
  }

  Future<List<AppointmentData>> fetchCompletedAppointments() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      debugPrint('No user session');
      return [];
    }

    final now = DateTime.now().toUtc();

    final response = await supabase
        .from('appointments')
        .select('appointment_id, appointment_date, doctor_id, clinic_id')
        .eq('user_id', user.id)
        .eq('status', 'active') // hanya yang tidak dibatalkan
        .lt('appointment_date', now.toIso8601String()) // sudah lewat
        .order('appointment_date', ascending: false);

    final List data = response as List;
    final appointments = <AppointmentData>[];

    for (final row in data) {
      final doctorId = row['doctor_id'] as String;
      final clinicId = row['clinic_id'] as String;

      final doctor = await supabase
          .from('doctors')
          .select('name, specialization, profile_picture')
          .eq('doctor_id', doctorId)
          .maybeSingle();

      final clinic = await supabase
          .from('clinics')
          .select('clinic_name')
          .eq('clinic_id', clinicId)
          .maybeSingle();

      if (doctor == null || clinic == null) continue;

      appointments.add(
        AppointmentData(
          appointmentId: row['appointment_id'] as String,
          doctorName: doctor['name'] as String? ?? 'Unknown Doctor',
          specialization: doctor['specialization'] as String? ?? 'Unknown',
          clinic: clinic['clinic_name'] as String? ?? 'Unknown Clinic',
          doctorImage: doctor['profile_picture'] as String? ?? '',
          appointmentDate: DateTime.parse(row['appointment_date'] as String),
        ),
      );
    }

    return appointments;
  }

  void _refreshAppointments() {
    setState(() {
      futureCompletedAppointments = fetchCompletedAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refreshAppointments(),
      child: FutureBuilder<List<AppointmentData>>(
        future: futureCompletedAppointments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No completed appointments'),
            );
          }

          final appointments = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              return CompletedAppointmentCard(
                appointment: appointments[index],
              );
            },
          );
        },
      ),
    );
  }
}

// ======================= CANCELED =======================

class CanceledView extends StatefulWidget {
  final VoidCallback onStatusChanged;

  const CanceledView({Key? key, required this.onStatusChanged})
      : super(key: key);

  @override
  State<CanceledView> createState() => _CanceledViewState();
}

class _CanceledViewState extends State<CanceledView> {
  late Future<List<AppointmentData>> futureCanceledAppointments;

  @override
  void initState() {
    super.initState();
    futureCanceledAppointments = fetchCanceledAppointments();
  }

  Future<List<AppointmentData>> fetchCanceledAppointments() async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session == null) {
        print('DEBUG: No user session found');
        return [];
      }

      final userId = session.user.id;

      final appointmentsResponse = await supabase
          .from('appointments')
          .select('appointment_id, appointment_date, doctor_id, clinic_id')
          .eq('user_id', userId)
          .eq('status', 'canceled')
          .order('appointment_date', ascending: false);

      if (appointmentsResponse.isEmpty) {
        return [];
      }

      List<AppointmentData> appointments = [];

      for (var appointmentData in appointmentsResponse) {
        try {
          final doctorId = appointmentData['doctor_id'];
          final clinicId = appointmentData['clinic_id'];

          final doctorResponse = await supabase
              .from('doctors')
              .select('name, specialization, profile_picture')
              .eq('doctor_id', doctorId)
              .maybeSingle();

          final clinicResponse = await supabase
              .from('clinics')
              .select('clinic_name')
              .eq('clinic_id', clinicId)
              .maybeSingle();

          if (doctorResponse != null && clinicResponse != null) {
            final appointment = AppointmentData(
              appointmentId: appointmentData['appointment_id'] ?? '',
              doctorName: doctorResponse['name'] ?? 'Unknown Doctor',
              specialization: doctorResponse['specialization'] ?? 'Unknown',
              clinic: clinicResponse['clinic_name'] ?? 'Unknown Clinic',
              doctorImage: doctorResponse['profile_picture'] ?? '',
              appointmentDate:
                  DateTime.parse(appointmentData['appointment_date']),
            );
            appointments.add(appointment);
          }
        } catch (e) {
          print('Error processing appointment: $e');
          continue;
        }
      }

      return appointments;
    } catch (e) {
      print('Error fetching canceled appointments: $e');
      rethrow;
    }
  }

  void _refreshAppointments() {
    setState(() {
      futureCanceledAppointments = fetchCanceledAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refreshAppointments(),
      child: FutureBuilder<List<AppointmentData>>(
        future: futureCanceledAppointments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No canceled appointments'),
            );
          }

          final appointments = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              return CanceledAppointmentCard(
                appointment: appointments[index],
              );
            },
          );
        },
      ),
    );
  }
}

// ======================= CARDS & DIALOG =======================

class AppointmentCard extends StatelessWidget {
  final AppointmentData appointment;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    required this.onCancel,
    required this.onReschedule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appointment.formattedDate,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: appointment.doctorImage.isNotEmpty
                    ? Image.network(
                        appointment.doctorImage,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.specialization,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointment.clinic,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: onReschedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('Reschedule'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person, color: Colors.white),
    );
  }
}

class CompletedAppointmentCard extends StatelessWidget {
  final AppointmentData appointment;

  const CompletedAppointmentCard({
    Key? key,
    required this.appointment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completed at ${appointment.formattedDate}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: appointment.doctorImage.isNotEmpty
                    ? Image.network(
                        appointment.doctorImage,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.specialization,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointment.clinic,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person, color: Colors.white),
    );
  }
}

class CanceledAppointmentCard extends StatelessWidget {
  final AppointmentData appointment;

  const CanceledAppointmentCard({
    Key? key,
    required this.appointment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Canceled at ${appointment.formattedDate}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: appointment.doctorImage.isNotEmpty
                    ? Image.network(
                        appointment.doctorImage,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.specialization,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointment.clinic,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: OutlinedButton(
                onPressed: () {
                  // Re-book: buka lagi AllDoctorsScreen,
                  // dari sana user pilih dokter dan lanjut ke BookAppointmentPage
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AllDoctorsScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Re-Book',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person, color: Colors.white),
    );
  }
}

class AppointmentCancellationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const AppointmentCancellationDialog({Key? key, required this.onConfirm})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/close_icon.png',
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.close,
                      size: 40,
                      color: Colors.teal[400],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Appointment Cancellation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You are attempting to cancel your appointment. Are you sure you want to proceed with the cancellation?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Go Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= MODEL =======================

class AppointmentData {
  final String appointmentId;
  final String doctorName;
  final String specialization;
  final String clinic;
  final String doctorImage;
  final DateTime appointmentDate;

  AppointmentData({
    required this.appointmentId,
    required this.doctorName,
    required this.specialization,
    required this.clinic,
    required this.doctorImage,
    required this.appointmentDate,
  });

  String get formattedDate {
    final day = appointmentDate.day;
    final month = _getMonthName(appointmentDate.month);
    final year = appointmentDate.year;
    final hour = appointmentDate.hour.toString().padLeft(2, '0');
    final minute = appointmentDate.minute.toString().padLeft(2, '0');
    return '$month $day, $year - $hour:$minute';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}