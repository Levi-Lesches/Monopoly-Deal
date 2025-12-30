import "view_model.dart";

/// The view model for the home page.
class HomeModel extends ViewModel {
  int count = 0;

  void increment() {
    count++;
    notifyListeners();
  }
}
