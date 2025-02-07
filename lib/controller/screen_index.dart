import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

class GlobalController extends GetxController {
  var currentPageIndex = 0.obs;
  var isProductPageOpen = false.obs;
  var productPageId = "".obs;
  var productPageDate = "".obs;
  var selectedBookingIds = <String>{}.obs;
  var totalPax = 0.obs;
  InAppWebViewController? webViewController;

  void updatePageIndex(int index) {
    currentPageIndex.value = index;
  }

  void toggleProductPage(bool isOpen) {
    isProductPageOpen.value = isOpen;
  }

  Future<void> updateProductPageIdAndDate(String value,String value2) async {
    productPageId.value = value;
    productPageDate.value = value2;
    totalPax.value = 0;
    selectedBookingIds.clear();
    await loadSelectedState();
  }

  Future<void> loadSelectedState() async {
    try {
      // Get the current values for productPageId and productPageDate
      final optionId = productPageId.value;
      final date = productPageDate.value;

      if (optionId.isEmpty || date.isEmpty) {
        return;
      }

      // Determine Firestore collection (today or tomorrow)
      final now = DateTime.now();
      final today = now.toString().split(' ')[0];
      final collection = date == today ? 'today' : 'tomorrow';


      // Fetch Firestore data
      final snapshot = await FirebaseFirestore.instance
          .collection('booking')
          .doc(collection)
          .get();

      if (snapshot.exists) {
        final bookingData = snapshot.data()?['bookings'] ?? [];

        for (var booking in bookingData) {
          if (booking['products'] != null) {
            for (var product in booking['products']) {
              if (product['detailLink']?.contains('option_id=$optionId') == true) {
                // Update reactive variables
                selectedBookingIds.addAll(Set<String>.from(product['selectedBookingIds'] ?? [])); // Add the new items
                totalPax.value = product['totalPax'] ?? 0;
                return;
              }
            }
          }
        }
      } else {
        selectedBookingIds.clear();
        totalPax.value = 0;
      }
    } catch (e) {
      Exception(e);
    }
  }

  Future<void> insertHiddenLink(String phone, String message) async {
    final escapedPhone = Uri.encodeComponent(phone);
    final escapedMessage = message.replaceAll("'", "%27"); // Encode single quote
    final insertLinkScript = """
(function() {
  // Select the "Chats" container div
  const chatsContainer = document.querySelector('div[title="Chats"]');
  if (chatsContainer) {
    // Check if the hidden link already exists
    let hiddenLink = chatsContainer.querySelector('a.hidden-whatsapp-link');
    if (hiddenLink) {
      // Update the existing link
      hiddenLink.href = `https://wa.me/$escapedPhone?text=$escapedMessage`;
      console.log("Hidden link updated in the 'Chats' container.");
    } else {
      // Create a new hidden <a> element
      hiddenLink = document.createElement('a');
      hiddenLink.href = `https://wa.me/$escapedPhone?text=$escapedMessage`;
      hiddenLink.target = "_blank";
      hiddenLink.style.display = "none";
      hiddenLink.className = "hidden-whatsapp-link"; 
      hiddenLink.textContent = "Hidden WhatsApp Link"; 

      chatsContainer.appendChild(hiddenLink);
      console.log("Hidden link added below the 'Chats' container.");
    }

    // Click the link (either newly created or updated)
    hiddenLink.click();
  } else {
    console.error("'Chats' container not found.");
  }
})();
    """;

    await webViewController!.evaluateJavascript(source: insertLinkScript);
  }

  Future<void> clickHiddenLink(String phone, String message) async {
    final escapedPhone = Uri.encodeComponent(phone);
    final escapedMessage = message.replaceAll("'", "%27"); // Encode single quote
    final clickLinkScript = """
      // Select the hidden <a> element
      const hiddenLink = document.querySelector('a[href="https://wa.me/$escapedPhone?text=$escapedMessage"]');
      if (hiddenLink) {
        hiddenLink.click();
        console.log("Hidden link clicked.");
      } else {
        console.error("Hidden link not found.");
      }
    """;
    await webViewController!.evaluateJavascript(source: clickLinkScript);
  }
}
