import '../../common.dart';

bool get isMustardClient =>
    appName == 'MustardSupport' || appName == 'MustardRemote';

String get mustardDisplayName =>
    appName == 'MustardSupport' ? 'Mustard Support' : 'Mustard Remote';
