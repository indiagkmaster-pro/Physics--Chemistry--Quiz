import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MaterialApp(
      home: ClassSelectionScreen(),
      theme: ThemeData(primarySwatch: Colors.indigo),
      debugShowCheckedModeBanner: false,
    ));

class ClassSelectionScreen extends StatelessWidget {
  final String apiUrl = "https://script.google.com/macros/s/AKfycbwPrINv7pX8F_T4HWMRbsa99Db3d9BKG9LjBxbz0PihPl9B1ijpnsuuJPzmPNhnWCTT/exec";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("JEE Prep - Select Class")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildClassButton(context, "11"),
            SizedBox(height: 20),
            _buildClassButton(context, "12"),
          ],
        ),
      ),
    );
  }

  Widget _buildClassButton(BuildContext context, String className) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SubjectSelectionScreen(apiUrl: apiUrl, selectedClass: className)),
      ),
      child: Text("Class $className"),
    );
  }
}

class SubjectSelectionScreen extends StatelessWidget {
  final String apiUrl;
  final String selectedClass;

  SubjectSelectionScreen({required this.apiUrl, required this.selectedClass});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Subject (Class $selectedClass)")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSubjectTile(context, "Physics", Colors.blue),
          _buildSubjectTile(context, "Chemistry", Colors.orange),
          _buildSubjectTile(context, "Maths", Colors.green),
        ],
      ),
    );
  }

  Widget _buildSubjectTile(BuildContext context, String subject, Color color) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(Icons.book, color: color, size: 40),
        title: Text(subject, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChapterSelectionScreen(
              apiUrl: apiUrl,
              selectedClass: selectedClass,
              selectedSubject: subject,
            ),
          ),
        ),
      ),
    );
  }
}

class ChapterSelectionScreen extends StatefulWidget {
  final String apiUrl;
  final String selectedClass;
  final String selectedSubject;

  ChapterSelectionScreen({required this.apiUrl, required this.selectedClass, required this.selectedSubject});

  @override
  _ChapterSelectionScreenState createState() => _ChapterSelectionScreenState();
}

class _ChapterSelectionScreenState extends State<ChapterSelectionScreen> {
  List chapters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  fetchData() async {
    final response = await http.get(Uri.parse(widget.apiUrl));
    if (response.statusCode == 200) {
      List allData = json.decode(response.body);
      // Filtering unique chapters based on Class and Subject/Tag
      var filtered = allData.where((item) => 
        item['class'].toString() == widget.selectedClass && 
        item['tag'].toString().toLowerCase() == widget.selectedSubject.toLowerCase()
      ).map((item) => item['chapter']).toSet().toList();
      
      setState(() {
        chapters = filtered;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chapters")),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(chapters[index]),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QuizScreen(
                    apiUrl: widget.apiUrl,
                    chapter: chapters[index],
                  )),
                ),
              );
            },
          ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final String apiUrl;
  final String chapter;
  QuizScreen({required this.apiUrl, required this.chapter});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List questions = [];
  int currentIndex = 0;
  bool showSolution = false;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  fetchQuestions() async {
    final response = await http.get(Uri.parse(widget.apiUrl));
    if (response.statusCode == 200) {
      List allData = json.decode(response.body);
      setState(() {
        questions = allData.where((item) => item['chapter'] == widget.chapter).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return Scaffold(body: Center(child: CircularProgressIndicator()));

    var q = questions[currentIndex];
    return Scaffold(
      appBar: AppBar(title: Text(widget.chapter)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Question ${currentIndex + 1}:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(q['question'], style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            _optionButton("A", q['optionA']),
            _optionButton("B", q['optionB']),
            _optionButton("C", q['optionC']),
            _optionButton("D", q['optionD']),
            if (showSolution) ...[
              Divider(),
              Text("Correct Answer: ${q['answer']}", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text("Solution: ${q['explanation']}"),
            ],
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentIndex > 0) ElevatedButton(onPressed: () => setState(() { currentIndex--; showSolution = false; }), child: Text("Previous")),
                ElevatedButton(onPressed: () => setState(() { showSolution = true; }), child: Text("Show Solution")),
                if (currentIndex < questions.length - 1) ElevatedButton(onPressed: () => setState(() { currentIndex++; showSolution = false; }), child: Text("Next")),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _optionButton(String label, String text) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You selected $label"), duration: Duration(milliseconds: 500)));
        },
        child: Text("$label: $text", textAlign: TextAlign.left),
      ),
    );
  }
}
