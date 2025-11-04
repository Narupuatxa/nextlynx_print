// lib/utils/alerts.dart
import 'package:fluttertoast/fluttertoast.dart';

void showLowStockAlert(String productName) {
  Fluttertoast.showToast(msg: 'Estoque baixo para $productName!');
}

void showGeneralAlert(String message) {
  Fluttertoast.showToast(msg: message);
}