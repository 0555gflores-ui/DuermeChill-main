package com.intermodular.duermechill;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.*;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*") // Permite que Flutter se conecte sin bloqueos
public class ApiController {

    private static final ZoneId ZONE_ID = ZoneId.of("Europe/Madrid");

    @Autowired
    private JdbcTemplate db; // Herramienta para ejecutar SQL

    // 1. Registro de usuario
    @PostMapping("/registro")
    public ResponseEntity<?> registro(@RequestBody Map<String, Object> body) {
        try {
            String sql = "INSERT INTO usuarios (nombre, correo, edad, contrasena) VALUES (?, ?, ?, ?)";
            db.update(sql, body.get("nombre"), body.get("correo"), body.get("edad"), body.get("contrasena"));
            return ResponseEntity.ok(Map.of("mensaje", "Usuario registrado"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", "Error al registrar el usuario"));
        }
    }

    // 2. Login de usuario
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, Object> body) {
        String sql = "SELECT * FROM usuarios WHERE nombre = ? AND contrasena = ?";
        List<Map<String, Object>> users = db.queryForList(sql, body.get("nombre"), body.get("contrasena"));
        
        if (!users.isEmpty()) {
            Map<String, Object> usuario = new HashMap<>(users.get(0));
            
            Object valorEncuesta = usuario.get("encuesta_completada");
            boolean completada = false;
            if (valorEncuesta instanceof Boolean) completada = (Boolean) valorEncuesta;
            else if (valorEncuesta instanceof Number) completada = ((Number) valorEncuesta).intValue() == 1;
            
            usuario.put("encuesta_completada", completada);

            return ResponseEntity.ok(Map.of("mensaje", "Login exitoso", "usuario", usuario));
        } else {
            return ResponseEntity.status(401).body(Map.of("error", "Usuario o contraseña incorrectos"));
        }
    }

    // 3. Guardar encuesta inicial
    @PostMapping("/encuesta")
    public ResponseEntity<?> guardarEncuesta(@RequestBody Map<String, Object> body) {
        String sqlBusqueda = "SELECT id FROM usuarios WHERE nombre = ?";
        List<Map<String, Object>> users = db.queryForList(sqlBusqueda, body.get("nombre"));
        
        if (users.isEmpty()) return ResponseEntity.status(404).body(Map.of("error", "Usuario no encontrado"));
        
        Long userId = ((Number) users.get(0).get("id")).longValue();
        
        String sqlInsert = "INSERT INTO encuestas (usuario_id, expectativa, noche, hora, edad_encuesta) VALUES (?, ?, ?, ?, ?)";
        db.update(sqlInsert, userId, body.get("expectativa"), body.get("noche"), body.get("hora"), body.get("edad"));
        
        String sqlUpdate = "UPDATE usuarios SET encuesta_completada = TRUE WHERE id = ?";
        db.update(sqlUpdate, userId);
        
        return ResponseEntity.ok(Map.of("mensaje", "Encuesta guardada"));
    }

    // 4. Guardar registro diario de sueño
    @PostMapping("/registro_diario")
    public ResponseEntity<?> registroDiario(@RequestBody Map<String, Object> body) {
        List<Map<String, Object>> users = db.queryForList("SELECT id FROM usuarios WHERE nombre = ?", body.get("nombre"));
        if (users.isEmpty()) return ResponseEntity.status(404).body(Map.of("error", "Usuario no encontrado"));
        
        Long userId = ((Number) users.get(0).get("id")).longValue();
        String fecha = LocalDate.now(ZONE_ID).toString();
        
        String sql = "INSERT INTO registros_diarios (usuario_id, fecha, horas_dormidas, como_dormido, cansado, despertares) VALUES (?, ?, ?, ?, ?, ?)";
        db.update(sql, userId, fecha, body.get("horas_dormidas"), body.get("como_dormido"), body.get("cansado"), body.get("despertares"));
        
        return ResponseEntity.ok(Map.of("mensaje", "Registro guardado"));
    }

    // 5. Guardar alarmas
    @PostMapping("/alarmas")
    public ResponseEntity<?> guardarAlarmas(@RequestBody Map<String, Object> body) {
        List<Map<String, Object>> users = db.queryForList("SELECT id FROM usuarios WHERE nombre = ?", body.get("nombre"));
        if (users.isEmpty()) return ResponseEntity.status(404).body(Map.of("error", "Usuario no encontrado"));
        
        Long userId = ((Number) users.get(0).get("id")).longValue();
        
        db.update("DELETE FROM alarmas WHERE usuario_id = ?", userId);
        
        List<Map<String, Object>> alarmas = (List<Map<String, Object>>) body.get("alarmas");
        for (Map<String, Object> a : alarmas) {
            db.update("INSERT INTO alarmas (usuario_id, hora, activada) VALUES (?, ?, ?)", userId, a.get("hora"), a.get("activada"));
        }
        
        return ResponseEntity.ok(Map.of("mensaje", "Alarmas guardadas"));
    }

    // 6. Obtener datos de usuario (Gráficas y Alarmas)
    @GetMapping("/usuario/{nombre}")
    public ResponseEntity<?> getDatosUsuario(@PathVariable String nombre) {
        List<Map<String, Object>> users = db.queryForList("SELECT id FROM usuarios WHERE nombre = ?", nombre);
        if (users.isEmpty()) return ResponseEntity.status(404).body(Map.of("error", "Usuario no encontrado"));
        
        Long userId = ((Number) users.get(0).get("id")).longValue();
        
        List<Map<String, Object>> registros = db.queryForList("SELECT * FROM registros_diarios WHERE usuario_id = ? ORDER BY fecha ASC", userId);
        List<Map<String, Object>> alarmas = db.queryForList("SELECT hora, activada FROM alarmas WHERE usuario_id = ?", userId);
        
        for (Map<String, Object> a : alarmas) {
            Object val = a.get("activada");
            boolean isActivada = false;
            if (val instanceof Boolean) isActivada = (Boolean) val;
            else if (val instanceof Number) isActivada = ((Number) val).intValue() == 1;
            a.put("activada", isActivada);
        }

        return ResponseEntity.ok(Map.of("historial_registros", registros, "alarmas", alarmas));
    }

    // 7. Guardar datos de reloj inteligente (pulsaciones + fases de sueño)
    @PostMapping("/reloj/ingestar")
    public ResponseEntity<?> ingestarDatosReloj(@RequestBody Map<String, Object> body) {
        List<Map<String, Object>> users = db.queryForList("SELECT id FROM usuarios WHERE nombre = ?", body.get("nombre"));
        if (users.isEmpty()) return ResponseEntity.status(404).body(Map.of("error", "Usuario no encontrado"));

        Long userId = ((Number) users.get(0).get("id")).longValue();
        String fecha = body.getOrDefault("fecha", LocalDate.now(ZONE_ID).toString()).toString();

        List<Map<String, Object>> pulsaciones = (List<Map<String, Object>>) body.getOrDefault("pulsaciones", List.of());
        List<Map<String, Object>> fasesSueno = (List<Map<String, Object>>) body.getOrDefault("fases_sueno", List.of());

        return guardarDatosReloj(userId, fecha, pulsaciones, fasesSueno);
    }

    // 8. Obtener datos de reloj guardados (historial completo)
    @GetMapping("/reloj/{nombre}")
    public ResponseEntity<?> obtenerDatosReloj(@PathVariable String nombre) {
        List<Map<String, Object>> users = db.queryForList("SELECT id FROM usuarios WHERE nombre = ?", nombre);
        if (users.isEmpty()) return ResponseEntity.status(404).body(Map.of("error", "Usuario no encontrado"));

        Long userId = ((Number) users.get(0).get("id")).longValue();
        // Obtener todos los registros del reloj ordenados por fecha (últimos 30 días)
        List<Map<String, Object>> historialReloj = db.queryForList("SELECT fecha, total_horas, horas_awake, horas_light, horas_deep, horas_rem FROM reloj_suenos WHERE usuario_id = ? AND fecha >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) ORDER BY fecha ASC", userId);

        if (historialReloj.isEmpty()) {
            return ResponseEntity.ok(Map.of("historial_reloj", List.of(), "ultimo_reloj", Map.of("total_horas", 0, "horas_awake", 0, "horas_light", 0, "horas_deep", 0, "horas_rem", 0), "pulsaciones", List.of(), "fases_sueno", List.of()));
        }

        Map<String, Object> ultimoDato = historialReloj.get(historialReloj.size() - 1);
        String fechaUltima = ultimoDato.get("fecha").toString();

        List<Map<String, Object>> pulsaciones = db.queryForList("SELECT minuto, valor FROM pulsaciones WHERE usuario_id = ? AND fecha = ? ORDER BY minuto ASC", userId, fechaUltima);
        List<Map<String, Object>> fasesSueno = db.queryForList("SELECT fase, horas FROM fases_sueno WHERE usuario_id = ? AND fecha = ? ORDER BY id ASC", userId, fechaUltima);

        return ResponseEntity.ok(Map.of("historial_reloj", historialReloj, "ultimo_reloj", ultimoDato, "pulsaciones", pulsaciones, "fases_sueno", fasesSueno));
    }

    private ResponseEntity<?> guardarDatosReloj(Long userId, String fecha, List<Map<String, Object>> pulsaciones, List<Map<String, Object>> fasesSueno) {
        double horasAwake = 0.0;
        double horasLight = 0.0;
        double horasDeep = 0.0;
        double horasRem = 0.0;

        for (Map<String, Object> fase : fasesSueno) {
            String nombreFase = fase.getOrDefault("fase", "").toString().toLowerCase();
            double horas = toDouble(fase.getOrDefault("horas", 0));
            switch (nombreFase) {
                case "awake": horasAwake += horas; break;
                case "light": horasLight += horas; break;
                case "deep": horasDeep += horas; break;
                case "rem": horasRem += horas; break;
                default: break;
            }
        }

        double totalHoras = horasAwake + horasLight + horasDeep + horasRem;

        db.update("DELETE FROM reloj_suenos WHERE usuario_id = ? AND fecha = ?", userId, fecha);
        db.update("DELETE FROM pulsaciones WHERE usuario_id = ? AND fecha = ?", userId, fecha);
        db.update("DELETE FROM fases_sueno WHERE usuario_id = ? AND fecha = ?", userId, fecha);

        db.update("INSERT INTO reloj_suenos (usuario_id, fecha, total_horas, horas_awake, horas_light, horas_deep, horas_rem) VALUES (?, ?, ?, ?, ?, ?, ?)",
                userId, fecha, totalHoras, horasAwake, horasLight, horasDeep, horasRem);

        for (Map<String, Object> pulso : pulsaciones) {
            db.update("INSERT INTO pulsaciones (usuario_id, fecha, minuto, valor) VALUES (?, ?, ?, ?)",
                    userId, fecha, toInt(pulso.getOrDefault("minuto", 0)), toInt(pulso.getOrDefault("valor", 0)));
        }

        for (Map<String, Object> fase : fasesSueno) {
            db.update("INSERT INTO fases_sueno (usuario_id, fecha, fase, horas) VALUES (?, ?, ?, ?)",
                    userId, fecha, fase.getOrDefault("fase", ""), toDouble(fase.getOrDefault("horas", 0)));
        }

        return ResponseEntity.ok(Map.of("mensaje", "Datos de reloj guardados"));
    }

    private double toDouble(Object value) {
        if (value instanceof Number) return ((Number) value).doubleValue();
        try {
            return Double.parseDouble(value.toString());
        } catch (Exception e) {
            return 0.0;
        }
    }

    private int toInt(Object value) {
        if (value instanceof Number) return ((Number) value).intValue();
        try {
            return Integer.parseInt(value.toString());
        } catch (Exception e) {
            return 0;
        }
    }

    // 9. Obtener todo para el admin
    @GetMapping("/admin/usuarios")
    public ResponseEntity<?> getAdminUsuarios() {
        List<Map<String, Object>> users = db.queryForList("SELECT id, nombre, correo, bloqueado FROM usuarios WHERE nombre != 'admin'");
        
        for (Map<String, Object> u : users) {
            Long uid = ((Number) u.get("id")).longValue();

            Object b = u.get("bloqueado");
            boolean isBloqueado = false;
            if (b instanceof Boolean) isBloqueado = (Boolean) b;
            else if (b instanceof Number) isBloqueado = ((Number) b).intValue() == 1;
            u.put("bloqueado", isBloqueado);

            List<Map<String, Object>> enc = db.queryForList("SELECT * FROM encuestas WHERE usuario_id = ?", uid);
            u.put("encuesta", enc.isEmpty() ? null : enc.get(0));

            List<Map<String, Object>> reg = db.queryForList("SELECT * FROM registros_diarios WHERE usuario_id = ? ORDER BY fecha DESC LIMIT 1", uid);
            u.put("registro_diario", reg.isEmpty() ? null : reg.get(0));

            List<Map<String, Object>> alms = db.queryForList("SELECT hora, activada FROM alarmas WHERE usuario_id = ?", uid);
            for (Map<String, Object> a : alms) {
                Object val = a.get("activada");
                boolean isActivada = false;
                if (val instanceof Boolean) isActivada = (Boolean) val;
                else if (val instanceof Number) isActivada = ((Number) val).intValue() == 1;
                a.put("activada", isActivada);
            }
            u.put("alarmas", alms);
        }
        return ResponseEntity.ok(users);
    }

    // 8. Bloquear/Desbloquear usuario (Admin)
    @PutMapping("/admin/usuarios/{id}/bloquear")
    public ResponseEntity<?> bloquearUsuario(@PathVariable Long id, @RequestBody Map<String, Boolean> body) {
        db.update("UPDATE usuarios SET bloqueado = ? WHERE id = ?", body.get("bloquear"), id);
        return ResponseEntity.ok(Map.of("mensaje", "Estado de bloqueo actualizado"));
    }

    // 9. Eliminar usuario completo (Admin)
    @DeleteMapping("/admin/usuarios/{id}")
    public ResponseEntity<?> eliminarUsuario(@PathVariable Long id) {
        db.update("DELETE FROM alarmas WHERE usuario_id = ?", id);
        db.update("DELETE FROM registros_diarios WHERE usuario_id = ?", id);
        db.update("DELETE FROM encuestas WHERE usuario_id = ?", id);
        db.update("DELETE FROM chat_coach WHERE usuario_id = ?", id);
        db.update("DELETE FROM usuarios WHERE id = ?", id);
        return ResponseEntity.ok(Map.of("mensaje", "Usuario eliminado"));
    }

    // 10. Obtener lista de sesiones de chat del Coach
    @GetMapping("/coach/{nombre}/sesiones")
    public ResponseEntity<?> getSesionesCoach(@PathVariable String nombre) {
        List<Map<String, Object>> users = db.queryForList("SELECT id FROM usuarios WHERE nombre = ?", nombre);
        if (users.isEmpty()) return ResponseEntity.status(404).body(Map.of("error", "Usuario no encontrado"));
        Long userId = ((Number) users.get(0).get("id")).longValue();

        String sql = "SELECT session_id, MIN(fecha) as fecha, " +
                     "(SELECT texto FROM chat_coach c2 WHERE c2.session_id = c1.session_id ORDER BY id ASC LIMIT 1) as titulo " +
                     "FROM chat_coach c1 WHERE usuario_id = ? AND session_id IS NOT NULL " +
                     "GROUP BY session_id ORDER BY fecha DESC";
                     
        List<Map<String, Object>> sesiones = db.queryForList(sql, userId);
        return ResponseEntity.ok(sesiones);
    }

    // 11. Obtener mensajes de una sesión específica
    @GetMapping("/coach/{nombre}/sesion/{sessionId}")
    public ResponseEntity<?> getMensajesSesion(@PathVariable String nombre, @PathVariable String sessionId) {
        List<Map<String, Object>> users = db.queryForList("SELECT id FROM usuarios WHERE nombre = ?", nombre);
        if (users.isEmpty()) return ResponseEntity.status(404).body(Map.of("error", "Usuario no encontrado"));
        Long userId = ((Number) users.get(0).get("id")).longValue();
        
        List<Map<String, Object>> chat = db.queryForList("SELECT rol, texto FROM chat_coach WHERE usuario_id = ? AND session_id = ? ORDER BY id ASC", userId, sessionId);
        return ResponseEntity.ok(chat);
    }

    // 12. Guardar mensaje en el chat (Coach)
    @PostMapping("/coach")
    public ResponseEntity<?> guardarMensajeCoach(@RequestBody Map<String, Object> body) {
        List<Map<String, Object>> users = db.queryForList("SELECT id FROM usuarios WHERE nombre = ?", body.get("nombre"));
        if (users.isEmpty()) return ResponseEntity.status(404).body(Map.of("error", "Usuario no encontrado"));
        Long userId = ((Number) users.get(0).get("id")).longValue();
        
        db.update("INSERT INTO chat_coach (usuario_id, rol, texto, session_id) VALUES (?, ?, ?, ?)", 
            userId, body.get("rol"), body.get("texto"), body.get("session_id"));
        return ResponseEntity.ok(Map.of("mensaje", "Mensaje guardado"));
    }
}