# ==============================================================================
# 06_obtener_reporte.R
# Función principal pública: obtener_reporte_sugef()
#
# Punto de entrada único que unifica el acceso a todos los tipos de reporte
# de la API REST de SUGEF. Orquesta la resolución de entidades, la generación
# de la secuencia de fechas y el despacho al módulo correspondiente
# (04_reportes_financieros.R o 05_reportes_cartera.R).
# ==============================================================================

# ------------------------------------------------------------------------------
# Registro de aliases de reportes
# ------------------------------------------------------------------------------

#' Tabla de aliases para los tipos de reporte
#' Permite que el usuario use nombres cortos, descriptivos o en inglés/español.
#' La columna "interno" es la clave usada en los módulos de despacho.
.TABLA_ALIASES <- data.frame(
  alias    = c(
    # Financieros
    "balance", "balance_situacion", "bs",
    "resultados", "estado_resultados", "er",
    "indicadores", "indicadores_financieros", "if",
    # Cartera
    "cartera_actividad", "actividad_economica", "act_econ",
    "cartera_actividad_riesgo", "actividad_riesgo", "act_econ_riesgo",
    "cartera_actividad_atraso", "actividad_atraso", "act_econ_atraso",
    "cartera_riesgo_atraso", "riesgo_atraso", "cat_riesgo_atraso"
  ),
  interno  = c(
    "balance",    "balance",    "balance",
    "resultados", "resultados", "resultados",
    "indicadores","indicadores","indicadores",
    "cartera_actividad",        "cartera_actividad",        "cartera_actividad",
    "cartera_actividad_riesgo", "cartera_actividad_riesgo", "cartera_actividad_riesgo",
    "cartera_actividad_atraso", "cartera_actividad_atraso", "cartera_actividad_atraso",
    "cartera_riesgo_atraso",    "cartera_riesgo_atraso",    "cartera_riesgo_atraso"
  ),
  stringsAsFactors = FALSE
)

#' Tipos que se despachan al módulo financiero
.TIPOS_FINANCIEROS <- c("balance", "resultados", "indicadores")

#' Tipos que se despachan al módulo de cartera
.TIPOS_CARTERA <- c("cartera_actividad", "cartera_actividad_riesgo",
                    "cartera_actividad_atraso", "cartera_riesgo_atraso")

# ------------------------------------------------------------------------------
# Función auxiliar de descubrimiento
# ------------------------------------------------------------------------------

#' Lista los tipos de reporte disponibles y sus aliases
#'
#' Muestra en consola (y retorna invisiblemente) la tabla completa de reportes
#' disponibles con todos sus aliases aceptados por \code{obtener_reporte_sugef()}.
#'
#' @return invisible data.frame con columnas "interno" y "aliases".
#' @export
listar_reportes_disponibles <- function() {
  df <- .TABLA_ALIASES
  resumen <- aggregate(alias ~ interno, data = df, FUN = function(x) paste(x, collapse = ", "))
  names(resumen) <- c("tipo_interno", "aliases_aceptados")
  cat("\n=== Reportes disponibles en obtener_reporte_sugef() ===\n\n")
  cat("--- REPORTES FINANCIEROS ---\n")
  fin <- resumen[resumen$tipo_interno %in% .TIPOS_FINANCIEROS, ]
  for (i in seq_len(nrow(fin))) {
    cat(sprintf("  %-28s aliases: %s\n", fin$tipo_interno[i], fin$aliases_aceptados[i]))
  }
  cat("\n--- REPORTES DE CARTERA DE CREDITO ---\n")
  car <- resumen[resumen$tipo_interno %in% .TIPOS_CARTERA, ]
  for (i in seq_len(nrow(car))) {
    cat(sprintf("  %-28s aliases: %s\n", car$tipo_interno[i], car$aliases_aceptados[i]))
  }
  cat(sprintf(
    "\nNOTA: Los reportes de cartera con rango de fechas que cruce enero 2024\n%s\n",
    "      cambian de normativa (SUGEF 1-05 → CONASSIF 14-21). Ver argumento intentar_union."
  ))
  invisible(resumen)
}

# ------------------------------------------------------------------------------
# Función principal
# ------------------------------------------------------------------------------

#' Obtiene reportes de la API de SUGEF para entidades y/o sectores en un rango de fechas
#'
#' @description
#' Función principal del proyecto \code{sugef-reportes}. Acepta nombres o códigos
#' de entidades y sectores, resuelve automáticamente la lista de entidades
#' correspondientes, genera la secuencia de fechas mensuales y descarga el reporte
#' solicitado para cada combinación entidad × período.
#'
#' Para conocer los tipos de reporte disponibles y sus aliases, use
#' \code{listar_reportes_disponibles()}.
#'
#' @param entidad character o NULL.
#'   Nombre (completo o parcial), abreviatura o código COD_ENT (cédula jurídica)
#'   de la(s) entidad(es). Puede ser un vector de varios valores.
#'   \emph{Se excluye mutuamente con \code{sector}.}
#' @param sector character o NULL.
#'   Nombre (completo o parcial) o código COD_SEC del sector supervisado.
#'   Se obtendrá el reporte para \emph{todas} las entidades del sector indicado.
#'   \emph{Se excluye mutuamente con \code{entidad}.}
#' @param reporte character.
#'   Tipo de reporte a obtener. Acepta los siguientes valores (con aliases):
#'   \itemize{
#'     \item \strong{"balance"} / "bs" / "balance_situacion"
#'     \item \strong{"resultados"} / "er" / "estado_resultados"
#'     \item \strong{"indicadores"} / "if" / "indicadores_financieros"
#'     \item \strong{"cartera_actividad"} / "act_econ" / "actividad_economica"
#'     \item \strong{"cartera_actividad_riesgo"} / "act_econ_riesgo"
#'     \item \strong{"cartera_actividad_atraso"} / "act_econ_atraso"
#'     \item \strong{"cartera_riesgo_atraso"} / "riesgo_atraso"
#'   }
#' @param from character o Date.
#'   Fecha de inicio del rango. Acepta "YYYY-MM-DD" o "YYYYMMDD".
#'   Siempre se ajusta al primer día del mes.
#' @param to character o Date o NULL.
#'   Fecha de fin del rango. Si es NULL (default), se usa el mismo mes que \code{from}.
#'   Acepta los mismos formatos que \code{from}.
#' @param dias_atraso character.
#'   Solo aplica a los reportes \code{"cartera_actividad_atraso"} y
#'   \code{"cartera_riesgo_atraso"}. Filtra por tramo de días de atraso:
#'   \code{""} (todos), \code{"1"} (al día), \code{"2"} (1-30 d.),
#'   \code{"3"} (31-60 d.), \code{"4"} (61-90 d.), \code{"5"} (91-180 d.),
#'   \code{"6"} (181 o más), \code{"7"} (cobro judicial).
#'   Default \code{""} (sin filtro).
#' @param codigo_cuenta character.
#'   Solo aplica a reportes financieros (balance, resultados, indicadores).
#'   Filtra por un código de cuenta específico del catálogo contable.
#'   Default \code{""} (todas las cuentas).
#' @param normativa_pre character.
#'   Código de normativa para períodos anteriores a enero 2024 (pre-CONASSIF 14-21).
#'   Default \code{"1"} (SUGEF 1-05). Solo aplica a reportes de cartera.
#' @param normativa_post character.
#'   Código de normativa para períodos desde enero 2024.
#'   Default \code{"1"} (CONASSIF 14-21). Solo aplica a reportes de cartera.
#' @param intentar_union lógico.
#'   Aplica solo a reportes de cartera cuando el rango cruza enero 2024.
#'   Si \code{TRUE} (default), intenta unir los bloques pre y post 2024 con
#'   \code{dplyr::bind_rows()}; si las columnas difieren, rellena con NA y advierte.
#'   Si \code{FALSE}, retorna siempre una lista con \code{$pre_2024} y \code{$post_2024}.
#' @param pausa_entre_llamadas numeric.
#'   Segundos de espera entre llamadas sucesivas a la API. Se recomienda un valor
#'   mínimo de 0.3 para evitar rechazos por rate-limiting. Default \code{0.5}.
#' @param verbose lógico.
#'   Si \code{TRUE} (default), muestra mensajes de progreso: nombre del reporte,
#'   total de llamadas planificadas, y estado de cada llamada individual.
#'
#' @return
#' \itemize{
#'   \item Un \strong{tibble} con los datos del reporte, con las siguientes columnas
#'     de identificación añadidas al inicio: \code{COD_ENT}, \code{ABR_ENT},
#'     \code{NOM_ENT}, \code{DES_SEC}, \code{COD_SEC}, \code{PERIODO} (YYYYMMDD).
#'     El resto de columnas son las devueltas por la API de SUGEF para ese reporte.
#'   \item Para reportes de cartera con corte normativo y \code{intentar_union = FALSE}
#'     o cuando la unión no es posible: una \strong{lista} con elementos nombrados
#'     \code{$pre_2024} y \code{$post_2024} (cada uno un tibble con las columnas
#'     de identificación).
#' }
#'
#' @examples
#' \dontrun{
#' # Cargar todas las funciones del proyecto
#' source("cargar_sugef.R")
#'
#' # Ver todos los sectores disponibles
#' listar_sectores()
#'
#' # Balance de situación de una entidad para un único mes
#' bs_bcr <- obtener_reporte_sugef(
#'   entidad = "BCR",
#'   reporte = "balance",
#'   from    = "2024-06-01"
#' )
#'
#' # Estado de resultados de todas las entidades de un sector, rango de 6 meses
#' er_bancos <- obtener_reporte_sugef(
#'   sector  = "BANCOS COMERCIALES DEL ESTADO",
#'   reporte = "resultados",
#'   from    = "2024-01-01",
#'   to      = "2024-06-01"
#' )
#'
#' # Cartera por actividad económica cruzando el corte normativo de enero 2024
#' cartera_bcr <- obtener_reporte_sugef(
#'   entidad = "4000000019",   # Código COD_ENT del BCR
#'   reporte = "cartera_actividad",
#'   from    = "2023-10-01",
#'   to      = "2024-03-01",
#'   intentar_union = TRUE
#' )
#'
#' # Cartera por actividad económica y días de atraso, sin filtro de días (todos)
#' cartera_atraso <- obtener_reporte_sugef(
#'   sector      = "BANCOS PRIVADOS",
#'   reporte     = "cartera_actividad_atraso",
#'   from        = "2024-01-01",
#'   to          = "2024-06-01",
#'   dias_atraso = ""
#' )
#'
#' # Múltiples entidades por nombre
#' multi_ent <- obtener_reporte_sugef(
#'   entidad = c("BCR", "BNCR", "BPDC"),
#'   reporte = "indicadores",
#'   from    = "2024-06-01"
#' )
#' }
#'
#' @export
obtener_reporte_sugef <- function(
  entidad              = NULL,
  sector               = NULL,
  reporte,
  from,
  to                   = NULL,
  dias_atraso          = "",
  codigo_cuenta        = "",
  normativa_pre        = "1",
  normativa_post       = "1",
  intentar_union       = TRUE,
  pausa_entre_llamadas = 0.5,
  verbose              = TRUE
) {

  # ── 1. Validar y resolver el tipo de reporte ──────────────────────────────
  reporte_norm <- tolower(trimws(reporte))
  idx          <- match(reporte_norm, .TABLA_ALIASES$alias)
  if (is.na(idx)) {
    listar_reportes_disponibles()
    stop(sprintf(
      "\nTipo de reporte no reconocido: '%s'.\nUse listar_reportes_disponibles() para ver las opciones.",
      reporte
    ))
  }
  reporte_interno <- .TABLA_ALIASES$interno[idx]

  # ── 2. Generar secuencia de períodos ──────────────────────────────────────
  periodos <- secuencia_mensual_sugef(from = from, to = to)
  if (verbose) {
    n_per <- length(periodos)
    rango  <- if (n_per == 1) periodos else paste0(periodos[1], " a ", periodos[n_per])
    message(sprintf("Período(s): %s (%d mes%s)", rango, n_per, if (n_per == 1) "" else "es"))
  }

  # ── 3. Resolver entidades ─────────────────────────────────────────────────
  entidades_df <- .resolver_entidades(entidad = entidad, sector = sector, verbose = verbose)

  # ── 4. Despachar al módulo correspondiente ────────────────────────────────
  if (reporte_interno %in% .TIPOS_FINANCIEROS) {
    resultado <- .obtener_reportes_financieros(
      tipo_reporte         = reporte_interno,
      entidades_df         = entidades_df,
      periodos             = periodos,
      codigo_cuenta        = codigo_cuenta,
      pausa_entre_llamadas = pausa_entre_llamadas,
      verbose              = verbose
    )

  } else if (reporte_interno %in% .TIPOS_CARTERA) {
    resultado <- .obtener_reportes_cartera(
      tipo_reporte         = reporte_interno,
      entidades_df         = entidades_df,
      periodos             = periodos,
      normativa_pre        = normativa_pre,
      normativa_post       = normativa_post,
      dias_atraso          = dias_atraso,
      intentar_union       = intentar_union,
      pausa_entre_llamadas = pausa_entre_llamadas,
      verbose              = verbose
    )
  }

  # ── 5. Resumen final ──────────────────────────────────────────────────────
  if (verbose) {
    if (is.data.frame(resultado)) {
      message(sprintf("\nListo. Filas retornadas: %d", nrow(resultado)))
    } else {
      message(sprintf(
        "\nListo. Resultado dividido por corte normativo: $pre_2024 (%d filas) | $post_2024 (%d filas).",
        nrow(resultado$pre_2024), nrow(resultado$post_2024)
      ))
    }
  }

  resultado
}
