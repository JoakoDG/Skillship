# skillship

Aplicación Flutter para agilizar y centralizar el papeleo de vinculaciones y
pasantías de alumnos de la universidad.

Tres roles: **estudiante**, **empresa** y **universidad**.

---

## Cómo levantar el flujo del estudiante (paso a paso)

### 1. Ejecutar el script SQL

Abrí tu proyecto en [Supabase](https://supabase.com) → **SQL Editor** → *New query*,
pegá todo el archivo [`supabase/schema.sql`](supabase/schema.sql) y presioná **Run**.

> Si ya lo habías ejecutado antes, **pegalo de nuevo**: el script es idempotente
> (no duplica nada) y así se crean las tablas nuevas que se hayan agregado.

Eso crea:

| Qué | Para qué |
| --- | --- |
| Tablas `pasantias`, `postulaciones`, `horas_pasantia`, `reclamos` | Propuestas, postulaciones, horas cargadas y reclamos |
| Tabla `perfiles_universidades` + columna `universidad_id` | Perfil de la entidad educativa y vínculo manual alumno ↔ universidad |
| Políticas RLS | Para que la app (rol `anon`) pueda leer y escribir |
| Bucket `documentos` de Storage | Donde se guardan los archivos del registro |
| Datos de ejemplo | 6 propuestas, 1 postulación **aceptada y en proceso** con horas cargadas, 1 reclamo, 1 postulación pendiente, y para la universidad: 1 cuenta demo con **2 alumnos vinculados** y **4 solicitudes** (2 pendientes, 1 en proceso, 1 rechazada) |

> Si no lo ejecutás, la app igualmente arranca: el registro te avisa que falta
> el script en vez de perder los archivos a medias.

### 2. Correr la app

```bash
flutter pub get
flutter run
```

### 3. Recorrer el flujo

1. **Registrarse** → *Registrarse* → rol *Estudiante* → completar nombre,
   institución y carrera, y cargar los 4 documentos pedidos
   (certificado de alumno regular, DNI, CUIL y analítico).
   Los archivos suben al bucket `documentos` y sus rutas quedan guardadas en
   `documentos_registro`.
2. **Iniciar sesión** → correo + contraseña + rol. Se valida contra la tabla
   `usuarios` y según el rol guardado entra a cada panel.
3. **Buscar pasantías** → lista las propuestas de `pasantias`, con buscador por
   título, empresa, ubicación, modalidad o carrera.
4. **Detalle de la propuesta** → *Enviar solicitud* crea la fila en
   `postulaciones` (estado `pendiente`).
5. **Gestionar pasantía** → muestra el trabajo actual, las horas trabajadas
   semanales y acumuladas, el tutor asignado, el detalle de las horas cargadas
   y todas las postulaciones. El apartado **Reclamos** es un campo escribible:
   lo que escribís se guarda en la tabla `reclamos` y aparece listado debajo
   como *Reclamos enviados*.
6. **Perfil** (barra lateral) → datos del estudiante y los documentos que quedaron
   guardados en la base de datos.

### Cuenta de prueba

Para ver el flujo completo sin registrarte:

| | |
| --- | --- |
| Correo | `estudiante@demo.com` |
| Contraseña | `demo1234` |
| Rol | Estudiante |

Tiene una pasantía **aceptada y en proceso** (con 5 semanas de horas cargadas),
un **reclamo de ejemplo** en el apartado de Reclamos y una postulación **pendiente**.

---

## Cómo levantar el flujo de la universidad (entidad educativa)

Usa el **mismo script SQL** del paso anterior (ya crea todo lo que hace falta).

### Recorrer el flujo

1. **Registrarse** → *Registrarse* → rol *Universidad* → completar nombre de la
   institución, CUIT y teléfono, y cargar los 4 documentos pedidos (convenio,
   DNI, estatuto social y constancia de CUIT). Los archivos suben al bucket
   `documentos` y la cuenta queda en `usuarios` + `perfiles_universidades`.
2. **Iniciar sesión** → correo + contraseña + rol. Entra al panel con dos
   pestañas: **Alumnos** y **Solicitudes**.
3. **Alumnos** → lista los alumnos **vinculados** a la institución. Con
   *Agregar alumno* se vincula a un estudiante existente **por su correo**; con
   el ícono de la derecha se lo desvincula. Tocar un alumno abre su detalle:
   carrera, institución, horas cargadas y sus postulaciones con estado.
4. **Solicitudes** → *Ver Solicitudes* lista las postulaciones de los alumnos
   (con estado). También se puede tocar un *Trabajo Disponible* para ver
   sólo las solicitudes de esa propuesta.
5. **Aceptar / Rechazar** → al tocar una solicitud pendiente se ve el detalle
   completo (alumno, empresa, descripción). *Aceptar* pide el **nombre del
   tutor** y guarda `estado = en_proceso` con tutor y fecha de inicio;
   *Rechazar* guarda `estado = rechazada`. En ambos casos la lista se
   refresca con el nuevo estado.
6. **Perfil** (barra lateral, en todas las pantallas) → datos de la entidad y
   los documentos subidos.

### Cuentas de prueba

| | |
| --- | --- |
| Correo | `universidad@demo.com` |
| Contraseña | `demo1234` |
| Rol | Universidad |

Tiene **2 alumnos vinculados** (Sofía y Martín, ambos con
`estudiante@demo.com` y `alumno@demo.com` / `demo1234`) y **4 solicitudes**:
2 pendientes para aceptar/rechazar, 1 en proceso y 1 rechazada.

---

## Estructura

```
lib/
├── main.dart                  # Arranque + conexión a Supabase
├── models/                    # Capa de modelos: Usuario, Pasantia,
│                              # Postulacion, RegistroHora, Reclamo,
│                              # Alumno, Solicitud
├── data/                      # Capa de datos (sin lógica en los widgets)
│   ├── supabase_service.dart      # Registro con archivos, login, perfiles
│   ├── pasantias_repository.dart  # Interfaz PasantiasRepository
│   ├── supabase_pasantias_repository.dart  # Implementación real
│   ├── mock_pasantias_repository.dart      # Mock en memoria
│   ├── universidad_repository.dart         # Interfaz UniversidadRepository
│   ├── supabase_universidad_repository.dart
│   ├── mock_universidad_repository.dart
│   ├── datos_de_prueba.dart                # Listas de datos de prueba
│   ├── repositorio_pasantias.dart          # Fachada con fallback a mocks
│   └── repositorio_universidad.dart        # Fachada con fallback a mocks
└── ui/                        # Capa de presentación
    ├── screens/               # Pantallas (una por flujo/rol)
    └── widgets/               # Button, CustomTextField, UploadField,
                               # perfil_universidad (diálogo compartido)
supabase/
└── schema.sql                 # Esquema + RLS + Storage + datos de ejemplo
```

### Capa de repositorios (patrón Repository)

Las pantallas **no** hablan directamente con Supabase: solo conocen las
interfaces `PasantiasRepository` y `UniversidadRepository`.

```
UI (screens/)  →  RepositorioPasantias (fachada)
                        ├─ SupabasePasantiasRepository  → base de datos real
                        └─ MockPasantiasRepository       → datos de prueba en listas

UI (screens/)  →  RepositorioUniversidad (fachada)
                        ├─ SupabaseUniversidadRepository → base de datos real
                        └─ MockUniversidadRepository      → datos de prueba en listas
```

La fachada prueba la conexión una sola vez: si Supabase responde usa la base
real; si no (falta `schema.sql`, no hay red, etc.) queda en **modo demo** con
los mocks de `datos_de_prueba.dart`, así la demo nunca se rompe.

---

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/codelabs/flutter-codelab-first)
- [Flutter documentation](https://docs.flutter.dev/)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
