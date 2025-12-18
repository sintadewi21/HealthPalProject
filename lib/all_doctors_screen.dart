import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'docdetails.dart';

/// ========= MODEL DOKTER =========

class Doctor {
  final String id;              // uuid dari Supabase
  final String name;
  final String specialization;  // General, Cardiology, Dentistry, dst.
  final String clinicName;
  final String location;        // contoh: "Seattle, USA"
  final double rating;
  final int? reviews;           // optional, kalau belum ada di DB boleh null
  final String profileImageUrl;
  final String? experience;        // years of experience
  final String? education;      // education background

  const Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.clinicName,
    required this.location,
    required this.rating,
    required this.profileImageUrl,
    this.reviews,
    this.experience,
    this.education,
  });
}

/// ========= ALL DOCTORS SCREEN =========

class AllDoctorsScreen extends StatefulWidget {
  final String? initialFilter;  // contoh: "Cardiology"
  final String? initialQuery;   // contoh: "David"

  const AllDoctorsScreen({
    super.key,
    this.initialFilter,
    this.initialQuery,
  });

  @override
  State<AllDoctorsScreen> createState() => _AllDoctorsScreenState();
}

class _AllDoctorsScreenState extends State<AllDoctorsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final List<String> filters = const [
    'All',
    'General',
    'Cardiology',
    'Dentistry',
    'Gynecology',
    'Orthopedic Surgery',
    'Pediatrics',
    // Kalau mau tambahin lain: Pulmonology, Neurology, dll
  ];

  late String selectedFilter;
  String searchQuery = '';

  late TextEditingController _searchController;

  List<Doctor> _allDoctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // set filter awal dari Home (kategori)
    if (widget.initialFilter != null && filters.contains(widget.initialFilter)) {
      selectedFilter = widget.initialFilter!;
    } else {
      selectedFilter = 'All';
    }

    // set query awal dari Home (search)
    searchQuery = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: searchQuery);

    _fetchDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. QUERY: Ambil data dokter DAN data rating dari tabel review
      final response = await _supabase
          .from('doctors')
          .select('*, ratings_reviews(rating), clinics(*)');

      final List data = response as List;

      _allDoctors = data.map<Doctor>((raw) {
        // --- LOGIKA HELPER (Clinic Location) ---
        final clinic = raw['clinics'] as Map<String, dynamic>?;
        final clinicName = clinic?['clinic_name'] as String? ?? 'Unknown Clinic';
        final city = clinic?['city'] as String? ?? '';
        final country = clinic?['country'] as String? ?? '';
        final location = (city.isNotEmpty && country.isNotEmpty)
            ? '$city, $country'
            : (city.isNotEmpty ? city : country);

        // --- BAGIAN PENTING: MENGHITUNG RATING ---
        // Kita ambil list review mentah yang didapat dari query diatas
        final reviewsList = raw['ratings_reviews'] as List?;
        
        double finalRating = 0.0; // Default kalau belum ada review
        int totalReviews = 0;     // Default jumlah review

        if (reviewsList != null && reviewsList.isNotEmpty) {
           double totalStars = 0;
           for (var r in reviewsList) {
             // Ambil angka rating, tambahkan ke total
             totalStars += (r['rating'] as num).toDouble();
           }
           // Rumus Rata-rata: Total Bintang / Jumlah Orang Review
           finalRating = totalStars / reviewsList.length;
           totalReviews = reviewsList.length;
        }
        // ------------------------------------------

        return Doctor(
          id: raw['doctor_id'] as String,
          name: raw['name'] as String,
          specialization: raw['specialization'] as String,
          clinicName: clinicName,
          location: location,
          
          // Masukkan HASIL HITUNGAN ke sini, bukan data mentah dari DB
          rating: finalRating, 
          
          profileImageUrl: raw['profile_picture'] as String? ??
              'https://via.placeholder.com/150',
          experience: raw['experience'] as String?,
          education: raw['education'] as String?,
          
          // Masukkan JUMLAH REVIEW agar teks "0 Reviews" di kartu ikut berubah
          reviews: totalReviews, 
        );
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<Doctor> get filteredDoctors {
    return _allDoctors.where((d) {
      // filter spesialisasi
      if (selectedFilter != 'All' && d.specialization != selectedFilter) {
        return false;
      }

      // filter search nama dokter
      if (searchQuery.isNotEmpty &&
          !d.name.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final doctors = filteredDoctors;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'All Doctors',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search doctor...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final f = filters[index];
                final bool isActive = f == selectedFilter;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFilter = f;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF101828) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF101828)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isActive ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: filters.length,
            ),
          ),

          const SizedBox(height: 16),

          // Loading / error / found info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isLoading
                ? const Text(
                    'Loading doctors...',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  )
                : _errorMessage != null
                    ? Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.red,
                        ),
                      )
                    : Row(
                        children: [
                          Text(
                            '${doctors.length} found',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: const [
                              Text(
                                'Default',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.swap_vert_rounded,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
          ),

          const SizedBox(height: 10),

          // List of doctors
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : doctors.isEmpty
                    ? const Center(
                        child: Text(
                          'No doctors found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: doctors.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final d = doctors[index];
                          return _DoctorCard(
                            doctor: d,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DocDetails(doctor: d),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// ========= CARD DOKTER =========

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback? onTap;

  const _DoctorCard({required this.doctor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Foto dokter
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 70,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: Image.network(
                    doctor.profileImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama + love
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            doctor.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialization,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${doctor.clinicName}, ${doctor.location}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFA500),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (doctor.reviews != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${doctor.reviews} Reviews',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
