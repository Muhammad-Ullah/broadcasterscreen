
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as Path;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class FireStoreClass{

  static final liveCollection = 'liveuser';
  static final userCollection = 'users';
  static final emailCollection = 'user_email';

  static void createLiveUser({name, id, time,image}) async{
    final snapShot = await FirebaseFirestore.instance.collection(liveCollection).doc(name).get();
    if(snapShot.exists){
      await FirebaseFirestore.instance.collection(liveCollection).doc(name).update({
        'name': name,
        'channel': id,
        'time':time,
        'image': image
      });
    } else {
      await FirebaseFirestore.instance.collection(liveCollection).doc(name).set({
        'name': name,
        'channel': id,
        'time':time,
        'image': image
      });
    }
  }

  static Future<String> getImage ({username}) async{
    final snapShot = await FirebaseFirestore.instance.collection(userCollection).doc(username).get();
    return snapShot.data()['image'];
  }

  static Future<String> getName ({username}) async{
    final snapShot = await FirebaseFirestore.instance.collection(userCollection).doc(username).get();
    return snapShot.data()['name'];
  }


  static Future<bool> checkUsername({username}) async{
    final snapShot = await FirebaseFirestore.instance.collection(userCollection).doc(username).get();
    //print('Xperion ${snapShot.exists} $username');
    if(snapShot.exists) {
      return false;
    }
    return true;
  }

  static Future<void> regUser({name, email, username, image}) async{

    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('$email/${Path.basename(image.path)}');
    UploadTask uploadTask = storageReference.putFile(image);
    await uploadTask.then((res) {
      res.ref.getDownloadURL();
    });                                    //  Image Upload code

    await storageReference.getDownloadURL().then((fileURL) async{   // To fetch the uploaded data's url
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      await prefs.setString('username', username);
      await prefs.setString('email', email);
      await prefs.setString('image', fileURL);

      await FirebaseFirestore.instance.collection(userCollection).doc(username).set({
        'name': name,
        'email': email,
        'username': username,
        'image': fileURL,
      });
      await FirebaseFirestore.instance.collection(emailCollection).doc(email).set({
        'name': name,
        'email': email,
        'username': username,
        'image': fileURL,
      });
      return true;
    });


  }

  static void deleteUser({username}) async{
    await FirebaseFirestore.instance.collection('liveuser').doc(username).delete();
  }

  static Future<void> getDetails({email}) async{
    var document = await FirebaseFirestore.instance.doc('user_email/$email').get();
    var checkData = document.data;
    if(checkData==null)
      return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', document.data()['name']);
    await prefs.setString('username', document.data()['username']);
    await prefs.setString('image', document.data()['image']);
  }

}