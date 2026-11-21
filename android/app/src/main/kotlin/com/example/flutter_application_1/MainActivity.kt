package com.example.flutter_application_1

import io.flutter.embedding.android.FlutterFragmentActivity

// A entrada pela digital (pacote local_auth) precisa de FlutterFragmentActivity
// em vez de FlutterActivity. Sem isso a digital dá erro ao abrir.
class MainActivity : FlutterFragmentActivity()
