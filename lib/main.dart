import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://twvktwrplxoduzawsyin.supabase.co',  // Ganti dengan URL Supabase Anda
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3dmt0d3JwbHhvZHV6YXdzeWluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNzYxOTIsImV4cCI6MjA3OTY1MjE5Mn0.Rqb2PxiaKOZCd8cy1-DqrMlZz2nXn9m7BP-aZEV9rFg',  // Ganti dengan Anon Key dari Supabase Anda
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> users = [];
  bool isLoading = false;  // Status loading

  // Kontroller untuk form input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // Fungsi untuk mengambil data dari tabel "users"
  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });

    final response = await supabase.from('users').select();

    setState(() {
      isLoading = false;
    });

    if (response.isNotEmpty) {
      setState(() {
        users = List<Map<String, dynamic>>.from(response);
      });
    } else {
      print('No data found or error occurred');
    }
  }

  // Fungsi untuk menambahkan data baru ke Supabase
  Future<void> addUser() async {
    final name = _nameController.text;
    final email = _emailController.text;

    // Validasi input
    if (name.isEmpty || email.isEmpty) {
      print('Please enter both name and email');
      return;
    }

    setState(() {
      isLoading = true;  // Menampilkan loading saat proses pengiriman
    });

    final response = await supabase.from('users').insert([
      {'name': name, 'email': email},
    ]);

    setState(() {
      isLoading = false;  // Menghentikan loading setelah selesai
    });

    if (response.isNotEmpty) {
      // Setelah berhasil menambahkan, ambil data terbaru
      fetchUsers();
      _nameController.clear();
      _emailController.clear();
      
      // Tampilkan SnackBar dengan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User berhasil ditambahkan!')),
      );
    } else {
      // Menampilkan error jika ada
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan user')),
      );
      print('Error: Gagal menambahkan user');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Supabase Flutter Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form untuk memasukkan nama dan email
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: addUser,
              child: Text('Add User'),
            ),
            SizedBox(height: 20),
            // Menampilkan data users
            isLoading
                ? Center(child: CircularProgressIndicator()) // Menampilkan loading spinner
                : Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          title: Text(user['name'] ?? 'No Name'),
                          subtitle: Text(user['email'] ?? 'No Email'),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
