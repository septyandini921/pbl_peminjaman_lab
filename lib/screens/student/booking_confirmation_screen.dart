//C:\Kuliah\semester5\Moblie\PBL\pbl_peminjaman_lab\lib\screens\student\booking_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/labs/lab_model.dart';
import '../../models/slots/slot_model.dart';
import '../../service/booking_service.dart';
import '../../service/slot_service.dart';

class PeminjamanFormScreen extends StatefulWidget {
  final LabModel lab;
  final SlotModel slot;
  final DateTime selectedDate;

  const PeminjamanFormScreen({
    super.key,
    required this.lab,
    required this.slot,
    required this.selectedDate,
  });

  @override
  State<PeminjamanFormScreen> createState() => _PeminjamanFormScreenState();
}

class _PeminjamanFormScreenState extends State<PeminjamanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();
  final _namaController = TextEditingController();
  final _jumlahController = TextEditingController();
  
  String _selectedTujuan = 'Kelas Pengganti';
  bool _isAgreed = false;
  bool _isLoading = false;

  final List<String> _tujuanOptions = [
    'Kelas Pengganti',
    'Praktikum',
    'Penelitian',
    'Rapat',
    'Lainnya',
  ];

  final BookingService _bookingService = BookingService();
  final SlotService _slotService = SlotService();

  @override
  void dispose() {
    _nimController.dispose();
    _namaController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  // Validasi NIM: harus angka minimal 9 digit
  String? _validateNIM(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIM wajib diisi';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'NIM harus berupa angka';
    }
    if (value.length < 9) {
      return 'NIM minimal 9 digit';
    }
    return null;
  }

  // Validasi Nama: harus huruf
  String? _validateNama(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama wajib diisi';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Nama harus berupa huruf';
    }
    if (value.trim().length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  // Validasi Jumlah: harus angka dan tidak melebihi kapasitas
  String? _validateJumlah(String? value) {
    if (value == null || value.isEmpty) {
      return 'Jumlah orang wajib diisi';
    }
    
    final jumlah = int.tryParse(value);
    if (jumlah == null) {
      return 'Jumlah harus berupa angka';
    }
    
    if (jumlah < 1) {
      return 'Jumlah minimal 1 orang';
    }
    
    if (jumlah > widget.lab.labCapacity) {
      return 'Maksimal ${widget.lab.labCapacity} orang';
    }
    
    return null;
  }

  // Cek apakah form valid dan checkbox dicentang
  bool get _isFormValid {
    return _isAgreed && 
           _formKey.currentState?.validate() == true;
  }

  Future<void> _submitBooking() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Mohon lengkapi semua data dengan benar'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validasi checkbox
    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 8),
              Text('Anda harus menyetujui peraturan terlebih dahulu'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User tidak terautentikasi');
      }

      // Try to book slot secara atomic
      final slotBooked = await _slotService.tryBookSlot(slotId: widget.slot.id);
      
      if (!slotBooked) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Slot sudah dibooking oleh orang lain'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Create booking
      final result = await _bookingService.createBooking(
        lab: widget.lab,
        slot: widget.slot,
        userId: userId,
        nama: _namaController.text.trim(),
        nim: _nimController.text.trim(),
        tujuan: _selectedTujuan,
        participantCount: int.parse(_jumlahController.text),
      );

      if (mounted) {
        if (result == "SUCCESS") {
          // Show success dialog
          await _showSuccessDialog();
          // Return success to previous screen
          Navigator.pop(context, "SUCCESS");
        } else if (result == "SLOT_TIDAK_TERSEDIA") {
          // Release slot if booking creation failed
          await _slotService.releaseSlot(slotId: widget.slot.id);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Slot tidak tersedia'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Release slot if booking creation failed
          await _slotService.releaseSlot(slotId: widget.slot.id);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Gagal membuat peminjaman'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Release slot on error
      await _slotService.releaseSlot(slotId: widget.slot.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showSuccessDialog() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Peminjaman Berhasil!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pengajuan peminjaman Anda telah dikirim.\nSilakan tunggu konfirmasi dari admin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4D55CC),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'SIMPEL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF4D55CC),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        onChanged: () {
          // Rebuild to update button state
          setState(() {});
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Peminjaman',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Tanggal Pinjam
              _buildInfoRow(
                'Tanggal Pinjam',
                _formatDate(widget.selectedDate),
              ),

              // Slot
              _buildInfoRow(
                'Slot',
                '${_formatTime(widget.slot.slotStart)} - ${_formatTime(widget.slot.slotEnd)}',
              ),

              // NIM Field dengan validasi
              _buildInputField(
                label: 'NIM',
                controller: _nimController,
                hint: 'Masukkan NIM Anda',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validateNIM,
                helperText: 'NIM minimal 9 digit',
              ),

              // Nama Field dengan validasi
              _buildInputField(
                label: 'Nama',
                controller: _namaController,
                hint: 'Masukkan nama lengkap',
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
                validator: _validateNama,
                helperText: 'Nama harus berupa huruf',
              ),

              // Jumlah Field dengan validasi
              _buildInputField(
                label: 'Jumlah',
                controller: _jumlahController,
                hint: 'Jumlah peserta',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validateJumlah,
                helperText: 'Maksimal ${widget.lab.labCapacity} orang',
              ),

              // Tujuan Dropdown
              _buildDropdownField(),

              const SizedBox(height: 25),

              // Peraturan
              _buildPeraturanSection(),

              const SizedBox(height: 20),

              // Checkbox Persetujuan
              _buildAgreementCheckbox(),

              const SizedBox(height: 30),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 115,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7986CB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
    required String? Function(String?) validator,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 115,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7986CB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  validator: validator,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF4D55CC),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                if (helperText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      helperText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 115,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7986CB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Tujuan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTujuan,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedTujuan = newValue);
                    }
                  },
                  items: _tujuanOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeraturanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Peraturan:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildPeraturanItem('Dilarang makan di dalam lab'),
        _buildPeraturanItem('Dilarang menggunakan Lab melebihi kapasitas'),
        _buildPeraturanItem('Menjaga kebersihan lab'),
        _buildPeraturanItem(
            'Mengembalikan barang yang telah dipinjam seperti semula'),
        _buildPeraturanItem(
            'Tidak menggunakan lab melebihi durasi slot yang tersedia'),
        _buildPeraturanItem(
            'Melakukan konfirmasi kehadiran pada asisten Lab'),
      ],
    );
  }

  Widget _buildPeraturanItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _isAgreed,
            onChanged: (bool? value) {
              setState(() => _isAgreed = value ?? false);
            },
            activeColor: const Color(0xFF4D55CC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '*Saya bersedia mematuhi peraturan yang berlaku.',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isValid = _isFormValid;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: (isValid && !_isLoading) ? _submitBooking : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid 
              ? const Color(0xFF4D55CC) 
              : Colors.grey.shade300,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: isValid ? 2 : 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Lakukan Peminjaman',
                style: TextStyle(
                  color: isValid ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}