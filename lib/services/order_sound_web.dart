import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void playWebAudioDataUri(String dataUri) {
  try {
    final JSObject doc = globalContext.getProperty<JSObject>('document'.toJS);
    final JSObject audio =
        doc.callMethod<JSObject>('createElement'.toJS, 'audio'.toJS);
    audio.setProperty('src'.toJS, dataUri.toJS);
    audio.setProperty('volume'.toJS, 0.9.toJS);
    audio.callMethod('play'.toJS);
  } catch (_) {}
}
