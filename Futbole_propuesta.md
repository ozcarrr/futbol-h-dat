# **Propuesta de Proyecto Integrador**

## **1\. Identificación**

| Nombre del proyecto | FutboLE |
| :---- | :---- |
| **Curso** | IIP323W — Tecnologías y Aplicaciones Web y Móviles |
| **Semestre** | 2026 (semestral) |
| **Sección** | 1 |
| **Profesor** | Cristóbal Maturana Ahumada |
| **Fecha de entrega** | Semana del 20 al 25 de julio de 2026 |

## **2\. Integrantes del grupo**

| Nombre completo | Correo UDD | Rol en el grupo |
| :---- | :---- | :---- |
| Emilio Hanna | e.hanna@udd.cl | Desarrollador |
| Oscar Pichuman | o.pichumanm@udd.cl | Desarrollador |
| Lukas Garrido | l.garridog@udd.cl | Desarrollador |

## **3\. Problema a resolver**

**¿Qué problema están abordando?**

   

  Trivia y entretenimiento relacionado con el fútbol. Actualmente existen juegos de adivinanzas de jugadores, pero buscamos crear una experiencia centrada específicamente en fútbol, donde los usuarios puedan poner a prueba sus conocimientos sobre jugadores y equipos mediante desafíos.

   

   

## **4\. Usuario objetivo**

**¿Quién es el usuario? Describan al menos una persona (edad, contexto, necesidad).**

   

Personas aficionadas al fútbol que quieran poner a prueba sus conocimientos deportivos de una manera rápida y entretenida.

Por ejemplo, un hombre de 30 años que sigue regularmente el fútbol y ha visto muchos partidos de su equipo, pero que quiere comprobar cuánto sabe sobre jugadores, equipos y sus respectivas trayectorias. 

   

   

## **5\. Propuesta de valor**

**Resuman en una frase: ¿por qué alguien usaría esta app en lugar de no usarla?**

FutboLE ofrece una forma rápida y entretenida de poner a prueba los conocimientos sobre jugadores y equipos de fútbol mediante juegos de adivinanza que entregan pistas progresivamente.    

   

## **6\. Funcionalidades principales**

**Listen entre 3 y 5 funcionalidades core que debe tener el MVP.**

* Adivinar el jugador: el usuario debe descubrir qué jugador de fútbol corresponde a las pistas entregadas por la aplicación.  
* Pistas sobre el jugador: mostrar información como nacionalidad, edad, equipo actual, equipo inicial, posición y otros datos relevantes para ayudar al usuario a identificarlo.  
* Adivinar el equipo: mostrar una parte ampliada/recortada del logo de un equipo y permitir que el usuario intente identificarlo. Si falla, se mostrará progresivamente una parte más amplia del logo.  
* Sistema de intentos y resultados: registrar los intentos del usuario y mostrar si logró identificar correctamente al jugador o equipo.  
* Lista de desafíos: disponer de múltiples jugadores y equipos para que el usuario pueda elegir diferentes desafíos en lugar de limitar la aplicación a un único desafío diario.

## **7\. Stack y dependencias**

**Tecnologías que usarán además de Flutter \+ Dart (APIs, librerías, BD local).**

   

   Flutter \+ Dart: desarrollo de la aplicación web y construcción de la interfaz mediante widgets.

API REST de fútbol: obtención de información actualizada de jugadores y equipos, incluyendo nacionalidad, edad, equipo actual, posición y trayectoria.

API de imágenes: obtención de fotografías de jugadores y logos de equipos cuando sea necesario.

HTTP / consumo de API REST: para realizar las solicitudes desde Flutter.

Figma: diseño y prototipado de la interfaz.

GitHub: control de versiones y trabajo colaborativo.

La aplicación buscará reducir la cantidad de información almacenada localmente, obteniendo los datos de jugadores y equipos mediante APIs externas.

   

## **8\. Diseño y mockup**

Adjunten el link del mockup en Miro o Figma (deben ser visibles para el profesor con el link).

**URL del mockup: [https\://www\.figma.com/proto/hk7G1b77Lub00KQWmyGaV5/Untitled?node-id=0-1\&t=dR19wjneBa74Lsyh-1](https://www.figma.com/proto/hk7G1b77Lub00KQWmyGaV5/Untitled?node-id=0-1&t=dR19wjneBa74Lsyh-1)** 

   

## **9\. Cronograma**

| Semana | Hito / Entregable | Responsable |
| :---- | :---- | :---- |
| 1 (06-07) | Propuesta \+ Mockup inicial | Todo el grupo  |
| 2 (13-07) | Interfaz de la app (widgets Flutter) | Todo el grupo  |
| 3 (20-07) | Consumo de API REST | Todo el grupo  |
| 4 (semana 20 al 25 jul) | Presentación \+ Control 2 | Todo el grupo  |

## **10\. Riesgos y supuestos**

**¿Qué puede salir mal? ¿Qué están asumiendo?**

   

   La API seleccionada podría no entregar todos los datos necesarios de los jugadores, como premios individuales, equipo inicial o trayectoria completa.

La información de algunos jugadores podría estar desactualizada, especialmente respecto al equipo actual.

La API podría tener límites de solicitudes que dificulten realizar muchas consultas durante el uso de la aplicación.

Las imágenes de jugadores y logos podrían tener restricciones de disponibilidad o uso.

El funcionamiento de la aplicación dependerá de la disponibilidad de la API externa y de una conexión a Internet.

Se asume que los datos entregados por la API son suficientemente completos y confiables para construir las pistas del juego.

Se asume que Flutter permite implementar correctamente la aplicación web y el consumo de las APIs seleccionadas.

   

   

## **11\. Firmas / Confirmación**

Al entregar este documento, el grupo confirma que los integrantes listados están comprometidos con el proyecto y conocen las fechas clave de la asignatura.

Firma del responsable del grupo: Emilio Hanna  
Fecha: 7/10/2026