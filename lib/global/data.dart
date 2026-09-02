import 'package:read_app/utils/tts_service.dart';

class Data {
  String parentId = '';
  late Function refresh;
  late Function addDirectory;
  late Function updateSort;
  late TtsService tts;
}

final Data data = Data();
