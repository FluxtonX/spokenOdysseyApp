import 'package:talker_flutter/talker_flutter.dart';

class TalkerSuccessLog extends TalkerLog {
  TalkerSuccessLog(
      String super.message, {
        Object? error,
        super.stackTrace,
      }) : super(
    logLevel: LogLevel.info,
    error: error is Error ? error : null,
    pen: AnsiPen()..green(),
  );
}