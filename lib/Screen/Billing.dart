import 'package:flutter/material.dart';
import 'package:workshop_assignment/Screen/EditProfile.dart';

class Billing extends StatefulWidget {
  const Billing({super.key});

  @override
  State<Billing> createState() => _BillingState();
}

class _BillingState extends State<Billing> {
  final columns = ["Date", "Amount", "Status","Action"];
  int sortedIndex = 0;
  bool isAscending = true;

  // Keep one list in state
  late List<PendingPaid> _data;

  @override
  void initState() {
    super.initState();
    _data = PendingPaid.getPendingPaid();
  }

  List<DataColumn> getColumns(List<String> columns) {
    return List.generate(columns.length, (index) {
      return DataColumn(
        label: Text(columns[index]),
        onSort: onSort, // wire sort
      );
    });
  }

  // Helper: parse "RM 2,450.00" -> 2450.00
  double _amountToDouble(String amt) {
    final cleaned = amt.replaceAll("RM", "").replaceAll(",", "").trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  void onSort(int columnIndex, bool ascending) {
    setState(() {
      sortedIndex = columnIndex;
      isAscending = ascending;

      switch (columnIndex) {
        case 0: // Date (YYYY-MM-DD strings compare fine)
          _data.sort((a, b) =>
          ascending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
          break;

        case 1: // Amount (numeric)
          _data.sort((a, b) {
            final da = _amountToDouble(a.amount);
            final db = _amountToDouble(b.amount);
            return ascending ? da.compareTo(db) : db.compareTo(da);
          });
          break;

        case 2: // Status (alpha)
          _data.sort((a, b) => ascending
              ? a.status.compareTo(b.status)
              : b.status.compareTo(a.status));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Billing",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StatCard(
              title: "Total Outstanding",
              amount: "RM 2,450.00",
              color: Colors.purple,
              icon: Icons.receipt_long,
            ),
            const SizedBox(height: 12),
            const StatCard(
              title: "Paid This Month",
              amount: "RM 1,890.00",
              color: Colors.green,
              icon: Icons.check_circle,
            ),
            const SizedBox(height: 12),
            const StatCard(
              title: "Overdue",
              amount: "RM 560.00",
              color: Colors.red,
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 20),


            Padding(
              padding: const EdgeInsets.fromLTRB(5, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: const [
                      Icon(Icons.timer, size: 22, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Text(
                        "Pending Payment",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      sortColumnIndex: sortedIndex,
                      sortAscending: isAscending, // IMPORTANT
                      border: TableBorder.all(color: Colors.grey),
                      dataRowHeight: 50,
                      headingRowHeight: 50,
                      headingTextStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      dataTextStyle: const TextStyle(fontSize: 14),
                      columns: getColumns(columns),
                      rows: _data
                          .map(
                            (item) => DataRow(
                          cells: [
                            DataCell(Text(item.date)),
                            DataCell(Text(item.amount)),
                            DataCell(Text(item.status)),
                            DataCell(
                                TextButton.icon(
                                  label: Text("Paid Now"),
                                  onPressed: (){
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const EditProfile()),
                                    );
                                  },
                                  icon: Icon(Icons.payment,size: 16,),
                                )
                            )
                          ],
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

    );
  }
}

class PendingPaid {
  final String date;
  final String amount;
  final String status;

  PendingPaid({
    required this.date,
    required this.amount,
    required this.status,
  });

  static List<PendingPaid> getPendingPaid() {
    return [
      PendingPaid(date: "2025-08-01", amount: "RM 350.00", status: "Pending"),
      PendingPaid(date: "2025-08-05", amount: "RM 420.00", status: "Overdue"),
      PendingPaid(date: "2025-08-10", amount: "RM 180.00", status: "Overdue"),
      PendingPaid(date: "2025-08-15", amount: "RM 600.00", status: "Pending"),
      PendingPaid(date: "2025-08-20", amount: "RM 250.00", status: "Overdue"),
    ];
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 12.0;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(radius),
                bottomLeft: Radius.circular(radius),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.95), color.withOpacity(0.35)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
