import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database_operations/db_operations.dart';
import '../../database_operations/time_entry_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseOperations _dbOps = DatabaseOperations();
  final ScrollController _scrollController = ScrollController();
  final List<TimeEntry> _entries = [];

  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMoreData = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await _dbOps.getTimeEntries(
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _entries.addAll(entries);
        _hasMoreData = entries.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load entries');
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await _dbOps.getTimeEntries(
        page: _currentPage + 1,
        pageSize: _pageSize,
      );

      setState(() {
        _entries.addAll(entries);
        _currentPage++;
        _hasMoreData = entries.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load more entries');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreData();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 8) return Colors.green;
    if (rating >= 5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _entries.clear();
                _currentPage = 1;
                _hasMoreData = true;
              });
              _loadInitialData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _entries.clear();
            _currentPage = 1;
            _hasMoreData = true;
          });
          await _loadInitialData();
        },
        child: _entries.isEmpty && !_isLoading
            ? const Center(
                child: Text('No entries found'),
              )
            : ListView.builder(
                controller: _scrollController,
                itemCount: _entries.length + (_hasMoreData ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _entries.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const SizedBox(),
                      ),
                    );
                  }

                  final entry = _entries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ListTile(
                      title: Text(
                        entry.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy - HH:mm')
                            .format(entry.timestamp),
                      ),
                      trailing: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getRatingColor(entry.rating),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            entry.rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        // Show details or edit dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Entry Details'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Description: ${entry.description}'),
                                const SizedBox(height: 8),
                                Text(
                                  'Time: ${DateFormat('MMM dd, yyyy - HH:mm').format(entry.timestamp)}',
                                ),
                                const SizedBox(height: 8),
                                Text('Rating: ${entry.rating}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Delete entry
                                  await _dbOps.deleteTimeEntry(entry.id!);
                                  Navigator.pop(context);
                                  setState(() {
                                    _entries.removeAt(index);
                                  });
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
