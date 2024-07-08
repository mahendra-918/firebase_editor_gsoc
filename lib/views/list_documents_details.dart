import 'package:firebase_editor_gsoc/views/array_field_data.dart';
import 'package:firebase_editor_gsoc/views/edit_field_type.dart';
import 'package:firebase_editor_gsoc/views/map_field_data.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DocumentDetailsPage extends StatefulWidget {
  final String accessToken;
  final String documentPath;
  final String projectId;
  final String databaseId;
  final String collectionId;

  const DocumentDetailsPage({super.key,
    required this.accessToken,
    required this.documentPath,
    required this.projectId,
    required this.databaseId,
    required this.collectionId,
  });

  @override
  _DocumentDetailsPageState createState() => _DocumentDetailsPageState();
}

class _DocumentDetailsPageState extends State<DocumentDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _documentDetails;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDocumentDetails();
  }

  void _fetchDocumentDetails() async {
    String url = 'https://firestore.googleapis.com/v1/${widget.documentPath}';
    Map<String, String> headers = {
      'Authorization': 'Bearer ${widget.accessToken}',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print(data);
        setState(() {
          _documentDetails = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to call Firestore API. Status Code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _error = 'Error calling Firestore API: $error';
        _isLoading = false;
      });
    }
  }


  void _showEditDialog(String fieldName, String fieldType, String fieldValue) {
    String newFieldType = fieldType;
    String newFieldValue = fieldValue;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: fieldName),
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Field Name'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: newFieldType),
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Field Type'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditFieldTypePage(
                            fieldName: fieldName,
                            fieldType: fieldType,
                            fieldValue: fieldValue,
                            accessToken: widget.accessToken,
                            documentPath: widget.documentPath,
                            documentDetails: _documentDetails,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              TextField(
                controller: TextEditingController(text: newFieldValue),
                onChanged: (value) {
                  newFieldValue = value;
                },
                decoration: const InputDecoration(labelText: 'Field Value'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateField(fieldName, newFieldType, newFieldValue);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _updateField(String fieldName, String fieldType, String fieldValue) async {
    Map<String, dynamic> fields = _documentDetails!['fields'];
    fields[fieldName] = {fieldType: fieldValue};

    String url = 'https://firestore.googleapis.com/v1/${widget.documentPath}?updateMask.fieldPaths=$fieldName';
    Map<String, String> headers = {
      'Authorization': 'Bearer ${widget.accessToken}',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    Map<String, dynamic> body = {
      "fields": fields,
    };

    try {
      final response = await http.patch(Uri.parse(url), headers: headers, body: json.encode(body));

      if (response.statusCode == 200) {
        setState(() {
          _documentDetails!['fields'] = fields;
        });
        //call function for storing history
        print('Field updated successfully');
      } else {
        print('Failed to update field. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error updating field: $error');
    }
  }


  void _deleteField(String fieldName) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the field "$fieldName"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancelled
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      Map<String, dynamic> fields = _documentDetails!['fields'];

      // Remove the field from the fields map
      fields.remove(fieldName);

      // Update Firestore with the updated fields
       _updateDocument(fields);
    }
  }


  void _updateDocument(Map<String, dynamic> updatedFields) async {
    String url = 'https://firestore.googleapis.com/v1/${widget.documentPath}';
    Map<String, String> headers = {
      'Authorization': 'Bearer ${widget.accessToken}',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    Map<String, dynamic> body = {
      "fields": updatedFields,
    };

    try {
      final response = await http.patch(Uri.parse(url), headers: headers, body: json.encode(body));

      if (response.statusCode == 200) {
        setState(() {
          _documentDetails!['fields'] = updatedFields;
        });
        // Call function for storing history or any other actions after successful update
        print('Field deleted successfully');
      } else {
        print('Failed to delete field. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error deleting field: $error');
    }
  }


  void _showGeoPointDialog(String fieldName, Map<String, dynamic> geoPointValue) {
    double latitude = geoPointValue['latitude'];
    double longitude = geoPointValue['longitude'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit GeoPoint: $fieldName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: latitude.toString()),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Latitude'),
                onChanged: (value) {
                  latitude = double.tryParse(value) ?? latitude;
                },
              ),
              TextField(
                controller: TextEditingController(text: longitude.toString()),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Longitude'),
                onChanged: (value) {
                  longitude = double.tryParse(value) ?? longitude;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (latitude < -90 || latitude > 90) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Latitude must be between -90 and 90.'),
                    ),
                  );
                  return;
                }
                if (longitude < -180 || longitude > 180) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Longitude must be between -180 and 180.'),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
                _updateGeoPointField(fieldName, latitude, longitude);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _updateGeoPointField(String fieldName, double latitude, double longitude) async {
    Map<String, dynamic> fields = _documentDetails!['fields'];
    fields[fieldName] = {'geoPointValue': {'latitude': latitude, 'longitude': longitude}};

    String url = 'https://firestore.googleapis.com/v1/${widget.documentPath}?updateMask.fieldPaths=$fieldName';
    Map<String, String> headers = {
      'Authorization': 'Bearer ${widget.accessToken}',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    Map<String, dynamic> body = {
      "fields": fields,
    };

    try {
      final response = await http.patch(Uri.parse(url), headers: headers, body: json.encode(body));

      if (response.statusCode == 200) {
        setState(() {
          _documentDetails!['fields'] = fields;
        });
        print('GeoPoint updated successfully');
      } else {
        print('Failed to update GeoPoint. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error updating GeoPoint: $error');
    }
  }

  void _showBoolDialog(String fieldName, bool currentValue) {
    bool newValue = currentValue;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Boolean: $fieldName'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<bool>(
                    title: const Text('True'),
                    value: true,
                    groupValue: newValue,
                    onChanged: (value) {
                      setState(() {
                        newValue = value!;
                      });
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('False'),
                    value: false,
                    groupValue: newValue,
                    onChanged: (value) {
                      setState(() {
                        newValue = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateBoolField(fieldName, newValue);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }


  void _showTimeStampEditDialog(String fieldName, String fieldType, dynamic fieldValue) {
    String newFieldType = fieldType;
    String newFieldValue = fieldValue;

    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    // Parse the current timestamp value
    DateTime currentDateTime = DateTime.parse(fieldValue);

    // Initialize selectedDate and selectedTime with current values
    selectedDate = currentDateTime;
    selectedTime = TimeOfDay.fromDateTime(currentDateTime);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Timestamp'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: newFieldType),
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Field Type'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditFieldTypePage(
                            fieldName: fieldName,
                            fieldType: fieldType,
                            fieldValue: fieldValue,
                            accessToken: widget.accessToken,
                            documentPath: widget.documentPath,
                            documentDetails: _documentDetails,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              // Date picker
              ListTile(
                title: Text('Date'),
                subtitle: Text(selectedDate.toString().split(' ')[0]),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null && pickedDate != selectedDate) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),
              // Time picker
              ListTile(
                title: Text('Time'),
                subtitle: Text(selectedTime.format(context)),
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (pickedTime != null && pickedTime != selectedTime) {
                    setState(() {
                      selectedTime = pickedTime;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                DateTime newDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                setState(() {
                  // Update the map field value with the new timestamp value at the specified index
                  fieldValue = newDateTime.toUtc().toIso8601String();
                });

                Navigator.of(context).pop(); // Close the dialog

                // Now update the entire map in Firestore
                _updateField(fieldName, fieldType, fieldValue);

              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _updateBoolField(String fieldName, bool newValue) async {
    Map<String, dynamic> fields = _documentDetails!['fields'];
    fields[fieldName] = {'booleanValue': newValue};

    String url = 'https://firestore.googleapis.com/v1/${widget.documentPath}?updateMask.fieldPaths=$fieldName';
    Map<String, String> headers = {
      'Authorization': 'Bearer ${widget.accessToken}',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    Map<String, dynamic> body = {
      "fields": fields,
    };

    try {
      final response = await http.patch(Uri.parse(url), headers: headers, body: json.encode(body));

      if (response.statusCode == 200) {
        setState(() {
          _documentDetails!['fields'] = fields;
        });
        print('Boolean value updated successfully');
      } else {
        print('Failed to update Boolean value. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error updating Boolean value: $error');
    }
  }


  String _formatDateTime(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
  }

  String extractDisplayName(String documentName) {
    List<String> parts = documentName.split("${widget.collectionId}/");
    String displayName = parts.last;
    return displayName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Details'),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading document details...'),
          ],
        ),
      )
          : _error != null
          ? Center(child: Text(_error!))
          : _documentDetails != null
          ? Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Document ID: ${extractDisplayName(_documentDetails!['name'])}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Collection Name: ${widget.collectionId}"),
              const SizedBox(height: 8),
              Text('Created Time: ${_formatDateTime(_documentDetails!['createTime'])}'),
              Text('Updated Time: ${_formatDateTime(_documentDetails!['updateTime'])}'),
              const SizedBox(height: 16),
              const Text('Fields:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_documentDetails!['fields'] != null)
                ..._documentDetails!['fields'].entries.map((entry) {
                  String fieldName = entry.key;
                  Map<String, dynamic> fieldData = entry.value;
                  String fieldType;
                  dynamic displayValue;
                  dynamic fieldValue;

                  if (fieldData.containsKey('stringValue')) {
                    fieldType = 'stringValue';
                    fieldValue = fieldData['stringValue'];
                    displayValue = fieldValue;
                  } else if (fieldData.containsKey('integerValue')) {
                    fieldType = 'integerValue';
                    fieldValue = fieldData['integerValue'];
                    displayValue = fieldValue;
                  } else if (fieldData.containsKey('timestampValue')) {
                    fieldType = 'timestampValue';
                    fieldValue = fieldData['timestampValue'];
                    displayValue = fieldValue;
                  } else if (fieldData.containsKey('mapValue')) {
                    fieldType = 'mapValue';
                    fieldValue = fieldData['mapValue'];
                    displayValue = 'Map';
                    print(fieldValue);
                  } else if (fieldData.containsKey('arrayValue')) {
                    fieldType = 'arrayValue';
                    fieldValue = fieldData['arrayValue'];
                    displayValue = 'Array';
                  } else if (fieldData.containsKey('geoPointValue')) {
                    fieldType = 'geoPointValue';
                    fieldValue = fieldData['geoPointValue'];
                    displayValue = 'GeoPoint';

                  } else if (fieldData.containsKey('nullValue')) {
                    fieldType = 'nullValue';
                    fieldValue = fieldData['nullValue'];
                    displayValue = fieldValue;
                  } else if (fieldData.containsKey("booleanValue")) {
                    fieldType = 'booleanValue';
                    fieldValue = fieldData['booleanValue'];
                    displayValue = fieldValue;
                  } else if (fieldData.containsKey("referenceValue")) {
                    fieldType = 'referenceValue';
                    fieldValue = fieldData['referenceValue'];
                    displayValue = fieldValue;
                  } else {
                    // Handle unsupported types or unexpected data structure
                    fieldType = 'unsupported';
                    fieldValue = 'Unsupported';
                    displayValue = fieldValue;
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text('$fieldName ($fieldType): $displayValue'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (fieldType == 'mapValue')
                            IconButton(onPressed: () {
                              // _showMapDialog(fieldName, fieldValue);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapFieldDataPage(
                                    fieldName: fieldName,
                                    mapValue: fieldValue,
                                    documentDetails: _documentDetails,
                                    accessToken: widget.accessToken,
                                    documentPath: widget.documentPath,
                                  ),
                                ),
                              );
                            }, icon: const Icon(Icons.remove_red_eye)),
                          if (fieldType == 'arrayValue')
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ArrayFieldDataPage(
                                      fieldName: fieldName,
                                      arrayValue: fieldValue['values'],
                                      accessToken: widget.accessToken,
                                      documentDetails: _documentDetails,
                                      documentPath: widget.documentPath,

                                    ),
                                  ),
                                );
                              },
                            ),
                          if (fieldType == 'geoPointValue')
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye),
                              onPressed: () {
                                _showGeoPointDialog(fieldName, fieldValue);
                              },
                            ),
                          if (fieldType == 'booleanValue')
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showBoolDialog(fieldName, fieldValue);
                              },
                            ),
                          if (fieldType == 'timestampValue')
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showTimeStampEditDialog(fieldName, fieldType, fieldValue);
                              },
                            ),
                          if (fieldType != 'mapValue' &&
                              fieldType != 'arrayValue' &&
                              fieldType != 'geoPointValue' &&
                              fieldType != 'booleanValue' &&
                              fieldType != 'timestampValue')
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showEditDialog(fieldName, fieldType, fieldValue);
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              // Define your delete action here
                              _deleteField(fieldName);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      )
          : const Center(child: Text('No document details found.')),
    );
  }
}
