import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../pantalla_login.dart';

class PantallaAdmin extends StatefulWidget {
  const PantallaAdmin({super.key});

  @override
  State<PantallaAdmin> createState() => _PantallaAdminState();
}

class _PantallaAdminState extends State<PantallaAdmin> {
  late Future<List<dynamic>> _usuariosFuture;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  void _cargarUsuarios() {
    setState(() {
      _usuariosFuture = AdminService.obtenerTodosLosUsuarios();
    });
  }

  void _dialogoNuevoUsuario() {
    final nombreCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final edadCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Nuevo Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: correoCtrl, decoration: const InputDecoration(labelText: 'Correo')),
            TextField(controller: edadCtrl, decoration: const InputDecoration(labelText: 'Edad'), keyboardType: TextInputType.number),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              bool ok = await AuthService.registrarUsuario(
                nombreCtrl.text, edadCtrl.text, correoCtrl.text, passCtrl.text
              );
              Navigator.pop(context);
              if (ok) _cargarUsuarios();
            },
            child: const Text('Crear'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6EADD8),
        title: const Text('Panel Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargarUsuarios),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              AuthService.cerrarSesion();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaLogin()));
            }
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6EADD8),
        onPressed: _dialogoNuevoUsuario,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _usuariosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay usuarios.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final user = snapshot.data![index];
              final bool bloqueado = user['bloqueado'] ?? false;
              final int userId = user['id'];

              return Card(
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: bloqueado ? Colors.red : const Color(0xFF6EADD8),
                    child: Icon(bloqueado ? Icons.lock : Icons.person, color: Colors.white),
                  ),
                  title: Text(user['nombre'], style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: bloqueado ? TextDecoration.lineThrough : null
                  )),
                  subtitle: Text(user['correo']),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow("Expectativa", user['encuesta']?['expectativa'] ?? "N/A"),
                          _infoRow("Último Registro", "${user['registro_diario']?['horas_dormidas'] ?? 0}h"),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TextButton.icon(
                                icon: Icon(bloqueado ? Icons.lock_open : Icons.lock, color: Colors.orange),
                                label: Text(bloqueado ? "Desbloquear" : "Bloquear"),
                                onPressed: () async {
                                  await AdminService.bloquearUsuario(userId, !bloqueado);
                                  _cargarUsuarios();
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text("Eliminar"),
                                onPressed: () {
                                  _confirmarEliminar(userId, user['nombre']);
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(String t, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text("$t: $v", style: const TextStyle(fontSize: 13)),
  );

  void _confirmarEliminar(int id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar usuario?"),
        content: Text("Esto borrará a $nombre y todos sus datos."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () async {
              await AdminService.eliminarUsuario(id);
              Navigator.pop(context);
              _cargarUsuarios();
            }, 
            child: const Text("Sí, eliminar", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}