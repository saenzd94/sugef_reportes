# sugefReportes <img src="man/figures/logo.png" align="right" height="120" alt="" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/usuario/sugefReportes/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/usuario/sugefReportes/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

Cliente R para la **API REST pública de SUGEF** (Superintendencia General de Entidades Financieras, Costa Rica). Permite descargar reportes financieros y de cartera de crédito para cualquier entidad supervisada o sector, en rangos de fechas arbitrarios, con un único comando.

---

## Instalación

```r
# Opción 1: devtools
install.packages("devtools")
devtools::install_github("usuario/sugefReportes")

# Opción 2: pak (más rápido, resuelve dependencias automáticamente)
install.packages("pak")
pak::pkg_install("usuario/sugefReportes")
```

> **Requisito**: R ≥ 4.1.0

---

## Uso rápido

```r
library(sugefReportes)

# Ver reportes disponibles
listar_reportes_disponibles()

# Balance de situación — BCR, junio 2024
obtener_reporte_sugef(entidad = "BCR", reporte = "balance", from = "2024-06-01")

# Estado de resultados — bancos estatales, primer semestre 2024
obtener_reporte_sugef(
  sector  = "BANCOS COMERCIALES DEL ESTADO",
  reporte = "resultados",
  from    = "2024-01-01",
  to      = "2024-06-01"
)

# Cartera cruzando el corte normativo de enero 2024
obtener_reporte_sugef(
  entidad = "BCR",
  reporte = "cartera_actividad",
  from    = "2023-10-01",
  to      = "2024-03-01"
)
```

---

## Reportes disponibles

| Tipo | Aliases | Descripción |
|---|---|---|
| `balance` | `"bs"` | Balance de Situación |
| `resultados` | `"er"` | Estado de Resultados |
| `indicadores` | `"if"` | Indicadores Financieros |
| `cartera_actividad` | `"act_econ"` | Cartera por Actividad Económica |
| `cartera_actividad_riesgo` | `"act_econ_riesgo"` | Cartera por Actividad Económica y Categoría de Riesgo |
| `cartera_actividad_atraso` | `"act_econ_atraso"` | Cartera por Actividad Económica y Días de Atraso |
| `cartera_riesgo_atraso` | `"riesgo_atraso"` | Cartera por Categoría de Riesgo y Días de Atraso |

---

## Características

- **Resolución flexible**: acepta nombre completo, abreviatura, coincidencia parcial o código (`COD_ENT`) de entidad, y nombre o código (`COD_SEC`) de sector.
- **Rangos de fechas**: itera mensualmente de forma automática; la API solo acepta un período por llamada.
- **Corte normativo enero 2024**: detecta si el rango cruza el umbral entre SUGEF 1-05 y CONASSIF 14-21, procesa cada bloque con su endpoint correcto e intenta unirlos (configurable vía `intentar_union`).
- **Columnas de identificación automáticas**: `COD_ENT`, `ABR_ENT`, `NOM_ENT`, `DES_SEC`, `COD_SEC`, `PERIODO` se añaden al inicio de cada resultado.
- **Caché en memoria**: los catálogos de referencia no se vuelven a descargar en la misma sesión.
- **Reintentos automáticos** y pausa configurable entre llamadas.

---

## Funciones exportadas

| Función | Descripción |
|---|---|
| `obtener_reporte_sugef()` | Función principal |
| `listar_entidades()` | Lista las 49 entidades supervisadas |
| `listar_sectores()` | Lista los sectores disponibles |
| `listar_catalogo_contable()` | Catálogo de cuentas contables |
| `listar_reportes_disponibles()` | Muestra tipos de reporte y aliases |
| `limpiar_cache_sugef()` | Limpia el caché de catálogos |
| `a_fecha_sugef()` | Convierte fecha a formato YYYYMMDD |
| `secuencia_mensual_sugef()` | Genera secuencia mensual de fechas |

---

## Fuente de datos

- **API**: [https://www.sugef.fi.cr/Bccr.Sugef.Reportes_SitioWeb.API](https://www.sugef.fi.cr/Bccr.Sugef.Reportes_SitioWeb.API/index.html)
- **Organismo**: SUGEF — Superintendencia General de Entidades Financieras, Costa Rica
- **Actualización**: mensual | **Acceso**: público, sin autenticación

---

## Dependencias

`httr`, `XML`, `jsonlite`, `dplyr`, `tibble`

---

## Licencia

MIT © Diego Sáenz Castro
