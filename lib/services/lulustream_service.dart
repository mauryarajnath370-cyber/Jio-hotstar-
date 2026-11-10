import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class LuluStreamService {
  static const String apiKey = "2705561jhlofjmxrgy7zx"; 

  static Future<String?> uploadVideo(File videoFile, File? thumbnailFile, String title, String desc, bool isAdult) async {
    try {
      var serverRes = await http.get(Uri.parse('https://lulustream.com/api/upload/server?key=$apiKey'));
      var serverData = jsonDecode(serverRes.body);
      if (serverData['status'] != 200) return null;
      
      String uploadUrl = serverData['result']; 

      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['key'] = apiKey;
      request.fields['file_title'] = title;
      request.fields['file_descr'] = desc;
      request.fields['file_adult'] = isAdult ? '1' : '0';
      
      request.files.add(await http.MultipartFile.fromPath('file', videoFile.path));
      if (thumbnailFile != null) {
        request.files.add(await http.MultipartFile.fromPath('snapshot', thumbnailFile.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 200 && data['files'].isNotEmpty) {
           return data['files'][0]['filecode']; // Return filecode
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
