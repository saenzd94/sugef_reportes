# ==============================================================================
# 03_helpers.R
# Funciones auxiliares transversales:
#   - Manejo y validación de fechas en formato SUGEF (YYYYMMDD)
#   - Resolución flexible de entidades (por nombre, abreviatura o código)
#   - Resolución de sectores (por nombre o código)
#   - Detección del corte normativo de cartera (enero 2024)
#   - Diagnóstico e intento de unión de reportes pre/post 2024
# ==============================================================================

library(dplyr)
library(tibble)

# ------------------------------------------------------------------------------
# Constantes
# ------------------------------------------------------------------------------

#' Fecha de corte para reportes de cartera de crédito
#'
#' Antes de esta fecha: normativa SUGEF 1-05, endpoint /ReporteCrediticioHasta2023/
#' Desde esta fecha:   normativa CONASSIF 14-21, endpoint /ReporteCrediticio/
FECHA_CORTE_CARTERA <- as.Date("2024-01-01")

# ------------------------------------------------------------------------------
# Manejo de fechas
# ------------------------------------------------------------------------------

#' Convierte una fecha al formato requerido por la API de SUGEF (YYYYMMDD)
#'
#' @param fecha Date, o character en formato "YYYY-MM-DD" o "YYYYMMDD".
#' @return character de 8 dígitos en formato YYYYMMDD.
#' @examples
#' a_fecha_sugef("2024-06-01")   # "20240601"
#' a_fecha_sugef(as.Date("2023-12-01"))  # "20231201"
a_fecha_sugef <- function(fecha) {
  # Si ya viene en formato YYYYMMDD
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
#' Siempre usa el primer día del mes. Si \code{from} o \code{to} no caen el día 1,
#' se ajustan automáticamente al primer día del mes correspondiente.
#'
#' @param from Date o character. Fecha de inicio.
#' @param to   Date o character o NULL. Fecha de fin (NULL = solo el mes de \code{from}).
#' @return Vector character de fechas en formato YYYYMMDD, una por mes.
secuencia_mensual_sugef <- function(from, to = NULL) {
  # from_dt <- as.Date(paste0(format(as.Date(from), "%Y-%m"), "-01"))
  from_dt <- if(!is(try(as.Date(from), silent = TRUE), "try-error")){
    as.Date(paste0(format(as.Date(from), "%Y-%m"), "-01"))
  } else {
    from = paste(substr(from, 1, 4), substr(from, 5, 6), substr(from, 7, 8), sep = "-")
    as.Date(paste0(format(as.Date(from), "%Y-%m"), "-01"))
  }
  
  to_dt   <- if(is.null(to)) {
    from_dt
  } else {
    # as.Date(paste0(format(as.Date(to), "%Y-%m"), "-01"))
    if(!is(try(as.Date(to), silent = TRUE), "try-error")){
      as.Date(paste0(format(as.Date(to), "%Y-%m"), "-01"))
    } else {
      to = paste(substr(to, 1, 4), substr(to, 5, 6), substr(to, 7, 8), sep = "-")
      as.Date(paste0(format(as.Date(to), "%Y-%m"), "-01"))
    }
  }
  
  if (to_dt < from_dt) stop("'to' debe ser mayor o igual a 'from'.")
  seq.Date(from = from_dt, to = to_dt, by = "month") %>% format("%Y%m%d")
}

# ------------------------------------------------------------------------------
# Resolución de entidades y sectores
# ------------------------------------------------------------------------------

#' Resuelve una especificación de entidad o sector a un data frame de entidades
#'
#' Acepta búsquedas por código exacto, nombre exacto, nombre abreviado, o
#' coincidencia parcial de nombre (sin distinción de mayúsculas/minúsculas).
#' Para sectores, filtra todas las entidades que pertenezcan al sector indicado.
#'
#' @param entidad character o NULL. Nombre (completo o parcial), abreviatura o
#'   código (COD_ENT / cédula jurídica). Puede ser un vector de múltiples valores.
#' @param sector  character o NULL. Nombre (completo o parcial) o código (COD_SEC)
#'   del sector supervisado. Se excluye mutuamente con \code{entidad}.
#' @param verbose lógico. Si TRUE, informa sobre coincidencias múltiples.
#' @return tibble con columnas COD_ENT, ABR_ENT, NOM_ENT, DES_SEC, COD_SEC,
#'   con una fila por entidad resuelta.
.resolver_entidades <- function(entidad = NULL, sector = NULL, verbose = TRUE) {
  if (is.null(entidad) && is.null(sector)) {
    stop("Debe especificar al menos uno de los argumentos: 'entidad' o 'sector'.")
  }
  if (!is.null(entidad) && !is.null(sector)) {
    stop("Especifique 'entidad' O 'sector', no ambos simultáneamente.")
  }
  df <- listar_entidades(usar_cache = TRUE, verbose = FALSE) %>% 
    # Se adicionan acronimos de BCR y BNCR para llamar a esas entidades por esos nombres
    mutate(NOM_ENT = case_when(grepl(toupper("Banco de Costa Rica"), NOM_ENT) == 1 ~ paste(NOM_ENT, "BCR", sep = " - "),
                               grepl(toupper("Banco Nacional"), NOM_ENT) == 1 ~ paste(NOM_ENT, "BNCR", sep = " - "),
                               TRUE ~ NOM_ENT)
           )

  # --- Resolución por entidad ---
  if (!is.null(entidad)) {
    entidad_v <- toupper(trimws(as.character(entidad)))
    filas <- lapply(entidad_v, function(e) {
      # Prioridad 1: código exacto (COD_ENT / cédula jurídica)
      m <- df[toupper(df$COD_ENT) == e, ]
      if (nrow(m) > 0) return(m)
      # Prioridad 2: nombre completo o abreviatura exactos
      m <- df[toupper(df$NOM_ENT) == e | toupper(df$ABR_ENT) == e, ]
      if (nrow(m) > 0) return(m)
      # Prioridad 3: coincidencia parcial en nombre o abreviatura
      m <- df[grepl(e, toupper(df$NOM_ENT), fixed = TRUE) |
              grepl(e, toupper(df$ABR_ENT), fixed = TRUE), ]
      if (nrow(m) == 0) {
        stop(sprintf(
          paste0("No se encontró ninguna entidad que coincida con: '%s'.\n",
                 "Use listar_entidades() para ver el listado completo.\n",
                 "Busque por COD_ENT (cédula jurídica), NOM_ENT o ABR_ENT."),
          e
        ))
      }
      if (nrow(m) > 1 && verbose) {
        message(sprintf(
          "Múltiples coincidencias para '%s':\n  %s\nSe incluirán todas. ",
          e, paste(m$NOM_ENT, collapse = "\n  ")
        ), "Para mayor precisión, use el COD_ENT.")
      }
      m
    })
    return(dplyr::bind_rows(filas) %>% dplyr::distinct())
  }

  # --- Resolución por sector ---
  sector_norm <- toupper(trimws(sector))
  # Prioridad 1: código exacto de sector
  m <- df[toupper(df$COD_SEC) == sector_norm, ]
  if (nrow(m) > 0) return(m)
  # Prioridad 2: coincidencia parcial en nombre de sector
  m <- df[grepl(sector_norm, toupper(df$DES_SEC), fixed = TRUE), ]
  if (nrow(m) == 0) {
    sectores_disp <- listar_sectores() %>%
      with(paste0("  [", COD_SEC, "] ", DES_SEC, collapse = "\n"))
    stop(sprintf(
      "No se encontró ningún sector que coincida con: '%s'.\nSectores disponibles:\n%s",
      sector, sectores_disp
    ))
  }
  secs_unicos <- unique(m$DES_SEC)
  if (verbose) {
    if (length(secs_unicos) > 1) {
      message(sprintf("Múltiples sectores coinciden con '%s':\n  %s\nSe incluirán todas sus entidades.",
                      sector, paste(secs_unicos, collapse = "\n  ")))
    } else {
      message(sprintf("Sector: %s — %d entidades encontradas.", secs_unicos, nrow(m)))
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
#' @return lista con:
#'   \itemize{
#'     \item \strong{hay_corte}: lógico, TRUE si hay fechas en ambos lados del corte.
#'     \item \strong{pre_2024}: vector de fechas anteriores a enero 2024.
#'     \item \strong{post_2024}: vector de fechas desde enero 2024.
#'   }
.detectar_corte_cartera <- function(fechas_sugef) {
  fechas_dt <- as.Date(fechas_sugef, format = "%Y%m%d")
  pre       <- fechas_sugef[fechas_dt < FECHA_CORTE_CARTERA]
  post      <- fechas_sugef[fechas_dt >= FECHA_CORTE_CARTERA]
  list(
    hay_corte = length(pre) > 0 && length(post) > 0,
    pre_2024  = pre,
    post_2024 = post
  )
}

# ------------------------------------------------------------------------------
# Intento de unión de bloques pre/post 2024
# ------------------------------------------------------------------------------

#' Intenta unir dos tibbles de cartera (pre/post 2024) con diagnóstico completo
#'
#' Compara las columnas de ambos bloques. Si son idénticas, hace \code{bind_rows}
#' directamente. Si difieren, intenta la unión con \code{bind_rows} de dplyr
#' (que rellena NAs en columnas faltantes) y advierte al usuario. Si la unión
#' falla por incompatibilidades de tipo, retorna una lista nombrada.
#'
#' @param df_pre  tibble con datos del período pre-2024.
#' @param df_post tibble con datos del período post-2023.
#' @return
#'   \itemize{
#'     \item Un tibble unido (con atributos de advertencia si hubo diferencias de columnas).
#'     \item Una lista con \code{$pre_2024}, \code{$post_2024} y \code{$no_unificado = TRUE}
#'       si la unión no fue posible.
#'   }
.intentar_union_cartera <- function(df_pre, df_post) {
  if (nrow(df_pre) == 0 && nrow(df_post) == 0) return(tibble::tibble())
  if (nrow(df_pre) == 0)  return(df_post)
  if (nrow(df_post) == 0) return(df_pre)

  cols_pre       <- names(df_pre)
  cols_post      <- names(df_post)
  cols_solo_pre  <- setdiff(cols_pre,  cols_post)
  cols_solo_post <- setdiff(cols_post, cols_pre)
  hay_diferencias <- length(cols_solo_pre) > 0 || length(cols_solo_post) > 0

  if (hay_diferencias) {
    msg_advertencia <- paste0(
      "Las columnas de los reportes pre y post 2024 difieren (cambio normativo).\n",
      if (length(cols_solo_pre)  > 0) sprintf("  Solo en pre-2024:   %s\n", paste(cols_solo_pre,  collapse = ", ")),
      if (length(cols_solo_post) > 0) sprintf("  Solo en post-2024:  %s\n", paste(cols_solo_post, collapse = ", ")),
      "Se realiza union con dplyr::bind_rows() rellenando NAs en columnas faltantes.\n",
      "Verifique el resultado. Si la union no es adecuada, use intentar_union = FALSE\n",
      "para recibir la lista $pre_2024 y $post_2024 por separado."
    )
    warning(msg_advertencia)
  }

  resultado <- tryCatch(
    dplyr::bind_rows(df_pre, df_post),
    error = function(e) {
      warning(sprintf(
        paste0("No fue posible unir los bloques pre/post 2024: %s\n",
               "Se retorna una lista con $pre_2024 y $post_2024 por separado."),
        conditionMessage(e)
      ))
      NULL
    }
  )

  if (is.null(resultado)) {
    return(list(
      pre_2024     = df_pre,
      post_2024    = df_post,
      no_unificado = TRUE
    ))
  }

  if (hay_diferencias) {
    attr(resultado, "advertencia_union")  <- TRUE
    attr(resultado, "cols_solo_pre_2024") <- cols_solo_pre
    attr(resultado, "cols_solo_post_2024")<- cols_solo_post
  }
  resultado
}
