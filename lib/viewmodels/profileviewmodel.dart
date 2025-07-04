// // ignore_for_file: avoid_print
import 'package:bmine_slice/Utils/apiservice.dart';
import 'package:bmine_slice/models/successmodel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileViewModel extends ChangeNotifier {
  late Success _profileresponse;
  Success get profileresponse => _profileresponse;
  late Success _editProfileresponse;
  Success get editProfileresponse => _editProfileresponse;
  late Success _uploadphotosresponse;
  Success get uploadphotosresponse => _uploadphotosresponse;
  late Success _removephotosresponse;
  Success get removephotosresponse => _removephotosresponse;
  late Success _uploadverifyvideoresponse;
  Success get uploadverifyvideoresponse => _uploadverifyvideoresponse;
  late Success _deleteaccountresponse;
  Success get deleteaccountresponse => _deleteaccountresponse;
  late Success _contactusresponse;
  Success get contactusresponse => _contactusresponse;
  late Success _updatePostSEQResponse;
  Success get updatePostSEQResponse => _updatePostSEQResponse;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  setLoading(bool loading) async {
    _isLoading = loading;
    notifyListeners();
  }

  setSuccess(bool isSuccess) async {
    _isSuccess = isSuccess;
    notifyListeners();
  }

  setProfileModel(Success profileresponse) async {
    print("2018");

    _profileresponse = profileresponse;
    notifyListeners();
  }

  setEditProfileModel(Success editProfileresponse) async {
    _editProfileresponse = editProfileresponse;
    notifyListeners();
  }

  setUploadPhotosModel(Success uploadphotosresponse) async {
    _uploadphotosresponse = uploadphotosresponse;
    notifyListeners();
  }

  setUploadVerifyVideoModel(Success uploadverifyvideoresponse) async {
    _uploadverifyvideoresponse = uploadverifyvideoresponse;
    notifyListeners();
  }

  setRemovePhotosModel(Success removephotosresponse) async {
    _removephotosresponse = removephotosresponse;
    notifyListeners();
  }

  setDeleteAccountModel(Success deleteaccountresponse) async {
    _deleteaccountresponse = deleteaccountresponse;
    notifyListeners();
  }

  setUpdatePostSEQModel(Success updatePostSEQResponse) async {
    _updatePostSEQResponse = updatePostSEQResponse;
    notifyListeners();
  }

  setContactUsModel(Success contactusresponse) async {
    _contactusresponse = contactusresponse;
    notifyListeners();
  }

  getProfileAPI(
    String userId,
    String latitude,
    String longitude,
    String measurementtype,
  ) async {
    setLoading(true);
    var response = await APIService.getProfile(
        userId, latitude, longitude, measurementtype);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setProfileModel(response);

        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setProfileModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  updateProfileAPI(String userId, Map<String, dynamic> jsonBody) async {
    setLoading(true);
    var response = await APIService.updateProfile(userId, jsonBody);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setEditProfileModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setEditProfileModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  uploadPhotosAPI(
      String userId, String firebaseId, List<XFile?> images, int seq) async {
    // setLoading(true);
    var response =
        await APIService.uploadPhotos(userId, firebaseId, images, seq);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setUploadPhotosModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setUploadPhotosModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  removePhotosAPI(String imageId) async {
    setLoading(true);
    var response = await APIService.removePhotos(imageId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setRemovePhotosModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setRemovePhotosModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  updatePostSeqAPI(String imageId1, int seq1, String imageId2, int seq2) async {
    setLoading(true);
    var response =
        await APIService.updatePostSeq(imageId1, seq1, imageId2, seq2);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setSuccess(true);
        setUpdatePostSEQModel(response);
        setLoading(false);
      } else {
        setSuccess(false);
        setUpdatePostSEQModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  uploadVerifyVideoAPI(String userId, XFile video) async {
    setLoading(true);
    var response = await APIService.uploadVerifyVideo(userId, video);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setUploadVerifyVideoModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setUploadVerifyVideoModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  deleteAccountAPI(String userId) async {
    setLoading(true);
    var response = await APIService.deleteAccount(userId);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setDeleteAccountModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setDeleteAccountModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  contactUsAPI(String email, String subject, String message) async {
    setLoading(true);
    var response = await APIService.contactUs(email, subject, message);
    if (response is Success) {
      Success result = response;
      if (result.success == true) {
        setContactUsModel(response);
        setSuccess(true);
        setLoading(false);
      } else {
        setSuccess(false);
        setContactUsModel(response);
        setLoading(false);
      }
      notifyListeners();
    }
  }

  updateProfileData(String text, String text2, String text3,
      TextEditingController hometownController) {}
}
