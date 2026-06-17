# ==============================================================================
# 03_helpers.R
# Funciones auxiliares: fechas, resolución de entidades/sectores,
# diagnóstico e intento de unión de reportes pre/post 2024.
# ==============================================================================

#' Fecha de corte para reportes de cartera de crédito
#'
#' Antes: normativa SUGEF 1-05, endpoint `/ReporteCrediticioHasta2023/`
#' Desde: normativa CONASSIF 14-21, endpoint `/ReporteCrediticio/`
#' @keywords internal
FECHA_CORTE_CARTERA <- as.Date("2024-01-01")

# ------------------------------------------------------------------------------
# Manejo de fechas
# ------------------------------------------------------------------------------

#' Convierte una fecha al formato requerido por la API de SUGEF (YYYYMMDD)
#'
#' @param fecha `Date` o character en formato `"YYYY-MM-DD"` o `"YYYYMMDD"`.
#' @return character de 8 dígitos en formato YYYYMMDD.
#' @export
#'
#' @examples
#' a_fecha_sugef("2024-06-01")           # "20240601"
#' a_fecha_sugef(as.Date("2023-12-01"))  # "20231201"
a_fecha_sugef <- function(fecha) {
  if (is.character(fecha) && all(grepl("^[0-9]{8}$", trimws(fecha)))) {
    return(trimws(fecha))
  }
  fecha_dt <- tryCatch(
    as.Date(fecha),
    error = function(e) stop(sprintf(
      "Formato de fecha no reconocido: '%s'. Use 'YYYY-MM-DD' o 'YYYYMMDD'.", fecha
    ))
  )
  format(fecha_dt, "%Y%m%d")
}

#' Genera una secuencia mensual de fechas en formato SUGEF (YYYYMMDD)
#'
#' Siempre usa el primer día de cada mes. Si `from` o `to` no son el día 1,
#' se ajustan automáticamente.
#'
#' @param from `Date` o character. Fecha de inicio.
#' @param to   `Date`, character o `NULL`. Fecha de fin. `NULL` = solo el mes de `from`.
#' @return Vector character de fechas en formato YYYYMMDD, una por mes.
#' @export
#'
#' @examples
#' secuencia_mensual_sugef("2024-01-01", "2024-06-01")
#' secuencia_mensual_sugef("2024-06-15")  # ajusta al primer día del mes
secuencia_mensual_sugef <- function(from, to = NULL) {
  from_dt <- as.Date(paste0(format(as.Date(from), "%Y-%m"), "-01"))
  to_dt   <- if (is.null(to)) from_dt else as.Date(paste0(format(as.Date(to), "%Y-%m"), "-01"))
  if (to_dt < from_dt) stop("'to' debe ser mayor o igual a 'from'.")
  seq.Date(from = from_dt, to = to_dt, by = "month") |> format("%Y%m%d")
}

# ------------------------------------------------------------------------------
# Resolución de entidades y sectores
# ------------------------------------------------------------------------------

#' Resuelve una especificación de entidad o sector al data frame de entidades
#'
#' Acepta código exacto, nombre exacto, abreviatura o coincidencia parcial
#' (sin distinción de mayúsculas). Para sectores, retorna todas las entidades
#' del sector indicado.
#'
#' @param entidad character o `NULL`. Nombre, abreviatura o `COD_ENT`. Puede ser vector.
#' @param sector  character o `NULL`. Nombre o `COD_SEC`. Excluyente con `entidad`.
#' @param verbose lógico. Si `TRUE`, informa sobre coincidencias múltiples.
#' @return tibble con columnas `COD_ENT`, `ABR_ENT`, `NOM_ENT`, `DES_SEC`, `COD_SEC`.
#' @keywords internal
.resolver_entidades <- function(entidad = NULL, sector = NULL, verbose = TRUE) {
  if (is.null(entidad) && is.null(sector)) {
    stop("Debe especificar al menos uno de: 'entidad' o 'sector'.")
  }
  if (!is.null(entidad) && !is.null(sector)) {
    stop("Especifique 'entidad' O 'sector', no ambos simultaneamente.")
  }
  df <- listar_entidades(usar_cache = TRUE, verbose = FALSE)

  # --- Por entidad ---
  if (!is.null(entidad)) {
    entidad_v <- toupper(trimws(as.character(entidad)))
    filas <- lapply(entidad_v, function(e) {
      m <- df[toupper(df$COD_ENT) == e, ]
      if (nrow(m) > 0) return(m)
      m <- df[toupper(df$NOM_ENT) == e | toupper(df$ABR_ENT) == e, ]
      if (nrow(m) > 0) return(m)
      m <- df[grepl(e, toupper(df$NOM_ENT), fixed = TRUE) |
              grepl(e, toupper(df$ABR_ENT), fixed = TRUE), ]
      if (nrow(m) == 0) {
        stop(sprintf(
          paste0("No se encontro ninguna entidad que coincida con: '%s'.\n",
                 "Use listar_entidades() para ver el listado completo."), e
        ))
      }
      if (nrow(m) > 1 && verbose) {
        message(sprintf(
          "Multiples coincidencias para '%s':\n  %s\nSe incluiran todas. Use COD_ENT para mayor precision.",
          e, paste(m$NOM_ENT, collapse = "\n  ")
        ))
      }
      m
    })
    return(dplyr::bind_rows(filas) |> dplyr::distinct())
  }

  # --- Por sector ---
  sector_norm <- toupper(trimws(sector))
  m <- df[toupper(df$COD_SEC) == sector_norm, ]
  if (nrow(m) > 0) return(m)
  m <- df[grepl(sector_norm, toupper(df$DES_SEC), fixed = TRUE), ]
  if (nrow(m) == 0) {
    sectores_disp <- listar_sectores() |>
      with(paste0("  [", COD_SEC, "] ", DES_SEC, collapse = "\n"))
    stop(sprintf(
      "No se encontro ningun sector que coincida con: '%s'.\nSectores disponibles:\n%s",
      sector, sectores_disp
    ))
  }
  secs_unicos <- unique(m$DES_SEC)
  if (verbose) {
    if (length(secs_unicos) > 1) {
      message(sprintf("Multiples sectores coinciden con '%s':\n  %s\nSe incluiran todas sus entidades.",
                      sector, paste(secs_unicos, collapse = "\n  ")))
    } else {
      message(sprintf("Sector: %s | %d entidades.", secs_unicos, nrow(m)))
    }
  }
  m
}

# ------------------------------------------------------------------------------
# Detección del corte normativo de cartera
# ------------------------------------------------------------------------------

#' Detecta si un vector de fechas cruza el corte normativo de cartera (enero 2024)
#'
#' @param fechas_sugef vector character de fechas en formato YYYYMMDD.
#' @return lista con `hay_corte` (lógico), `pre_2024` (vector) y `post_2024` (vector).
#' @keywords internal
.detectar_corte_cartera <- function(fechas_sugef) {
  fechas_dt <- as.Date(fechas_sugef, format = "%Y%m%d")
  pre       <- fechas_sugef[fechas_dt <  FECHA_CORTE_CARTERA]
  post      <- fechas_sugef[fechas_dt >= FECHA_CORTE_CARTERA]
  list(hay_corte = length(pre) > 0 && length(post) > 0,
       pre_2024  = pre,
       post_2024 = post)
}

# ------------------------------------------------------------------------------
# Unión de bloques pre/post 2024
# ------------------------------------------------------------------------------

#' Intenta unir dos tibbles de cartera (pre/post 2024) con diagnóstico
#'
#' Si las columnas son idénticas hace `bind_rows` directamente. Si difieren,
#' lo intenta igualmente (dplyr rellena con NA) y advierte. Si falla por tipos,
#' retorna lista nombrada con `$pre_2024` y `$post_2024`.
#'
#' @param df_pre  tibble con datos del período pre-2024.
#' @param df_post tibble con datos del período post-2023.
#' @return tibble unido (posiblemente con atributos de advertencia),
#'   o lista con `$pre_2024`, `$post_2024` y `$no_unificado = TRUE`.
#' @keywords internal
.intentar_union_cartera <- function(df_pre, df_post) {
  if (nrow(df_pre) == 0 && nrow(df_post) == 0) return(tibble::tibble())
  if (nrow(df_pre) == 0)  return(df_post)
  if (nrow(df_post) == 0) return(df_pre)

  cols_solo_pre  <- setdiff(names(df_pre),  names(df_post))
  cols_solo_post <- setdiff(names(df_post), names(df_pre))
  hay_diferencias <- length(cols_solo_pre) > 0 || length(cols_solo_post) > 0

  if (hay_diferencias) {
    warning(paste0(
      "Las columnas de los reportes pre y post 2024 difieren (cambio normativo).\n",
      if (length(cols_solo_pre)  > 0) sprintf("  Solo en pre-2024:   %s\n", paste(cols_solo_pre,  collapse = ", ")),
      if (length(cols_solo_post) > 0) sprintf("  Solo en post-2024:  %s\n", paste(cols_solo_post, collapse = ", ")),
      "Se realiza union con dplyr::bind_rows() (NAs en columnas faltantes).\n",
      "Para recibir los bloques por separado use intentar_union = FALSE."
    ))
  }

  resultado <- tryCatch(
    dplyr::bind_rows(df_pre, df_post),
    error = function(e) {
      warning(sprintf(
        "No fue posible unir los bloques: %s\nSe retorna lista con $pre_2024 y $post_2024.",
        conditionMessage(e)
      ))
      NULL
    }
  )

  if (is.null(resultado)) {
    return(list(pre_2024 = df_pre, post_2024 = df_post, no_unificado = TRUE))
  }
  if (hay_diferencias) {
    attr(resultado, "advertencia_union")   <- TRUE
    attr(resultado, "cols_solo_pre_2024")  <- cols_solo_pre
    attr(resultado, "cols_solo_post_2024") <- cols_solo_post
  }
  resultado
}
