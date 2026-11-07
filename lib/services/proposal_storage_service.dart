import 'package:hive_flutter/hive_flutter.dart';

import '../models/proposal.dart';

class ProposalStorageService {
  static const _boxName = 'proposals';

  static Future<void> initialize() async {
    await Hive.openBox(_boxName);
  }

  Box<dynamic> get _box => Hive.box(_boxName);

  Future<void> saveProposal(Proposal proposal) async {
    await _box.put(proposal.id, proposal.toMap());
  }

  Future<void> deleteProposal(String id) async {
    await _box.delete(id);
  }

  Future<void> saveProposals(List<Proposal> proposals) async {
    final nextIds = proposals.map((proposal) => proposal.id).toSet();
    final currentIds = _box.keys.map((key) => key.toString()).toList();

    for (final id in currentIds) {
      if (!nextIds.contains(id)) {
        await _box.delete(id);
      }
    }

    for (final proposal in proposals) {
      await saveProposal(proposal);
    }
  }

  List<Proposal> getAllProposals() {
    return _box.values
        .map((item) => Proposal.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList()
      ..sort((a, b) => b.receivedDate.compareTo(a.receivedDate));
  }

  Proposal? getProposal(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return Proposal.fromMap(Map<dynamic, dynamic>.from(data as Map));
  }
}
