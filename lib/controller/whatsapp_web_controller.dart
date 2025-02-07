import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WhatsappWebController {

   Future<void> insertHiddenLink(InAppWebViewController webViewController) async {
    const insertLinkScript = """
      // Select the "Chats" container div
      const chatsContainer = document.querySelector('div[title="Chats"]');
      if (chatsContainer) {
        // Create the hidden <a> element
        const hiddenLink = document.createElement('a');
        hiddenLink.href = "https://wa.me/923330365252?text=Hello,%20my%20name%20is%20abiali%0AKind%20Regards";
        hiddenLink.target = "_blank";
        hiddenLink.style.display = "none";
        hiddenLink.textContent = "Hidden WhatsApp Link"; // Optional: Text content for debugging

        // Append the <a> element below the "Chats" container
        chatsContainer.appendChild(hiddenLink);

        console.log("Hidden link added below the 'Chats' container.");
      } else {
        console.error("'Chats' container not found.");
      }
    """;

    // Inject the JavaScript to insert the hidden link
    await webViewController.evaluateJavascript(source: insertLinkScript);
  }

   Future<void> clickHiddenLink(InAppWebViewController webViewController) async {
    const clickLinkScript = """
      // Select the hidden <a> element
      const hiddenLink = document.querySelector('a[href="https://wa.me/923330365252?text=Hello,%20my%20name%20is%20abiali%0AKind%20Regards"]');
      if (hiddenLink) {
        hiddenLink.click();
        console.log("Hidden link clicked.");
      } else {
        console.error("Hidden link not found.");
      }
    """;

    // Inject the JavaScript to click the hidden link
    await webViewController.evaluateJavascript(source: clickLinkScript);
  }

   Future<void> saveBlobToFile(String base64Data, String suggestedName) async {
     try {
       // Decode the base64 data
       final bytes = base64Decode(base64Data);

       // Use the suggested name or fallback to a default
       final fileName = suggestedName.isNotEmpty
           ? suggestedName
           : 'file_${DateTime.now().millisecondsSinceEpoch}.png';

       // Open the save file dialog
       final FileSaveLocation? saveLocation =
       await getSaveLocation(suggestedName: fileName);
       if (saveLocation == null) {
         // User canceled the operation
         return;
       }

       // Save the file at the selected path
       final file = File(saveLocation.path);
       await file.writeAsBytes(bytes);

       final savedFileName = saveLocation.path.split('/').last;

       // // Notify the user of the successful download
       // ScaffoldMessenger.of(context).showSnackBar(
       //   SnackBar(content: Text("File saved to ${saveLocation.path}")),
       // );
     } catch (e) {
       // ScaffoldMessenger.of(context).showSnackBar(
       //   SnackBar(content: Text("Failed to save file")),
       // );
     }
   }

   Future<void> injectPasteListener(InAppWebViewController controller) async {
     const jsCode = """
      // Add an event listener for the 'paste' event
      document.addEventListener("paste", function (event) {
        const clipboardData = event.clipboardData || window.clipboardData;
        const files = clipboardData.files;

        if (files.length > 0) {
          console.log("Pasted Files:");

          // Handle the first pasted file (adjust for multiple files if needed)
          const file = files[0];
          console.log("Pasted File Name:", file.name);

          // Look for Zendesk's file input element
          const fileInput = document.querySelector("input[type='file']");

          if (fileInput) {
            // Create a DataTransfer object to simulate a file upload
            const dataTransfer = new DataTransfer();
            dataTransfer.items.add(file);

            // Attach the file to Zendesk's input field
            fileInput.files = dataTransfer.files;

            // Trigger a change event on the input field
            const changeEvent = new Event("change", { bubbles: true });
            fileInput.dispatchEvent(changeEvent);

            console.log("File successfully attached to Zendesk.");
          } else {
            console.error("Zendesk file input field not found.");
          }
        } else {
          console.log("No files detected in the paste event.");
        }
      });
    """;
     await controller.evaluateJavascript(source: jsCode);
   }

}