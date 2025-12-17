import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'book_appointment_page.dart';
import 'all_doctors_screen.dart'; // Import Model Doctor

class DocDetails extends StatefulWidget {
  final Doctor doctor;

  const DocDetails({Key? key, required this.doctor}) : super(key: key);

  @override
  State<DocDetails> createState() => _DocDetailsState();
}

class _DocDetailsState extends State<DocDetails> {
  late Future<List<Map<String, dynamic>>> _reviewsFuture;
  
  double _averageRating = 0.0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _averageRating = (widget.doctor.rating ?? 0.0).toDouble(); 
    _reviewCount = widget.doctor.reviews ?? 0;
    _reviewsFuture = _fetchReviews();
  }

  Future<List<Map<String, dynamic>>> _fetchReviews() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      // 1. Ambil Data Review
      final response = await supabase
          .from('ratings_reviews')
          .select()
          .eq('doctor_id', widget.doctor.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> rawReviews = List<Map<String, dynamic>>.from(response);
      final List<Map<String, dynamic>> enrichedReviews = [];

      // 2. Hitung Statistik
      if (rawReviews.isNotEmpty) {
        double totalStars = 0;
        for (var item in rawReviews) {
          totalStars += (item['rating'] as num).toDouble();
        }
        if (mounted) {
          setState(() {
            _reviewCount = rawReviews.length;
            _averageRating = totalStars / rawReviews.length;
          });
        }
      }

      // 3. Ambil Nama User untuk Setiap Review
      for (var review in rawReviews) {
        final userId = review['user_id'];
        String displayName = "Anonymous";

        // Cek: Apakah ini review saya sendiri?
        if (currentUser != null && userId == currentUser.id) {
          // Ambil dari Metadata Auth (Nama yang dipakai saat login/signup)
          displayName = currentUser.userMetadata?['full_name'] ?? 
                        currentUser.userMetadata?['name'] ?? 
                        'Me';
        } else {
          // Cek: Apakah ini review orang lain? Ambil dari tabel profiles (jika ada)
          try {
            // Asumsi tabel kamu bernama 'profiles' dan kolom nama 'full_name'
            // Kalau nama tabelmu 'users', ganti 'profiles' jadi 'users'
            final userProfile = await supabase
                .from('profiles') 
                .select('full_name')
                .eq('id', userId)
                .maybeSingle();
            
            if (userProfile != null) {
              displayName = userProfile['full_name'] ?? "Patient";
            }
          } catch (_) {
            // Kalau tabel profiles belum dibuat, biarkan Anonymous
          }
        }

        // Masukkan nama yang ketemu ke dalam data review
        final newMap = Map<String, dynamic>.from(review);
        newMap['user_name'] = displayName; 
        enrichedReviews.add(newMap);
      }

      return enrichedReviews;

    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Doctor Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- DOCTOR HEADER CARD ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.doctor.profileImageUrl,
                            width: 80, height: 80, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.person, size: 40, color: Colors.grey));
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.doctor.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(widget.doctor.specialization, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text('${widget.doctor.clinicName}, ${widget.doctor.location}', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- STATS ROW ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(Icons.people, '2,000+', 'patients'),
                        
                        // Experience Fix (Regex untuk ambil angka saja)
                        _buildStatItem(
                          Icons.work,
                          widget.doctor.experience != null 
                              ? '${widget.doctor.experience!.replaceAll(RegExp(r'[^0-9]'), '')}+' 
                              : '0+', 
                          'years'
                        ),
                        
                        _buildStatItem(Icons.star, _averageRating.toStringAsFixed(1), 'rating'),
                        _buildStatItem(Icons.chat, '$_reviewCount', 'reviews'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),

            // --- ABOUT & WORKING TIME ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About me', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.doctor.name} is a specialist in ${widget.doctor.specialization}. Dedicated to providing the best healthcare services.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text('Working Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Monday-Friday, 08.00 AM-18.00 PM', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- REVIEWS LIST ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () {}, child: const Text('See All')),
                    ],
                  ),
                  
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _reviewsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                      }
                      if (snapshot.hasError) return const Text("Failed to load reviews.");
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          alignment: Alignment.center,
                          child: const Text("No reviews yet. Be the first to review!", style: TextStyle(color: Colors.grey)),
                        );
                      }

                      return Column(
                        children: snapshot.data!.map((reviewData) {
                          return _buildReviewCard(reviewData);
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => BookAppointmentPage(doctor: widget.doctor)));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E2A3B),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Book Appointment', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1E2A3B), size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> data) {
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewText = data['review'] ?? '';
    
    // --- AMBIL NAMA DARI DATA YANG SUDAH KITA PROSES DIATAS ---
    final patientName = data['user_name'] ?? "HealthPal Patient"; 

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue[100],
                child: const Icon(Icons.person, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      children: [
                        Text('$rating', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              size: 14, color: Colors.orange,
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(reviewText, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}