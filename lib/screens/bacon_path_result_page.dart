import 'package:flutter/material.dart';
import '../services/bacon_service.dart';
import '../widgets/unified_app_bar.dart'; // optional, use if you're wrapping screens consistently

class BaconPathResultPage extends StatefulWidget {
  final int startActorId;
  final String startActorName;

  const BaconPathResultPage({
    super.key,
    required this.startActorId,
    required this.startActorName,
  });

  @override
  State<BaconPathResultPage> createState() => _BaconPathResultPageState();
}

class _BaconPathResultPageState extends State<BaconPathResultPage> {
  bool isLoading = true;
  List<PathStep> pathSteps = [];

  @override
  void initState() {
    super.initState();
    findConnection();
  }

  Future<void> findConnection() async {
    final result = await BaconService.findConnection(
      widget.startActorId,
      widget.startActorName,
    );
    setState(() {
      pathSteps = result;
      isLoading = false;
    });
  }

  Widget _buildStep(int index) {
    final step = pathSteps[index];
    final isActor = step.mediaTitle == null;

    if (isActor) {
      return ListTile(
        title: Text(step.actorName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Actor"),
      );
    } else {
      return ListTile(
        title: Text(step.mediaTitle ?? ""),
        subtitle: Text(step.isTV ? "TV Show" : "Movie"),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('6 Degrees of Kevin Bacon'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : pathSteps.isEmpty
                ? const Center(
                    child: Text(
                      'No connection found within 6 degrees.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    itemCount: pathSteps.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) => _buildStep(index),
                  ),
      ),
    );
  }
}
