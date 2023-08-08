import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:intl/intl.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(),
    );
  }
}

class LocationHelper {
  Location location = Location();
  
  Future<Map<String, double>> getLocation() async {
    try {
      var userLocation = await location.getLocation();
      return {
        'latitude': userLocation.latitude!,
        'longitude': userLocation.longitude!,
      };
    } catch (e) {
      return {};
    }
  }
}

class LoginScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final LocationHelper locationHelper = LocationHelper();

  void enviarUbicacion(BuildContext context) async {
    String nombreUsuario = usernameController.text;
    String contrasena = passwordController.text;

    // Realizar solicitud para obtener el token
    String urlServidorToken = "http://localhost/gps/server/host/generarToken.php";
    http.Response respuestaToken = await http.post(urlServidorToken, body: {
      'usuario': nombreUsuario,
      'contrasena': contrasena,
    });

    if (respuestaToken.statusCode == 200) {
      String token = respuestaToken.body;
      Map<String, double> locationData = await locationHelper.getLocation();

      if (locationData.isNotEmpty) {
        double latitude = locationData['latitude']!;
        double longitude = locationData['longitude']!;
        String gpsData = '$latitude, $longitude';
        String fechaHoraActual = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

        // Datos a enviar en la solicitud POST
        Map<String, String> datos = {
          "usuario": nombreUsuario,
          "token": token,
          "gps": gpsData,
          "fecha_hora": fechaHoraActual,
        };

        // Realizar la solicitud POST al servidor
        String urlServidor = "http://localhost/gps/server/host/post.php";
        http.Response respuestaServidor = await http.post(urlServidor, body: datos);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Resultado'),
              content: Text(respuestaServidor.body),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cerrar'),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('No se pudo obtener la ubicación'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cerrar'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('App de Ubicación')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Nombre de usuario'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                enviarUbicacion(context);
              },
              child: Text('Enviar Ubicación'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}
