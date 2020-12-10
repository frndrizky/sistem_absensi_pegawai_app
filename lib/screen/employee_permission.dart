import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:provider/provider.dart';
import 'package:spo_balaesang/models/absent_permission.dart';
import 'package:spo_balaesang/repositories/data_repository.dart';
import 'package:spo_balaesang/utils/view_util.dart';

class EmployeePermissionScreen extends StatefulWidget {
  @override
  _EmployeePermissionScreenState createState() =>
      _EmployeePermissionScreenState();
}

class _EmployeePermissionScreenState extends State<EmployeePermissionScreen> {
  List<AbsentPermission> _permissions = List<AbsentPermission>();
  bool _isLoading = false;

  Future<void> _fetchPermissionData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      var dataRepo = Provider.of<DataRepository>(context, listen: false);
      Map<String, dynamic> _result = await dataRepo.getAllEmployeePermissions();
      List<dynamic> permissions = _result['data'];

      List<AbsentPermission> _data =
          permissions.map((json) => AbsentPermission.fromJson(json)).toList();
      setState(() {
        _permissions = _data;
      });
    } catch (e) {
      print(e.toString());
    } finally {
      _isLoading = false;
    }
  }

  Future<void> approvePermission(AbsentPermission permission) async {
    ProgressDialog pd = ProgressDialog(context, isDismissible: false);
    pd.show();
    try {
      final dataRepo = Provider.of<DataRepository>(context, listen: false);
      Map<String, dynamic> data = {
        'user_id': permission.user.id,
        'is_approved': !permission.isApproved,
        'permission_id': permission.id
      };
      Response response = await dataRepo.approvePermission(data);
      Map<String, dynamic> _res = jsonDecode(response.body);
      if (response.statusCode == 200) {
        pd.hide();
        showAlertDialog("success", "Sukses", _res['message'], context, true);
      } else {
        pd.hide();
        showErrorDialog(context, _res);
      }
    } catch (e) {
      pd.hide();
      print(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPermissionData();
  }

  Widget _buildBody() {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_permissions.isEmpty) {
      return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 150,
                height: 150,
                child: FlareActor(
                  'assets/flare/empty.flr',
                  fit: BoxFit.contain,
                  animation: 'empty',
                  alignment: Alignment.center,
                ),
              ),
              Text('Belum ada izin yang diajukan!')
            ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemBuilder: (_, index) {
          AbsentPermission permission = _permissions[index];
          DateTime dueDate = _permissions[index].dueDate;
          DateTime startDate = _permissions[index].startDate;
          return Container(
            margin: EdgeInsets.only(bottom: 16.0),
            child: Card(
              elevation: 4.0,
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${permission.title}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16.0),
                      ),
                      SizedBox(height: 5.0),
                      Row(
                        children: <Widget>[
                          Text(
                            'Status : ',
                            style: TextStyle(fontSize: 12.0),
                          ),
                          Text(
                            '${permission.isApproved ? 'Disetujui' : 'Belum Disetujui'}',
                            style: TextStyle(
                                fontSize: 12.0,
                                color: permission.isApproved
                                    ? Colors.green
                                    : Colors.red),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.0),
                      Row(
                        children: <Widget>[
                          Text(
                            'Diajukan oleh : ',
                            style: TextStyle(fontSize: 12.0),
                          ),
                          Text(
                            '${permission.user.name}',
                            style: TextStyle(
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.0),
                      Divider(height: 2.0),
                      SizedBox(height: 5.0),
                      Text(
                        'Masa Berlaku : ',
                        style: TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                      SizedBox(height: 5.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16.0,
                          ),
                          SizedBox(width: 5.0),
                          Text(
                            '${startDate.day}/${startDate.month}/${startDate.year} - ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                            style: TextStyle(fontSize: 12.0),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.0),
                      Text(
                        'Deskripsi : ',
                        style: TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                      AutoSizeText(
                        '${permission.description}',
                        maxFontSize: 12.0,
                        minFontSize: 10.0,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5.0),
                      Text(
                        'Bukti Izin : ',
                        style: TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                      SizedBox(height: 5.0),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/images/upload_placeholder.png',
                          image: permission.photo,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 5.0),
                      SizedBox(
                        child: RaisedButton(
                          textColor: Colors.white,
                          color: Colors.blueAccent,
                          onPressed: () {
                            approvePermission(permission);
                          },
                          child: Text(permission.isApproved
                              ? 'Batal Setujui'
                              : 'Setujui'),
                        ),
                      )
                    ],
                  )),
            ),
          );
        },
        itemCount: _permissions.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('Daftar Izin Pegawai'),
      ),
      body: _buildBody(),
    );
  }
}