import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/widgets/healthsnap_logo_title.dart';
import 'package:my_app/utils/app_snackbar.dart';

class ReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> report;

  const ReportDetailScreen({super.key, required this.report});

  String _safe(dynamic val) => (val == null || val.toString().isEmpty) ? '---' : val.toString();

  @override
  Widget build(BuildContext context) {
    final parameters = (report['parameters'] as List<dynamic>?) ?? [];
    final generalStatus = _safe(report['generalStatus']);
    final generalStatusNote = _safe(report['generalStatusNote']);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const HealthsnapLogoTitle(),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // MEDICAL DIAGNOSTICS label
                  const Text(
                    'MEDICAL DIAGNOSTICS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B5BDB),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Test Name
                  Text(
                    _safe(report['testName']),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lab Provider + Report Date cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          label: 'LAB PROVIDER',
                          value: _safe(report['labName']),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoChip(
                          label: 'REPORT DATE',
                          value: _safe(report['testDate']),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // General Status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FAF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD1F2E0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF2ECC71),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'General Status: $generalStatus',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                generalStatusNote,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Detailed Parameters table
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
                          child: Text(
                            'Detailed Parameters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width - 40,
                            ),
                            child: Column(
                              children: [
                                // Column labels
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  child: Row(
                                    children: const [
                                      SizedBox(
                                        width: 140,
                                        child: Text('PARAMETER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 1)),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: Text('VALUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 1)),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Text('RANGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 1)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                                ...List.generate(parameters.length, (i) {
                                  final param = parameters[i] as Map<String, dynamic>;
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 140,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(_safe(param['name']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                                                  if ((param['unit'] ?? '').toString().isNotEmpty)
                                                    Text(param['unit'].toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 80,
                                              child: Text(_safe(param['value']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2ECC71))),
                                            ),
                                            SizedBox(
                                              width: 100,
                                              child: Text(_safe(param['range']), style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (i < parameters.length - 1)
                                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // View Original Report Image button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final imageUrl = report['imageUrl']?.toString() ?? '';
                  if (imageUrl.isEmpty) {
                    AppSnackbar.showInfo(
                        context, 'No original image available');
                    return;
                  }
                  final uri = Uri.parse(imageUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (!context.mounted) return;
                    AppSnackbar.showError(context, 'Could not open image');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5BDB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'View Original Report Image',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}
