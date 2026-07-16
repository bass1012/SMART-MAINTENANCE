import re

file_path = '/Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile/lib/features/customer/presentation/screens/quote_detail_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Ajouter les methodes helpers après initState()
helper_methods = """
  String _formatAmount(num amount) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return formatter.format(amount).replaceAll(' ', ' ').replaceAll(',', ' ');
  }

  String _formatQuoteReference(String ref) {
    final RegExp regExp = RegExp(r'(\d{2})(\d{2})(\d{2})');
    return ref.replaceFirstMapped(regExp, (match) {
      String yy = match.group(1)!;
      String mm = match.group(2)!;
      String dd = match.group(3)!;
      return '$dd$mm$yy';
    });
  }
"""

if "_formatAmount" not in content:
    init_state_end = content.find("  }\n\n  Future<void> _downloadQuotePDF")
    if init_state_end != -1:
        content = content[:init_state_end + 4] + helper_methods + "\n" + content[init_state_end + 4:]

# Remplacer les occurrences de montant
# On cherche ${expression} FCFA, ou $variable FCFA, ou ${expression.toStringAsFixed(0)} FCFA
content = re.sub(r'\$\{([^\}]+?)\.toStringAsFixed\(\d+\)\}\s*FCFA', r'${_formatAmount(\1)} FCFA', content)

# Cas speciaux:
content = content.replace("'$halfAmount FCFA", "'${_formatAmount(halfAmount)} FCFA")
content = content.replace("'$totalAmount FCFA", "'${_formatAmount(totalAmount)} FCFA")
content = content.replace("${(_quote.amount / 2).ceil()} FCFA", "${_formatAmount((_quote.amount / 2).ceil())} FCFA")
content = content.replace("${_quote.amount.toInt()} FCFA", "${_formatAmount(_quote.amount.toInt())} FCFA")

# Remplacer la reference du devis uniquement pour l'affichage (pas pour le nom du fichier PDF)
content = content.replace('SelectableText(\n                              _quote.reference,', 'SelectableText(\n                              _formatQuoteReference(_quote.reference),')
content = content.replace("Text('Devis n°${_quote.reference}'", "Text('Devis n°${_formatQuoteReference(_quote.reference)}'")

with open(file_path, 'w') as f:
    f.write(content)
