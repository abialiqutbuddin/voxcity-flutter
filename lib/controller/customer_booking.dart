import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

Map<String, dynamic> extractSaleDetails(String htmlContent) {
  // Parse the HTML content.
  Document document = html_parser.parse(htmlContent);

  // 1. Extract the booking number from the heading.
  String bookingNumber = "";
  Element? bookingElement =
  document.querySelector('h2.content-heading .row .col-md-10');
  if (bookingElement != null) {
    String text = bookingElement.text.trim();
    // Expecting text like "Booking: VOXCII5"
    bookingNumber = text.replaceFirst(RegExp(r'^Booking:\s*'), '');
  }

  // 2. Locate the "Sale Details" and "Code" blocks.
  Element? saleDetailsBlock;
  Element? codeBlock;
  List<Element> blocks = document.querySelectorAll('div.block');
  for (Element block in blocks) {
    Element? header = block.querySelector('.block-header .block-title');
    if (header != null) {
      String headerText = header.text.trim();
      if (headerText.contains("Sale Details")) {
        saleDetailsBlock = block;
      } else if (headerText.contains("Code")) {
        codeBlock = block;
      }
    }
  }

  // 3. Parse sale details.
  Map<String, dynamic> saleDetails = {};
  if (saleDetailsBlock != null) {
    Element? content = saleDetailsBlock.querySelector('.block-content');
    if (content != null) {
      List<Element> rows = content.querySelectorAll('.row');
      String? lastField; // to handle Provider extra row
      for (Element row in rows) {
        Element? fieldElem = row.querySelector('.col-3');
        Element? valueElem = row.querySelector('.col-9');
        if (fieldElem != null && valueElem != null) {
          String fieldName = fieldElem.text.trim();
          String fieldValue = valueElem.text.trim();
          if (fieldName.isNotEmpty) {
            saleDetails[fieldName] = fieldValue;
            lastField = fieldName;
          } else if (fieldName.isEmpty && lastField == "Provider") {
            // Append provider code from the extra row.
            saleDetails["Provider Code"] = fieldValue;
          }
        }
      }
    }
  }

  // 4. Parse code details.
  Map<String, dynamic> codeDetails = {};
  if (codeBlock != null) {
    Element? content = codeBlock.querySelector('.block-content');
    if (content != null) {
      Element? table = content.querySelector('table');
      if (table != null) {
        List<Element> trs = table.querySelectorAll('tr');
        String currentField = "";
        for (Element tr in trs) {
          // If the row has a <th>, treat its text as the current field name.
          Element? th = tr.querySelector('th');
          if (th != null) {
            currentField = th.text.trim().toLowerCase();
          } else {
            // Otherwise, process the <td> value.
            Element? td = tr.querySelector('td');
            if (td != null) {
              String value = td.text.trim();
              if (currentField == 'type') {
                codeDetails['type'] = value;
              } else if (currentField == 'token') {
                codeDetails['token'] = value;
              } else if (currentField == 'scans') {
                // Expect an inner table for scans.
                Element? innerTable = td.querySelector('table');
                if (innerTable != null) {
                  List<Map<String, dynamic>> scans = [];
                  List<Element> scanRows = innerTable.querySelectorAll('tr');
                  for (Element scanRow in scanRows) {
                    List<Element> tds = scanRow.querySelectorAll('td');
                    if (tds.length >= 2) {
                      String label = tds[0].text.trim();
                      String secondText = tds[1].text.trim();
                      // Split the text by newline to get time and additional info.
                      List<String> parts = secondText.split(RegExp(r'\n'));
                      String time = parts.isNotEmpty ? parts[0].trim() : "";
                      String info = parts.length > 1 ? parts[1].trim() : "";
                      scans.add({
                        'label': label,
                        'time': time,
                        'info': info,
                      });
                    }
                  }
                  codeDetails['scans'] = scans;
                }
              }
            }
          }
        }
      }
    }
  }

  // Combine everything into a single map.
  return {
    'booking': bookingNumber,
    'saleDetails': saleDetails,
    'codeDetails': codeDetails,
  };
}