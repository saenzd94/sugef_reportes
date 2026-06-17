# sugefReportes — Descripción del Proyecto

## Resumen

`sugefReportes` es un paquete de R de código abierto que proporciona acceso
programático a la **API REST pública de la Superintendencia General de Entidades
Financieras (SUGEF)** de Costa Rica. El paquete abstrae los detalles técnicos
del servicio web —manejo de solicitudes HTTP, parseo de respuestas XML/JSON,
iteración sobre períodos y entidades— y los expone mediante una única función
de alto nivel con la que el usuario puede obtener cualquier tipo de reporte
disponible con pocas líneas de código.

---

## Contexto y motivación

La SUGEF publica mensualmente información financiera y crediticia de las 49
entidades que supervisa —bancos estatales, bancos privados, cooperativas de
ahorro y crédito, financieras no bancarias, entre otras— a través de su
[API REST pública](https://www.sugef.fi.cr/Bccr.Sugef.Reportes_SitioWeb.API/index.html).
Esta información es de alto valor para el análisis del sistema financiero
costarricense: permite monitorear la evolución de balances, estados de
resultados, indicadores de solidez financiera y composición de la cartera de
crédito por sector económico, categoría de riesgo y días de atraso.

Sin embargo, la API requiere una llamada independiente por entidad y por período,
lo que hace que la extracción de series de tiempo o de datos de varios sectores
sea un proceso repetitivo y propenso a errores cuando se realiza manualmente.
`sugefReportes` automatiza completamente ese proceso.

---

## Reportes disponibles

El paquete cubre los reportes disponibles para entidades individuales en la API:

| Categoría | Reporte |
|---|---|
| **Financiero** | Balance de Situación |
| **Financiero** | Estado de Resultados |
| **Financiero** | Indicadores Financieros |
| **Cartera de crédito** | Por Actividad Económica |
| **Cartera de crédito** | Por Actividad Económica y Categoría de Riesgo |
| **Cartera de crédito** | Por Actividad Económica y Días de Atraso |
| **Cartera de crédito** | Por Categoría de Riesgo y Días de Atraso |

---

## Características principales

### Resolución flexible de entidades y sectores
La función principal acepta el nombre completo, la abreviatura o el código de
una entidad, así como el nombre de un sector supervisado. La resolución utiliza
coincidencia exacta y parcial sin distinción de mayúsculas, de modo que el
usuario no necesita conocer la nomenclatura exacta de la API.

### Rangos de fechas arbitrarios con iteración automática
La API solo admite un período por solicitud. El paquete genera automáticamente
la secuencia mensual de fechas en el rango indicado y consolida los resultados
en un único tibble listo para el análisis.

### Manejo del cambio normativo de enero 2024
Los reportes de cartera de crédito cambiaron de normativa y de estructura en
enero de 2024 (SUGEF 1-05 → CONASSIF 14-21), con endpoints y esquemas de
columnas distintos. El paquete detecta automáticamente si el rango de fechas
solicitado cruza ese umbral, procesa cada bloque con la normativa y el endpoint
correspondientes, y ofrece tres comportamientos configurables:

- **Unión automática** (`intentar_union = TRUE`, por defecto): consolida ambos
  bloques con `dplyr::bind_rows()`, rellenando con `NA` las columnas exclusivas
  de cada período y emitiendo una advertencia descriptiva con el detalle de
  las discrepancias.
- **Separación explícita** (`intentar_union = FALSE`): retorna una lista nombrada
  con `$pre_2024` y `$post_2024` para que el usuario decida cómo reconciliarlos.
- **Fallback automático**: si la unión falla por incompatibilidad de tipos, el
  paquete retorna la lista separada sin interrumpir la ejecución.

### Columnas de identificación automáticas
Todo resultado incluye columnas de metadatos añadidas al inicio —código de
entidad, nombre abreviado, nombre completo, sector y código de sector— junto
con el período en formato `YYYYMMDD`. Esto elimina la necesidad de joins
posteriores para identificar el origen de cada fila.

### Caché en memoria
Los catálogos de referencia (lista de entidades y catálogo de cuentas contables)
se almacenan en memoria durante la sesión de R. En análisis de sectores completos
o rangos largos, esto evita llamadas redundantes a la API y reduce el tiempo de
ejecución de manera significativa.

### Reintentos automáticos y control de velocidad
Cada llamada a la API incluye lógica de reintento configurable ante fallos de
red o respuestas inesperadas, y un parámetro de pausa entre llamadas sucesivas
para evitar saturar el servicio.

---

## Instalación

```r
# Requiere devtools o pak
devtools::install_github("usuario/sugefReportes")

# Alternativa con pak (más rápido)
pak::pkg_install("usuario/sugefReportes")
```

---

## Uso básico

```r
library(sugefReportes)

# Ver reportes disponibles
listar_reportes_disponibles()

# Balance de situación de BCR para junio 2024
obtener_reporte_sugef(entidad = "BCR", reporte = "balance", from = "2024-06-01")

# Estado de resultados de todos los bancos estatales, primer semestre 2024
obtener_reporte_sugef(
  sector  = "BANCOS COMERCIALES DEL ESTADO",
  reporte = "resultados",
  from    = "2024-01-01",
  to      = "2024-06-01"
)

# Cartera por actividad económica cruzando el corte normativo de enero 2024
obtener_reporte_sugef(
  entidad = "BCR",
  reporte = "cartera_actividad",
  from    = "2023-10-01",
  to      = "2024-03-01"
)
```

---

## Fuente de datos

- **Organismo**: Superintendencia General de Entidades Financieras (SUGEF)
- **País**: Costa Rica
- **API**: [https://www.sugef.fi.cr/Bccr.Sugef.Reportes_SitioWeb.API](https://www.sugef.fi.cr/Bccr.Sugef.Reportes_SitioWeb.API/index.html)
- **Actualización**: mensual
- **Acceso**: público, sin autenticación

---

## Dependencias

| Paquete | Uso |
|---|---|
| `httr` | Solicitudes HTTP GET/POST a la API |
| `XML` | Parseo de respuestas XML (endpoints de catálogo) |
| `jsonlite` | Parseo de respuestas JSON (endpoints de reportes) |
| `dplyr` | Manipulación y combinación de datos |
| `tibble` | Estructura de datos de salida |

**Versión mínima de R**: 4.1.0 (por uso del operador nativo `|>`)

---

## Licencia

MIT — uso libre para fines académicos, de investigación y comerciales.
