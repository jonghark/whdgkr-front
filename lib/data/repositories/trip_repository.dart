import 'package:flutter/foundation.dart';
import 'package:whdgkr/core/network/api_client.dart';
import 'package:whdgkr/data/models/trip.dart';
import 'package:whdgkr/data/models/expense.dart';
import 'package:whdgkr/data/models/settlement.dart';

class TripRepository {
  final ApiClient _apiClient;

  TripRepository(this._apiClient);

  void _logError(String method, dynamic error, [StackTrace? stackTrace]) {
    debugPrint('------------------------------------------');
    debugPrint('[TripRepository.$method] Error');
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
    debugPrint('------------------------------------------');
  }

  Future<List<Trip>> getAllTrips() async {
    try {
      debugPrint('[TripRepository.getAllTrips] API call start');
      final response = await _apiClient.dio.get('/trips');
      debugPrint('[TripRepository.getAllTrips] Success: ${response.data}');
      return (response.data as List).map((t) => Trip.fromJson(t)).toList();
    } catch (e, stackTrace) {
      _logError('getAllTrips', e, stackTrace);
      throw Exception('Failed to load trips: $e');
    }
  }

  Future<List<Trip>> getMatchedTrips() async {
    try {
      debugPrint('[TripRepository.getMatchedTrips] API call start');
      final response = await _apiClient.dio.get('/trips/matched');
      debugPrint('[TripRepository.getMatchedTrips] Success: ${response.data}');
      return (response.data as List).map((t) => Trip.fromJson(t)).toList();
    } catch (e, stackTrace) {
      _logError('getMatchedTrips', e, stackTrace);
      throw Exception('Failed to load matched trips: $e');
    }
  }

  Future<Trip> createTrip(Map<String, dynamic> tripData) async {
    try {
      debugPrint('[TripRepository.createTrip] API call: $tripData');
      final response = await _apiClient.dio.post('/trips', data: tripData);
      debugPrint('[TripRepository.createTrip] Success: ${response.data}');
      return Trip.fromJson(response.data);
    } catch (e, stackTrace) {
      _logError('createTrip', e, stackTrace);
      throw Exception('Failed to create trip: $e');
    }
  }

  Future<Trip> getTripById(int id) async {
    try {
      debugPrint('[TripRepository.getTripById] API call: id=$id');
      final response = await _apiClient.dio.get('/trips/$id');
      debugPrint('[TripRepository.getTripById] Success: ${response.data}');
      return Trip.fromJson(response.data);
    } catch (e, stackTrace) {
      _logError('getTripById', e, stackTrace);
      throw Exception('Failed to load trip: $e');
    }
  }

  Future<void> deleteTrip(int tripId) async {
    try {
      debugPrint('[TripRepository.deleteTrip] API call: tripId=$tripId');
      await _apiClient.dio.delete('/trips/$tripId');
      debugPrint('[TripRepository.deleteTrip] Success');
    } catch (e, stackTrace) {
      _logError('deleteTrip', e, stackTrace);
      throw Exception('Failed to delete trip: $e');
    }
  }

  Future<Trip> updateTrip(int tripId, Map<String, dynamic> tripData) async {
    try {
      debugPrint('[TripRepository.updateTrip] API call: tripId=$tripId, data=$tripData');
      final response = await _apiClient.dio.patch('/trips/$tripId', data: tripData);
      debugPrint('[TripRepository.updateTrip] Success: ${response.data}');
      return Trip.fromJson(response.data);
    } catch (e, stackTrace) {
      _logError('updateTrip', e, stackTrace);
      throw Exception('Failed to update trip: $e');
    }
  }

  Future<Participant> addParticipant(int tripId, Map<String, dynamic> participantData) async {
    try {
      debugPrint('[TripRepository.addParticipant] API call: tripId=$tripId, data=$participantData');
      final response = await _apiClient.dio.post('/trips/$tripId/participants', data: participantData);
      debugPrint('[TripRepository.addParticipant] Success: ${response.data}');
      return Participant.fromJson(response.data);
    } catch (e, stackTrace) {
      _logError('addParticipant', e, stackTrace);
      throw Exception('Failed to add participant: $e');
    }
  }

  Future<void> deleteParticipant(int tripId, int participantId) async {
    try {
      debugPrint('[TripRepository.deleteParticipant] API call: tripId=$tripId, participantId=$participantId');
      await _apiClient.dio.delete('/trips/$tripId/participants/$participantId');
      debugPrint('[TripRepository.deleteParticipant] Success');
    } catch (e, stackTrace) {
      _logError('deleteParticipant', e, stackTrace);
      throw Exception('Failed to delete participant: $e');
    }
  }

  Future<Expense> createExpense(int tripId, Map<String, dynamic> expenseData) async {
    try {
      debugPrint('[TripRepository.createExpense] API call: tripId=$tripId, data=$expenseData');
      final response = await _apiClient.dio.post('/trips/$tripId/expenses', data: expenseData);
      debugPrint('[TripRepository.createExpense] Success: ${response.data}');
      return Expense.fromJson(response.data);
    } catch (e, stackTrace) {
      _logError('createExpense', e, stackTrace);
      throw Exception('Failed to create expense: $e');
    }
  }

  Future<Settlement> getSettlement(int tripId, {String scope = 'UNSETTLED'}) async {
    try {
      debugPrint('[TripRepository.getSettlement] API call: tripId=$tripId, scope=$scope');
      final response = await _apiClient.dio.get('/trips/$tripId/settlement', queryParameters: {'scope': scope});
      debugPrint('[TripRepository.getSettlement] Success: ${response.data}');
      return Settlement.fromJson(response.data);
    } catch (e, stackTrace) {
      _logError('getSettlement', e, stackTrace);
      throw Exception('Failed to load settlement: $e');
    }
  }

  Future<void> deleteExpense(int expenseId) async {
    try {
      debugPrint('[TripRepository.deleteExpense] API call: expenseId=$expenseId');
      await _apiClient.dio.delete('/trips/expenses/$expenseId');
      debugPrint('[TripRepository.deleteExpense] Success');
    } catch (e, stackTrace) {
      _logError('deleteExpense', e, stackTrace);
      throw Exception('Failed to delete expense: $e');
    }
  }

  Future<Expense> updateExpense(int expenseId, Map<String, dynamic> expenseData) async {
    try {
      debugPrint('[TripRepository.updateExpense] API call: expenseId=$expenseId, data=$expenseData');
      final response = await _apiClient.dio.put('/trips/expenses/$expenseId', data: expenseData);
      debugPrint('[TripRepository.updateExpense] Success: ${response.data}');
      return Expense.fromJson(response.data);
    } catch (e, stackTrace) {
      _logError('updateExpense', e, stackTrace);
      throw Exception('Failed to update expense: $e');
    }
  }

  Future<Expense> updateExpenseSettled(int expenseId, bool settled) async {
    try {
      debugPrint('[TripRepository.updateExpenseSettled] API call: expenseId=$expenseId, settled=$settled');
      final response = await _apiClient.dio.patch('/trips/expenses/$expenseId/settled', data: {'settled': settled});
      debugPrint('[TripRepository.updateExpenseSettled] Success: ${response.data}');
      return Expense.fromJson(response.data);
    } catch (e, stackTrace) {
      _logError('updateExpenseSettled', e, stackTrace);
      throw Exception('Failed to update expense settled status: $e');
    }
  }
}
