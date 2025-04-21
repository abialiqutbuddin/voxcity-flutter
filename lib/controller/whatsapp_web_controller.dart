import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
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


   Future<void> extractWhatsAppChat(InAppWebViewController controller) async {
     String jsCode = """
// Function to extract WhatsApp Web chat list
function extractChatList() {
    let chats = [];
    
    // Select all chat list elements
    let chatElements = document.querySelectorAll("div.x10l6tqk.xh8yej3.x1g42fcv");

    chatElements.forEach(chat => {
        try {
            // Extract chat name
            let nameTag = chat.querySelector("span.x1iyjqo2");
            let chatName = nameTag ? nameTag.textContent.trim() : "Unknown";

            // Extract message preview
            let messageTag = chat.querySelector("span.x78zum5");
            let message = messageTag ? messageTag.textContent.trim() : "No message";

            // Extract timestamp
            let timestampTag = chat.querySelector("div._ak8i");
            let timestamp = timestampTag ? timestampTag.textContent.trim() : "Unknown";

            // Extract sender (if available)
            let senderTag = chat.querySelector("span.x1rg5ohu");
            let sender = senderTag ? senderTag.textContent.trim() : "Unknown";

            // Extract unread messages count (if available)
            let unreadTag = chat.querySelector("span.x1rg5ohu.x1xaadd7.x1pg5gke.xo5v014.x1u28eo4.x2b8uid.x16dsc37.x18ba5f9.x1sbl2l.xy9co9w.x5r174s.x7h3shv.x1tsellj.x682dto.x1e01kqd.xpqt37d.x9bpaai.xk50ysn");
            let unreadCount = unreadTag ? unreadTag.textContent.trim() : "0";

            // Determine read/unread status
            let readStatus = parseInt(unreadCount) > 0 ? "Unread" : "Read";

            // Append extracted data
            chats.push({
                "chat_name": chatName,
                "message": message,
                "timestamp": timestamp,
                "sender": sender,
                "unread_count": unreadCount,
                "status": readStatus
            });
        } catch (error) {
            console.error("Error extracting chat data:", error);
        }
    });

    console.log("Extracted chat list:", chats);
    return chats;
}

// Run the function and store the extracted data
let chatData = extractChatList();
  """;

     try {
       // Execute JavaScript in WebView
       var extractedHtml = await controller.evaluateJavascript(source: jsCode);

       if (extractedHtml != null && extractedHtml.isNotEmpty && !extractedHtml.contains("Chat block not found")) {
         // Copy extracted HTML to clipboard
         await Clipboard.setData(ClipboardData(text: extractedHtml));
         print("✅ WhatsApp chat HTML copied to clipboard!");
       } else {
         print("❌ Failed to extract chat HTML.");
       }
     } catch (e) {
       print("⚠️ Error extracting chat: $e");
     }
   }
   Future<void> copyWhatsAppChatHtml(InAppWebViewController controller) async {
     String jsCode = """
    (function() {
        let chatMessages = document.querySelectorAll("div.x10l6tqk.xh8yej3.x1g42fcv");

        if (!chatMessages.length) {
            return "Chat messages not found! Ensure you are on WhatsApp Web and inside a chat.";
        }

        // Create a wrapper div to store extracted messages
        let wrapperDiv = document.createElement("div");
        
        chatMessages.forEach(chat => {
            wrapperDiv.appendChild(chat.cloneNode(true)); // Clone each chat message div
        });

        return wrapperDiv.innerHTML; // Get all chat messages as HTML
    })();
  """;

     try {
       // Execute JavaScript to extract chat HTML
       var extractedHtml = await controller.evaluateJavascript(source: jsCode);

       if (extractedHtml != null && extractedHtml.isNotEmpty && !extractedHtml.contains("Chat HTML not found")) {
         // Copy extracted HTML to clipboard
         await Clipboard.setData(ClipboardData(text: extractedHtml));
         print("✅ WhatsApp chat HTML copied to clipboard! Length: ${extractedHtml.length}");
       } else {
         print("❌ Failed to extract chat HTML: Make sure you're inside a chat.");
       }
     } catch (e) {
       print("⚠️ Error extracting chat HTML: $e");
     }
   }

   Future<void> openWhatsAppChat(InAppWebViewController controller, String chatName) async {
     String jsCode = """
    (function() {
        let chatElements = document.querySelectorAll("div.x10l6tqk.xh8yej3.x1g42fcv");

        if (!chatElements.length) {
            return "❌ No chats found! Ensure you are on WhatsApp Web.";
        }

        for (let chat of chatElements) {
            let nameTag = chat.querySelector("span.x1iyjqo2");
            let nameText = nameTag ? nameTag.textContent.trim() : null;

            if (nameText && nameText.toLowerCase() === "${chatName.toLowerCase()}") {
                // Create a proper simulated click event
                let event = new MouseEvent('mousedown', {
                    bubbles: true,
                    cancelable: true,
                    view: window
                });
                
                chat.dispatchEvent(event); // Simulate the click event

                return "✅ Opened chat: " + nameText;
            }
        }

        return "❌ Chat with name '${chatName}' not found!";
    })();
  """;

     try {
       // Execute JavaScript to find and open the chat
       var result = await controller.evaluateJavascript(source: jsCode);

       print(result); // Log the result
     } catch (e) {
       print("⚠️ Error opening chat: $e");
     }
   }


}