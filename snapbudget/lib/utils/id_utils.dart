import 'package:uuid/uuid.dart';

class IdUtils {
  static String generateId() => const Uuid().v4();
}

