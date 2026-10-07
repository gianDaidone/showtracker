import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../core/services/app_toast.dart';
import '../services/sync_service.dart';
import '../services/local_sync_server.dart';
import '../utils/sync_compressor.dart';
import '../domain/models/sync_payload.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> with SingleTickerProviderStateMixin {
  final _localServer = LocalSyncServer();
  
  bool _isLoading = true;
  String? _qrData;
  bool _isLocalServerActive = false;
  
  // Scanning state
  bool _isProcessingScan = false;
  
  late final MobileScannerController _scannerController;
  late final AnimationController _scanAnimController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _prepareExportData();
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _scannerController.dispose();
    _localServer.stop();
    super.dispose();
  }

  Future<void> _prepareExportData() async {
    try {
      final syncService = ref.read(syncServiceProvider);
      final payload = await syncService.exportData();
      final base64String = SyncCompressor.compressPayload(payload.toJson());
      
      if (base64String.length > 2000) {
        final uri = await _localServer.start(base64String);
        if (uri != null) {
          setState(() {
            _qrData = uri;
            _isLocalServerActive = true;
            _isLoading = false;
          });
          return;
        }
      }
      
      setState(() {
        _qrData = base64String;
        _isLocalServerActive = false;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppToast.show('Errore durante l\'esportazione: $e', type: ToastType.error);
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _processScannedData(String data) async {
    if (_isProcessingScan) return;
    setState(() => _isProcessingScan = true);
    AppToast.show('Sincronizzazione in corso...', type: ToastType.info);
    
    try {
      String base64String = data;
      
      if (data.startsWith('http://')) {
        final response = await http.get(Uri.parse(data)).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Connessione scaduta. Assicurati che i due dispositivi siano sulla stessa rete Wi-Fi e riprova.'),
        );
        if (response.statusCode == 200) {
          base64String = response.body;
        } else {
          throw Exception('Errore ${response.statusCode} dal dispositivo mittente. Riprova.');
        }
      }
      
      final jsonMap = SyncCompressor.decompressPayload(base64String);
      final payload = SyncPayload.fromJson(jsonMap);
      
      final syncService = ref.read(syncServiceProvider);
      await syncService.importData(payload);
      
      syncService.hydrateUnknownMedia();
      
      if (mounted) {
        AppToast.show('Sincronizzazione completata!', type: ToastType.success);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(e.toString().replaceAll('Exception: ', ''), type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingScan = false);
        _scannerController.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text('Trasferimento', style: TextStyle(fontWeight: FontWeight.w600)),
          centerTitle: true,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Mostra QR', icon: Icon(Icons.qr_code_rounded)),
              Tab(text: 'Scansiona QR', icon: Icon(Icons.qr_code_scanner_rounded)),
            ],
            indicatorColor: AppColors.accent,
            indicatorWeight: 3,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            dividerColor: AppColors.divider.withValues(alpha: 0.5),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
        body: TabBarView(
          children: [
            _buildExportTab(),
            _buildImportTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    
    if (_qrData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'Impossibile generare il codice.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        children: [
          const Text(
            'Inquadra questo codice dal tuo\nsecondo dispositivo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary, 
              fontSize: 20, 
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tutto il tuo storico visioni e giochi verrà trasferito offline istantaneamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 48),
          
          // QR Code Card con Glow
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: QrImageView(
              data: _qrData!,
              version: QrVersions.auto,
              size: 220.0,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF161622),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF161622),
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          if (_isLocalServerActive)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.05),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_rounded, color: AppColors.accent, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connessione Locale P2P',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'I dati sono voluminosi. Assicurati che entrambi i dispositivi siano sulla stessa rete Wi-Fi.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _scannerController.stop();
                _processScannedData(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        
        Positioned.fill(
          child: CustomPaint(
            painter: _ScannerOverlayPainter(),
          ),
        ),
        
        Center(
          child: SizedBox(
            width: 260,
            height: 260,
            child: AnimatedBuilder(
              animation: _scanAnimController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ScannerFramePainter(
                    progress: _scanAnimController.value,
                    color: AppColors.accent,
                  ),
                );
              },
            ),
          ),
        ),
        
        const Positioned(
          bottom: 80,
          left: 40,
          right: 40,
          child: Text(
            'Allinea il QR Code all\'interno della cornice.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white, 
              fontSize: 14, 
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
            ),
          ),
        ),
        
        if (_isProcessingScan)
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: AppColors.background.withValues(alpha: 0.7),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.accent, strokeWidth: 3),
                          SizedBox(height: 24),
                          Text(
                            'Sincronizzazione...',
                            style: TextStyle(
                              color: AppColors.textPrimary, 
                              fontSize: 18, 
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Non chiudere l\'applicazione',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.background.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 260,
      height: 260,
    );

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(24)));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerFramePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScannerFramePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const length = 40.0;
    const r = 24.0;

    // Top-Left
    canvas.drawPath(
      Path()
        ..moveTo(0, length)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(length, 0),
      paint,
    );

    // Top-Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - length, 0)
        ..lineTo(size.width - r, 0)
        ..quadraticBezierTo(size.width, 0, size.width, r)
        ..lineTo(size.width, length),
      paint,
    );

    // Bottom-Left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - length)
        ..lineTo(0, size.height - r)
        ..quadraticBezierTo(0, size.height, r, size.height)
        ..lineTo(length, size.height),
      paint,
    );

    // Bottom-Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - length, size.height)
        ..lineTo(size.width - r, size.height)
        ..quadraticBezierTo(size.width, size.height, size.width, size.height - r)
        ..lineTo(size.width, size.height - length),
      paint,
    );

    // Scanning Line
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    
    final scanY = size.height * progress;
    canvas.drawRect(
      Rect.fromLTWH(10, scanY, size.width - 20, 2),
      linePaint,
    );
    
    canvas.drawRect(
      Rect.fromLTWH(10, scanY - 5, size.width - 20, 12),
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
