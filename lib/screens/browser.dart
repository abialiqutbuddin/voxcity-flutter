import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ModernBrowser extends StatefulWidget {
  const ModernBrowser({super.key});

  @override
  ModernBrowserState createState() => ModernBrowserState();
}

class ModernBrowserState extends State<ModernBrowser> with AutomaticKeepAliveClientMixin {
  final List<TabData> _tabs = [];
  int _currentTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addNewTab(initialUrl: 'https://google.com'); // Add initial tab
  }

  void _addNewTab({required String initialUrl}) {
    setState(() {
      _tabs.add(TabData(
        id: UniqueKey(), // Ensure each tab has a unique ID
        url: initialUrl,
        controller: null,
        title: 'New Tab',
      ));
      _currentTabIndex = _tabs.length - 1;
    });
  }

  void _closeTab(int index) {
    if (_tabs.length == 1) return; // Prevent closing the last tab

    setState(() {
      // Remove the tab and its WebView content
      _tabs[index].controller?.stopLoading(); // Stop any ongoing loading
      _tabs.removeAt(index);

      // Adjust the current tab index after the removal
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      }
    });
  }

  void _searchInCurrentTab() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final url = Uri.tryParse(query)?.hasAbsolutePath == true
        ? query
        : 'https://www.google.com/search?q=$query';

    setState(() {
      _tabs[_currentTabIndex].url = url;
    });

    _tabs[_currentTabIndex].controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri(url)),
    );
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Column(
        children: [
          _buildTabAndSearchBar(), // Combined Tab Bar and Search Bar
          Expanded(
            child: Stack(
              children: _tabs.map((tab) {
                final isActive = _tabs.indexOf(tab) == _currentTabIndex;

                return Offstage(
                  offstage: !isActive,
                  child: InAppWebView(
                    key: tab.id, // Unique key for each WebView
                    initialUrlRequest: URLRequest(
                      url: WebUri(tab.url),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      allowFileAccess: true,
                      userAgent:
                      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
                    ),
                    onWebViewCreated: (controller) {
                      tab.controller = controller;
                    },
                    onLoadStop: (controller, url) async {
                      if (url != null) {
                        final title = await controller.getTitle();
                        setState(() {
                          tab.url = url.toString();
                          tab.title = title ?? 'New Tab';
                        });
                      }
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      return NavigationActionPolicy.ALLOW;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabAndSearchBar() {
    return Container(
      height: 50,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length + 1, // Add 1 for the "New Tab" button
              itemBuilder: (context, index) {
                if (index == _tabs.length) {
                  // "New Tab" button
                  return IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () => _addNewTab(initialUrl: 'https://google.com'),
                  );
                }

                final tab = _tabs[index];
                final isActive = _currentTabIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTabIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blueAccent : Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isActive
                          ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Text(
                          tab.title.length > 15
                              ? '${tab.title.substring(0, 15)}...'
                              : tab.title,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_tabs.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                            onPressed: () => _closeTab(index),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search or URL',
                      hintStyle: TextStyle(color: Colors.white54),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16,vertical: 14),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _searchInCurrentTab(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _searchInCurrentTab,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class TabData {
  final Key id; // Unique key for identifying the tab
  String url;
  InAppWebViewController? controller;
  String title;

  TabData({required this.id, required this.url, this.controller, required this.title});
}