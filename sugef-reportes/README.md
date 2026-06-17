# sugef-reportes

Proyecto en R para la extracción automática de reportes financieros y crediticios de la **API REST pública de SUGEF** (`https://www.sugef.fi.cr/Bccr.Sugef.Reportes_SitioWeb.API`).

Permite descargar reportes para cualquier entidad supervisada o para todas las entidades de un sector, en un rango de fechas arbitrario, con un único comando.

---

## Estructura del proyecto

```
sugef-reportes/
├── R/
│   ├── 01_api_core.R             # Capa HTTP: wrappers GET/POST, parsers XML/JSON
│   ├── 02_catalogo.R             # listar_entidades(), listar_catalogo_contable()
│   ├── 03_helpers.R              # Fechas, resolución de entidades/sectores, unión pre/post 2024
│   ├── 04_reportes_financieros.R # Balance, Estado de Resultados, Indicadores Financieros
│   ├── 05_reportes_cartera.R     # Cartera de crédito (4 tipos, manejo del corte normativo)
│   └── 06_obtener_reporte.R      # Función principal: obtener_reporte_sugef()
├── ejemplos/
│   └── ejemplo_uso.R             # Casos de uso completos y comentados
├── legacy/                       # Código anterior (API SOAP - referencia histórica)
├── cargar_sugef.R                # Script de carga: instala paquetes y fuente los módulos
├── .gitignore
└── README.md
```

---

## Instalación y carga

```r
# Clonar o descargar el repositorio, luego desde la raíz del proyecto:
source("cargar_sugef.R")
```

El script `cargar_sugef.R` instala automáticamente los paquetes necesarios (`httr`, `XML`, `jsonlite`, `dplyr`, `tibble`, `here`) si no están presentes, y carga los seis módulos en el orden correcto de dependencias.

---

## Uso básico

### Explorar el catálogo

```r
# Ver todos los tipos de reporte y sus aliases
listar_reportes_disponibles()

# Ver entidades supervisadas (49 entidades, 5 columnas)
listar_entidades()

# Ver sectores supervisados disponibles
listar_sectores()

# Ver catálogo contable completo (~11,849 cuentas)
listar_catalogo_contable()
```

### Función principal

```r
obtener_reporte_sugef(
  entidad  = NULL,       # nombre, abreviatura o código (COD_ENT) de entidad(es)
  sector   = NULL,       # nombre o código (COD_SEC) de un sector
  reporte,               # tipo de reporte (ver tabla abajo)
  from,                  # fecha de inicio ("YYYY-MM-DD" o "YYYYMMDD")
  to       = NULL,       # fecha de fin (NULL = solo el mes de 'from')
  ...                    # argumentos opcionales (ver documentación)
)
```

> **Nota**: `entidad` y `sector` son mutuamente excluyentes. Use uno u otro.

---

## Tipos de reporte disponibles

| Tipo (interno) | Aliases aceptados | Descripción |
|---|---|---|
| `balance` | `"bs"`, `"balance_situacion"` | Balance de Situación |
| `resultados` | `"er"`, `"estado_resultados"` | Estado de Resultados |
| `indicadores` | `"if"`, `"indicadores_financieros"` | Indicadores Financieros |
| `cartera_actividad` | `"act_econ"`, `"actividad_economica"` | Cartera por Actividad Económica |
| `cartera_actividad_riesgo` | `"act_econ_riesgo"`, `"actividad_riesgo"` | Cartera por Actividad Económica y Categoría de Riesgo |
| `cartera_actividad_atraso` | `"act_econ_atraso"`, `"actividad_atraso"` | Cartera por Actividad Económica y Días de Atraso |
| `cartera_riesgo_atraso` | `"riesgo_atraso"`, `"cat_riesgo_atraso"` | Cartera por Categoría de Riesgo y Días de Atraso |

---

## Ejemplos

### Reportes financieros

```r
# Balance de situación — una entidad, un mes
bs_bcr <- obtener_reporte_sugef(
  entidad = "BCR",
  reporte = "balance",
  from    = "2024-06-01"
)

# Estado de resultados — sector completo, rango de 6 meses
er_estatales <- obtener_reporte_sugef(
  sector  = "BANCOS COMERCIALES DEL ESTADO",
  reporte = "resultados",
  from    = "2024-01-01",
  to      = "2024-06-01"
)

# Múltiples entidades por nombre
multi <- obtener_reporte_sugef(
  entidad = c("BCR", "BNCR", "BPDC"),
  reporte = "indicadores",
  from    = "2024-06-01"
)
```

### Reportes de cartera

```r
# Cartera por actividad económica — sin cruce del corte normativo
cartera_post <- obtener_reporte_sugef(
  entidad = "BCR",
  reporte = "cartera_actividad",
  from    = "2024-01-01",
  to      = "2024-06-01"
)

# Con filtro de días de atraso (solo cobro judicial)
cartera_jud <- obtener_reporte_sugef(
  entidad     = "BCR",
  reporte     = "cartera_actividad_atraso",
  from        = "2024-06-01",
  dias_atraso = "7"
)
```

### Cruce del corte normativo de enero 2024

Los reportes de cartera cambiaron de normativa en enero 2024 (SUGEF 1-05 → CONASSIF 14-21), con endpoints y estructuras de columnas distintos. La función maneja esto automáticamente:

```r
# El rango 2023-10 a 2024-03 cruza el corte
cartera_cruce <- obtener_reporte_sugef(
  entidad        = "BCR",
  reporte        = "cartera_actividad",
  from           = "2023-10-01",
  to             = "2024-03-01",
  intentar_union = TRUE   # default: intenta unir con bind_rows()
)

# Si las columnas difieren, retorna la lista separada:
cartera_sep <- obtener_reporte_sugef(
  entidad        = "BCR",
  reporte        = "cartera_actividad",
  from           = "2023-10-01",
  to             = "2024-03-01",
  intentar_union = FALSE
)
# cartera_sep$pre_2024   → datos bajo SUGEF 1-05
# cartera_sep$post_2024  → datos bajo CONASSIF 14-21
```

**Comportamiento de `intentar_union`**:
- `TRUE` (default): ejecuta `dplyr::bind_rows()`. Si las columnas difieren, rellena con `NA` y emite una advertencia con el detalle de columnas discrepantes. El tibble resultado lleva atributos `advertencia_union`, `cols_solo_pre_2024` y `cols_solo_post_2024`.
- `FALSE`: siempre retorna la lista `$pre_2024` / `$post_2024`, independientemente de si las columnas coinciden.
- Si `bind_rows()` falla por incompatibilidad de tipos, retorna la lista separada automáticamente.

---

## Estructura de los resultados

Todos los tibbles retornados incluyen las siguientes **columnas de identificación** añadidas al inicio, antes de las columnas propias del reporte:

| Columna | Descripción |
|---|---|
| `COD_ENT` | Cédula jurídica de la entidad (ID usado por la API) |
| `ABR_ENT` | Nombre abreviado |
| `NOM_ENT` | Nombre completo |
| `DES_SEC` | Descripción del sector |
| `COD_SEC` | Código del sector |
| `PERIODO` | Período en formato `YYYYMMDD` |

```r
# Convertir PERIODO a Date para análisis temporal
resultado <- resultado %>%
  dplyr::mutate(FECHA = as.Date(PERIODO, format = "%Y%m%d"))
```

---

## Argumentos opcionales de `obtener_reporte_sugef()`

| Argumento | Tipo | Default | Descripción |
|---|---|---|---|
| `dias_atraso` | character | `""` | Solo para reportes `*_atraso`. `""` = todos; `"1"`=al día; `"2"`=1-30d; `"3"`=31-60d; `"4"`=61-90d; `"5"`=91-180d; `"6"`=181+; `"7"`=cobro judicial |
| `codigo_cuenta` | character | `""` | Solo para reportes financieros. Filtra por código de cuenta del catálogo contable. `""` = todas las cuentas |
| `normativa_pre` | character | `"1"` | Normativa para períodos pre-enero 2024 (cartera). `"1"` = SUGEF 1-05 |
| `normativa_post` | character | `"1"` | Normativa para períodos desde enero 2024 (cartera). `"1"` = CONASSIF 14-21 |
| `intentar_union` | lógico | `TRUE` | Para cartera con cruce de corte: intentar unir pre/post en un tibble único |
| `pausa_entre_llamadas` | numeric | `0.5` | Segundos de espera entre llamadas a la API (mínimo recomendado: 0.3) |
| `verbose` | lógico | `TRUE` | Mostrar mensajes de progreso |

---

## Resolución flexible de entidades

La función acepta búsquedas por:
- **Código exacto** (`COD_ENT` / cédula jurídica): `entidad = "4000000019"`
- **Nombre completo exacto**: `entidad = "BANCO DE COSTA RICA"`
- **Nombre abreviado exacto**: `entidad = "BCR"`
- **Coincidencia parcial** (sin distinción de mayúsculas): `entidad = "costa rica"`

Si hay múltiples coincidencias parciales, se incluyen todas y se avisa al usuario.

Para sectores, la búsqueda es equivalente sobre `DES_SEC` y `COD_SEC`.

---

## Caché

Los catálogos (lista de entidades y catálogo contable) se almacenan en memoria durante la sesión para evitar llamadas repetidas a la API. Para forzar una actualización:

```r
limpiar_cache_sugef()
```

---

## Notas técnicas

- La API admite solo consultas **fecha a fecha** (un período por llamada). Para rangos, la función itera mensualmente.
- Los endpoints GET de catálogo devuelven JSON embebido en XML/HTML; los endpoints POST de reportes devuelven JSON directamente.
- Las llamadas incluyen reintentos automáticos (3 intentos por defecto) con pausa entre ellos.
- El parámetro `codigoTipoEntidad` requerido por los reportes de cartera se obtiene automáticamente de `COD_SEC` en la lista de entidades.
- El proyecto **no** usa los reportes agregados por sector que ofrece la API, sino que agrega individualmente por entidad para mayor control y trazabilidad.

---

## Referencia de la API

- **API REST**: `https://www.sugef.fi.cr/Bccr.Sugef.Reportes_SitioWeb.API/index.html`
- **SUGEF**: Superintendencia General de Entidades Financieras de Costa Rica

---

## Dependencias

```r
# Instalar manualmente si es necesario:
install.packages(c("httr", "XML", "jsonlite", "dplyr", "tibble", "here"))
```
