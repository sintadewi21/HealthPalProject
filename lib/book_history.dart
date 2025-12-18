//book_history.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_review_dialog.dart';  
import 'docdetails.dart';
import 'reschedule1.dart';
import 'all_doctors_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... Inisialisasi Supabase (Biarkan sesuai code aslimu) ...
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Bookings',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MyBookingsScreen(),
    );
  }
}

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  int _reloadKey = 0;     // Deklarasi _reloadKey

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('My Bookings', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // TabBar untuk menavigasi ke Upcoming, Completed, Canceled
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
                Tab(text: 'Canceled'),
              ],
              labelColor: const Color(0xFF1E2A3B),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF1E2A3B),
            ),
          ),
          // TabBarView untuk menampilkan konten berdasarkan tab yang dipilih
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                UpcomingView(onStatusChanged: () => setState(() => _reloadKey++)),
                CompletedView(onStatusChanged: () => setState(() {})),
                CanceledView(key: ValueKey(_reloadKey), onStatusChanged: () => setState(() {})),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AllDoctorsScreen())).then((_) {
            setState(() {});
          });
        },
        backgroundColor: const Color(0xFF1E2A3B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ======================= HELPERS NAVIGASI =======================

void _navigateToDetail(BuildContext context, AppointmentData item) {
  // Disini kita mengirim data ASLI yang sudah diambil dari database
  final doctorObj = Doctor(
    id: item.doctorId, 
    name: item.doctorName,
    specialization: item.specialization,
    profileImageUrl: item.doctorImage,
    clinicName: item.clinic,
    location: "Unknown Location", 
    rating: 0.0, // Nanti dihitung otomatis di halaman DocDetails
    reviews: 0,  // Nanti dihitung otomatis di halaman DocDetails
    
    // --> INI YANG BIKIN EXPERIENCE JADI REAL (Bukan "0" lagi) <--
    // Kita ambil dari item.doctorExperience yang sudah kita fetch dari DB
    experience: item.doctorExperience, 
  );

  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => DocDetails(doctor: doctorObj)),
  );
}

// ======================= UPCOMING VIEW =======================

class UpcomingView extends StatefulWidget {
  final VoidCallback onStatusChanged;
  const UpcomingView({Key? key, required this.onStatusChanged}) : super(key: key);
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
     if (user == null) return [];

     final now = DateTime.now();
     final response = await supabase.from('appointments').select('appointment_id, appointment_date, doctor_id, clinic_id')
        .eq('user_id', user.id).eq('status', 'active').gte('appointment_date', now.toIso8601String()).order('appointment_date', ascending: true);
     
     final appointments = <AppointmentData>[];
     for (final row in response as List) {
        final doctorId = row['doctor_id'];
        
        // --- UPDATE PENTING: AMBIL KOLOM 'experience' DARI DATABASE ---
        final doctor = await supabase
            .from('doctors')
            .select('name, specialization, profile_picture, experience') // <--- Tambah experience disini
            .eq('doctor_id', doctorId)
            .maybeSingle();
            
        final clinic = await supabase.from('clinics').select('clinic_name').eq('clinic_id', row['clinic_id']).maybeSingle();
        
        if (doctor != null && clinic != null) {
           appointments.add(AppointmentData(
             appointmentId: row['appointment_id'],
             doctorId: doctorId,
             doctorName: doctor['name'],
             specialization: doctor['specialization'],
             clinic: clinic['clinic_name'],
             doctorImage: doctor['profile_picture'] ?? '',
             // Simpan experience yang didapat dari DB ke variable lokal
             doctorExperience: doctor['experience'] ?? '0 years', 
             appointmentDate: DateTime.parse(row['appointment_date']),
           ));
        }
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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return const Center(child: Text('No upcoming appointments'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return AppointmentCard(
                appointment: item,
                onCardTap: () => _navigateToDetail(context, item),
                onCancel: () => _showCancelDialog(context, item),
                onReschedule: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Reschedule1Page(
                        appointmentId: item.appointmentId,
                        appointmentDate: item.appointmentDate,
                        doctorName: item.doctorName,
                      ),
                    ),
                  ).then((ok) {
                    if (ok == true) {
                      _refreshAppointments();
                      widget.onStatusChanged();
                    }
                  });
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
      builder: (ctx) => AppointmentCancellationDialog(onConfirm: () async {
        await Supabase.instance.client
        .from('appointments')
        .update({'status': 'cancelled'})
        .eq('appointment_id', appointment.appointmentId);
        if (!mounted) return;
        Navigator.pop(ctx);
        _refreshAppointments();
        widget.onStatusChanged();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment cancelled'), backgroundColor: Colors.red));
      }),
    );
  }
}

// ======================= COMPLETED VIEW =======================

class CompletedView extends StatefulWidget {
  final VoidCallback onStatusChanged;
  const CompletedView({Key? key, required this.onStatusChanged}) : super(key: key);
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
    if (user == null) return [];

    final now = DateTime.now();
    
    // 1. UBAH QUERY: Tambahkan ratings_reviews(*) untuk mengambil data review
    final response = await supabase
        .from('appointments')
        .select('*, ratings_reviews(*)') 
        .eq('user_id', user.id)
        .eq('status', 'active') // atau 'completed' sesuai logic db kamu
        .lt('appointment_date', now.toIso8601String())
        .order('appointment_date', ascending: false);

    final appointments = <AppointmentData>[];
    
    for (final row in response as List) {
      final doctorId = row['doctor_id'];

      // Ambil data dokter
      final doctor = await supabase
          .from('doctors')
          .select('name, specialization, profile_picture, experience')
          .eq('doctor_id', doctorId)
          .maybeSingle();

      // Ambil data klinik
      final clinic = await supabase
          .from('clinics')
          .select('clinic_name')
          .eq('clinic_id', row['clinic_id'])
          .maybeSingle();

      // 👇 LOGIKA BARU: Cek apakah ada review di dalam response
      Map<String, dynamic>? existingReview;
      final reviewsList = row['ratings_reviews'] as List?;
      if (reviewsList != null && reviewsList.isNotEmpty) {
        // Ambil review pertama (karena 1 appointment = 1 review)
        existingReview = reviewsList[0] as Map<String, dynamic>;
      }

      if (doctor != null && clinic != null) {
        appointments.add(AppointmentData(
          appointmentId: row['appointment_id'],
          doctorId: doctorId,
          doctorName: doctor['name'],
          specialization: doctor['specialization'],
          clinic: clinic['clinic_name'],
          doctorImage: doctor['profile_picture'] ?? '',
          doctorExperience: doctor['experience'] ?? '0 years',
          appointmentDate: DateTime.parse(row['appointment_date']),
          
          // 👇 Masukkan data review ke model
          userReview: existingReview, 
        ));
      }
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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return const Center(child: Text('No completed appointments'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return CompletedAppointmentCard(
                appointment: item,
                onCardTap: () => _navigateToDetail(context, item),
                onReBook: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) =>AllDoctorsScreen()));
                },
                onAddReview: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddReviewDialog(
                      appointmentId: item.appointmentId,
                      doctorId: item.doctorId,
                      doctorName: item.doctorName,
                      doctorSpecialization: item.specialization,
                      doctorImage: item.doctorImage,

                      // 👇 KIRIM DATA REVIEW LAMA (kalau ada)
                      existingReview: item.userReview, 
                    
                      onSuccess: _refreshAppointments,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ======================= CANCELED VIEW =======================

class CanceledView extends StatefulWidget {
  final VoidCallback onStatusChanged;
  const CanceledView({Key? key, required this.onStatusChanged}) : super(key: key);
  @override
  State<CanceledView> createState() => _CanceledViewState();
}

class _CanceledViewState extends State<CanceledView> {
  late Future<List<AppointmentData>> futureCanceledAppointments;
  @override
  void initState() { super.initState(); futureCanceledAppointments = fetchCanceledAppointments(); }
  
  Future<List<AppointmentData>> fetchCanceledAppointments() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase.from('appointments').select('appointment_id, appointment_date, doctor_id, clinic_id')
        .eq('user_id', user.id).eq('status', 'cancelled').order('appointment_date', ascending: false);

    final appointments = <AppointmentData>[];
    for (final row in response as List) {
      final doctorId = row['doctor_id'];
      
      // --- UPDATE PENTING: AMBIL KOLOM 'experience' DARI DATABASE ---
      final doctor = await supabase
          .from('doctors')
          .select('name, specialization, profile_picture, experience') // <--- Tambah experience disini
          .eq('doctor_id', doctorId)
          .maybeSingle();
          
      final clinic = await supabase.from('clinics').select('clinic_name').eq('clinic_id', row['clinic_id']).maybeSingle();

      if (doctor != null && clinic != null) {
        appointments.add(AppointmentData(
          appointmentId: row['appointment_id'],
          doctorId: doctorId,
          doctorName: doctor['name'],
          specialization: doctor['specialization'],
          clinic: clinic['clinic_name'],
          doctorImage: doctor['profile_picture'] ?? '',
          // Simpan experience
          doctorExperience: doctor['experience'] ?? '0 years',
          appointmentDate: DateTime.parse(row['appointment_date']),
        ));
      }
    }
    return appointments;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          futureCanceledAppointments = fetchCanceledAppointments();
        });
      },
      child: FutureBuilder<List<AppointmentData>>(
        future: futureCanceledAppointments,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return const Center(child: Text('No canceled appointments'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return CanceledAppointmentCard(
                appointment: snapshot.data![index],
                onCardTap: () => _navigateToDetail(context, snapshot.data![index]),
              );
            },
          );
        },
      ),
    );
  }
}

// ======================= WIDGET CARDS =======================

class AppointmentCard extends StatelessWidget {
  final AppointmentData appointment;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;
  final VoidCallback onCardTap;

  const AppointmentCard({Key? key, required this.appointment, required this.onCancel, required this.onReschedule, required this.onCardTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          children: [
            _buildHeader(appointment),
            const SizedBox(height: 16),
            Row(children: [
               Expanded(child: _buildButton('Cancel', Colors.black, Colors.white, onCancel, isOutlined: true)),
               const SizedBox(width: 12),
               Expanded(child: _buildButton('Reschedule', Colors.white, Colors.black, onReschedule, isOutlined: false)),
            ])
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(AppointmentData apt) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(apt.doctorImage, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_,__,___)=>Container(color:Colors.grey[200], width:64, height:64))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(apt.formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(apt.doctorName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(apt.specialization, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(apt.clinic, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ])),
    ]);
  }

  Widget _buildButton(String text, Color textColor, Color bgColor, VoidCallback onTap, {bool isOutlined = false}) {
    return isOutlined 
      ? OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), child: Text(text, style: TextStyle(color: textColor)))
      : ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: bgColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), child: Text(text, style: TextStyle(color: textColor)));
  }
}

class CompletedAppointmentCard extends StatelessWidget {
  final AppointmentData appointment;
  final VoidCallback onReBook;
  final VoidCallback onAddReview;
  final VoidCallback onCardTap;

  const CompletedAppointmentCard({Key? key, required this.appointment, required this.onReBook, required this.onAddReview, required this.onCardTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasReview = appointment.userReview != null;

    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completed at ${appointment.formattedDate}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),
            Row(children: [
               ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(appointment.doctorImage, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_,__,___)=>Container(color:Colors.grey[200], width:64, height:64))),
               const SizedBox(width: 12),
               Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 Text(appointment.doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                 Text(appointment.specialization, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                 Text(appointment.clinic, style: const TextStyle(fontSize: 11, color: Colors.grey)),
               ])),
            ]),
            const SizedBox(height: 16),
            Row(children: [
               Expanded(child: ElevatedButton(onPressed: onReBook, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black, elevation: 0), child: const Text("Re-Book"))),
               const SizedBox(width: 12),

               // 👇 TOMBOL REVIEW YANG PINTAR
              Expanded(
                child: ElevatedButton(
                  onPressed: onAddReview,
                  style: ElevatedButton.styleFrom(
                    // Kalau Edit, warnanya agak beda dikit biar user ngeh (opsional)
                    backgroundColor: hasReview ? const Color(0xFF2E86C1) : const Color(0xFF1E2A3B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  // Ganti teks sesuai kondisi
                  child: Text(hasReview ? "Edit Review" : "Add Review"),
                )
              )
            ])
          ],
        ),
      ),
    );
  }
}

class CanceledAppointmentCard extends StatelessWidget {
  final AppointmentData appointment;
  final VoidCallback onCardTap;

  const CanceledAppointmentCard({Key? key, required this.appointment, required this.onCardTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Canceled at ${appointment.formattedDate}', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(appointment.doctorImage, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey[200], width: 64, height: 64))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(appointment.doctorName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(appointment.specialization, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(appointment.clinic, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
            ]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), child: const Text('Canceled', style: TextStyle(color: Colors.black)))),
          ],
        ),
      ),
    );
  }
}

class AppointmentCancellationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const AppointmentCancellationDialog({Key? key, required this.onConfirm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, size: 50, color: Colors.orange),
            const SizedBox(height: 10),
            const Text("Are you sure?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Do you really want to cancel this appointment?", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("No"))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: onConfirm, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white)))),
            ])
          ],
        ),
      ),
    );
  }
}

// ======================= MODEL TERBARU =======================
// Pastikan ini ada di bagian paling bawah file book_history.dart

class AppointmentData {
  final String appointmentId;
  final String doctorId;
  final String doctorName;
  final String specialization;
  final String clinic;
  final String doctorImage;
  final String doctorExperience; // <--- Field Baru untuk menyimpan experience dari DB
  final DateTime appointmentDate;

  final Map<String, dynamic>? userReview;

  AppointmentData({
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    required this.clinic,
    required this.doctorImage,
    required this.doctorExperience, // <--- Field Baru
    required this.appointmentDate,
    this.userReview,
  });

  String get formattedDate {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final hour = appointmentDate.hour.toString().padLeft(2, '0');
    final minute = appointmentDate.minute.toString().padLeft(2, '0');
    return '${months[appointmentDate.month - 1]} ${appointmentDate.day}, ${appointmentDate.year} - $hour:$minute';
  }
}