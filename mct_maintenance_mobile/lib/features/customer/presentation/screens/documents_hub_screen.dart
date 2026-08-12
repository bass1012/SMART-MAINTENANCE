import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quotes_contracts_screen.dart';
import 'invoices_screen.dart';
import 'maintenance_reports_screen.dart';

/// Hub centralisé de tous les documents client.
///
/// Regroupe en onglets trois écrans existants sans les modifier :
///   • Devis & Contrats  → [QuotesContractsScreen]
///   • Factures          → [InvoicesScreen]
///   • Rapports          → [MaintenanceReportsScreen]
///
/// Chaque onglet est isolé dans son propre [Navigator] local, ce qui
/// permet la navigation interne (ex: detail d'un devis) sans quitter le hub.
/// [AutomaticKeepAliveClientMixin] préserve l'état lors des changements d'onglet.
class DocumentsHubScreen extends StatelessWidget {
  const DocumentsHubScreen({super.key});

  static const _green = Color(0xFF0a543d);
  static const _greenLight = Color(0xFF0d6b4d);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _green,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_green, _greenLight],
              ),
            ),
          ),
          title: Text(
            'Mes Documents',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            labelStyle: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.description_outlined, size: 20),
                text: 'Devis & Contrats',
                iconMargin: EdgeInsets.only(bottom: 2),
              ),
              Tab(
                icon: Icon(Icons.receipt_long_outlined, size: 20),
                text: 'Factures',
                iconMargin: EdgeInsets.only(bottom: 2),
              ),
              Tab(
                icon: Icon(Icons.assignment_outlined, size: 20),
                text: 'Rapports',
                iconMargin: EdgeInsets.only(bottom: 2),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TabShell(child: QuotesContractsScreen()),
            _TabShell(child: InvoicesScreen()),
            _TabShell(child: MaintenanceReportsScreen()),
          ],
        ),
      ),
    );
  }
}

/// Enveloppe chaque onglet dans un [Navigator] local isolé et conserve son état.
///
/// Le [Navigator] local capte les poussées d'écran internes (détail devis,
/// détail facture…) sans quitter le hub ni remonter au Navigator principal.
class _TabShell extends StatefulWidget {
  final Widget child;
  const _TabShell({required this.child});

  @override
  State<_TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<_TabShell>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = _navigatorKey.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else {
          final rootNav = Navigator.of(context, rootNavigator: true);
          if (rootNav.canPop()) {
            rootNav.pop();
          }
        }
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => widget.child,
        ),
      ),
    );
  }
}
