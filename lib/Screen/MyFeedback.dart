import 'package:flutter/material.dart';

class MyFeedback extends StatefulWidget {
  const MyFeedback({super.key});

  @override
  State<MyFeedback> createState() => _MyFeedbackState();
}

class _MyFeedbackState extends State<MyFeedback> {
  final Color surface = const Color(0xFF1F2937);

  DateTime? _startDate;
  DateTime? _endDate;

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required bool isStart,
  }) async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      barrierColor: Colors.black.withOpacity(0.5),
      barrierLabel: "Select Date",
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startController.text =
          "${picked.day}/${picked.month}/${picked.year}";
        } else {
          _endDate = picked;
          _endController.text =
          "${picked.day}/${picked.month}/${picked.year}";
        }
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.all(12),
        title: const Text("Filter"),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0,horizontal: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _startController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Start Date",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _endController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "End Date",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: () => _pickDate(isStart: false),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
              ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            )

      ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // Use _startDate and _endDate here
              Navigator.pop(context);
            },
            child: const Text("Apply",style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("My Feedback",style: TextStyle(
            fontSize: 20,
          color:Colors.white,
        ),),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: IconButton(onPressed: (){
              _showFilterDialog();
            }, icon: Icon(Icons.sort)),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
             Container(
               decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(10),
                 color: surface,
               ),
               child:Padding(
                   padding: EdgeInsets.symmetric(vertical: 10,horizontal: 8),
                 child: Row(
                   children: [
                     _cardRate(figure: 12,title:"Total Review",colorCode:Colors.blueAccent),
                     _cardRate(figure: 4.3,title:"Average Ratings",colorCode:Colors.yellow),
                     _cardRate(figure: 8,title:"Recommendation",colorCode:Colors.green),
                   ],
                 )

               )
             ),
              SizedBox(height: 10,),
              ListView.separated(
                separatorBuilder: (context, index) => SizedBox(height: 10,),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return _feedbackCard();
                  },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _cardRate({required num figure,required String title,required Color colorCode}){
 return Expanded(
   child: Card(
     color: Colors.white,
     shape: RoundedRectangleBorder(
       borderRadius: BorderRadius.circular(10),
     ),
     child: Container(
       padding: EdgeInsets.symmetric(horizontal: 5,vertical: 15),
       child: Column(
         children: [
           Text("$figure",style: TextStyle(
             color: colorCode,
             fontSize: 30,
             fontWeight: FontWeight.bold
           ),),
           SizedBox(height: 5,),
           Text("$title",style: TextStyle(
             fontSize: 13,
             fontWeight: FontWeight.bold,
             color: Colors.grey,
           ))
           ],
       ),
     ),
     ),
 );
}
Widget _feedbackCard() {
  const surface = Color(0xFF1F2937);

  return Container(
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: avatar + title/date + (optional) more icon
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar / photo
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Icon(Icons.oil_barrel,size: 30,)
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Oil Change",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "12 Dec 2025",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Service ID
                  const Text(
                    "Service ID: SM-123456",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating row (4 filled stars, 1 grey) + score + recommendation chip
                  Row(
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const Icon(Icons.star, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text(
                        "4.0",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green, width: 1),
                        ),
                        child: const Text(
                          "Recommended",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Comment
                  const Text(
                    "Great service! The team was quick and professional. "
                        "They explained everything clearly and even gave me advice "
                        "on how to maintain my car better in the future. "
                        "I really appreciate the attention to detail and the friendly attitude. "
                        "Definitely will recommend this service center to my friends and family.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.5, // 👈 adds nicer line spacing
                    ),
                    softWrap: true,
                  ),

                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 3.0,
          children: [
            TextButton(
              onPressed: () {
                // TODO: handle edit
              },
              child: const Text("Edit Details"),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                // TODO: handle view
              },
              child: const Text("View"),
            ),
          ],
        ),
      ],
    ),
  );
}
