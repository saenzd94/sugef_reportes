# ==============================================================================
# 06_obtener_reporte.R
# Función principal pública: obtener_reporte_sugef()
# ==============================================================================

.TABLA_ALIASES <- data.frame(
  alias = c(
    "balance", "balance_situacion", "bs",
    "resultados", "estado_resultados", "er",
    "indicadores", "indicadores_financieros", "if",
    "cartera_actividad", "actividad_economica", "act_econ",
    "cartera_actividad_riesgo", "actividad_riesgo", "act_econ_riesgo",
    "cartera_actividad_atraso", "actividad_atraso", "act_econ_atraso",
    "cartera_riesgo_atraso", "riesgo_atraso", "cat_riesgo_atraso"
  ),
  interno = c(
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

.TIPOS_FINANCIEROS <- c("balance", "resultados", "indicadores")
.TIPOS_CARTERA     <- c("cartera_actividad", "cartera_actividad_riesgo",
                        "cartera_actividad_atraso", "cartera_riesgo_atraso")

# ------------------------------------------------------------------------------
# Descubrimiento
# ------------------------------------------------------------------------------

#' Lista los tipos de reporte disponibles y sus aliases
#'
#' Muestra en consola la tabla completa de reportes aceptados por
#' [obtener_reporte_sugef()].
#'
#' @return invisible data.frame con columnas `tipo_interno` y `aliases_aceptados`.
#' @export
listar_reportes_disponibles <- function() {
  resumen <- stats::aggregate(alias ~ interno, data = .TABLA_ALIASES,
                              FUN = function(x) paste(x, collapse = ", "))
  names(resumen) <- c("tipo_interno", "aliases_aceptados")

  cat("\n=== Reportes disponibles en obtener_reporte_sugef() ===\n\n")
  cat("--- REPORTES FINANCIEROS ---\n")
  for (i in which(resumen$tipo_interno %in% .TIPOS_FINANCIEROS)) {
    cat(sprintf("  %-30s %s\n", resumen$tipo_interno[i], resumen$aliases_aceptados[i]))
  }
  cat("\n--- REPORTES DE CARTERA DE CREDITO ---\n")
  for (i in which(resumen$tipo_interno %in% .TIPOS_CARTERA)) {
    cat(sprintf("  %-30s %s\n", resumen$tipo_interno[i], resumen$aliases_aceptados[i]))
  }
  cat("\nNOTA: Reportes de cartera con rango que cruce enero 2024 cambian de normativa.\n",
      "      Ver argumento 'intentar_union'.\n\n")
  invisible(resumen)
}

# ------------------------------------------------------------------------------
# Función principal
# ------------------------------------------------------------------------------

#' Obtiene reportes de la API de SUGEF para entidades y/o sectores
#'
#' Función principal del paquete `sugefReportes`. Resuelve automáticamente las
#' entidades del sector o la entidad indicada, genera la secuencia mensual de
#' fechas en el rango solicitado, llama a la API por cada combinación
#' entidad × período y consolida los resultados en un tibble listo para el análisis.
#'
#' Para los reportes de cartera, detecta automáticamente si el rango cruza el
#' corte normativo de enero 2024 y gestiona ambos bloques de forma independiente.
#'
#' @param entidad character o `NULL`. Nombre, abreviatura o código `COD_ENT`
#'   (cédula jurídica) de la entidad. Puede ser un vector de varios valores.
#'   _Excluyente con `sector`._
#' @param sector character o `NULL`. Nombre o código `COD_SEC` del sector
#'   supervisado. Descarga el reporte para _todas_ las entidades del sector.
#'   _Excluyente con `entidad`._
#' @param reporte character. Tipo de reporte. Use `listar_reportes_disponibles()`
#'   para ver las opciones y aliases aceptados.
#' @param from character o `Date`. Fecha de inicio (`"YYYY-MM-DD"` o `"YYYYMMDD"`).
#'   Se ajusta automáticamente al primer día del mes.
#' @param to character, `Date` o `NULL`. Fecha de fin. `NULL` = solo el mes de `from`.
#' @param dias_atraso character. Para `cartera_actividad_atraso` y
#'   `cartera_riesgo_atraso`. `""` = todos los tramos; `"1"` = al día;
#'   `"2"` = 1-30 d.; `"3"` = 31-60 d.; `"4"` = 61-90 d.; `"5"` = 91-180 d.;
#'   `"6"` = 181 o más; `"7"` = cobro judicial. Default `""`.
#' @param codigo_cuenta character. Para reportes financieros. Filtra por código
#'   de cuenta del catálogo contable. `""` = todas las cuentas. Default `""`.
#' @param normativa_pre character. Normativa para períodos anteriores a enero 2024.
#'   Default `"1"` (SUGEF 1-05). Solo aplica a reportes de cartera.
#' @param normativa_post character. Normativa para períodos desde enero 2024.
#'   Default `"1"` (CONASSIF 14-21). Solo aplica a reportes de cartera.
#' @param intentar_union lógico. Para cartera con cruce de corte enero 2024.
#'   `TRUE` (default): intenta unir con `dplyr::bind_rows()`, rellena NAs si
#'   las columnas difieren y adjunta atributos descriptivos de la discrepancia.
#'   `FALSE`: siempre retorna lista `$pre_2024` / `$post_2024`.
#' @param pausa_entre_llamadas numeric. Segundos de espera entre llamadas a la API.
#'   Recomendado ≥ 0.3 para evitar rate-limiting. Default `0.5`.
#' @param verbose lógico. Si `TRUE` (default), muestra progreso detallado.
#'
#' @return
#' Un **tibble** con columnas de identificación añadidas al inicio
#' (`COD_ENT`, `ABR_ENT`, `NOM_ENT`, `DES_SEC`, `COD_SEC`, `PERIODO` en formato
#' `YYYYMMDD`), seguidas de las columnas propias del reporte.
#'
#' Para reportes de cartera con corte normativo y `intentar_union = FALSE`,
#' o cuando la unión no es posible, retorna una **lista** con elementos
#' `$pre_2024` y `$post_2024`.
#'
#' @examples
#' \dontrun{
#' library(sugefReportes)
#'
#' # Ver opciones disponibles
#' listar_reportes_disponibles()
#' listar_sectores()
#'
#' # Balance de situación — una entidad, un mes
#' obtener_reporte_sugef(entidad = "BCR", reporte = "balance", from = "2024-06-01")
#'
#' # Estado de resultados — sector completo, primer semestre 2024
#' obtener_reporte_sugef(
#'   sector  = "BANCOS COMERCIALES DEL ESTADO",
#'   reporte = "resultados",
#'   from    = "2024-01-01",
#'   to      = "2024-06-01"
#' )
#'
#' # Cartera cruzando el corte normativo de enero 2024
#' obtener_reporte_sugef(
#'   entidad = "BCR",
#'   reporte = "cartera_actividad",
#'   from    = "2023-10-01",
#'   to      = "2024-03-01"
#' )
#'
#' # Múltiples entidades por nombre
#' obtener_reporte_sugef(
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
  # 1. Resolver tipo de reporte
  reporte_norm    <- tolower(trimws(reporte))
  idx             <- match(reporte_norm, .TABLA_ALIASES$alias)
  if (is.na(idx)) {
    listar_reportes_disponibles()
    stop(sprintf("Tipo de reporte no reconocido: '%s'.", reporte))
  }
  reporte_interno <- .TABLA_ALIASES$interno[idx]

  # 2. Generar secuencia de períodos
  periodos <- secuencia_mensual_sugef(from = from, to = to)
  if (verbose) {
    n_per <- length(periodos)
    rango  <- if (n_per == 1) periodos else paste0(periodos[1], " a ", periodos[n_per])
    message(sprintf("Periodo(s): %s (%d mes%s)", rango, n_per, if (n_per == 1) "" else "es"))
  }

  # 3. Resolver entidades
  entidades_df <- .resolver_entidades(entidad = entidad, sector = sector, verbose = verbose)

  # 4. Despachar
  if (reporte_interno %in% .TIPOS_FINANCIEROS) {
    resultado <- .obtener_reportes_financieros(
      tipo_reporte         = reporte_interno,
      entidades_df         = entidades_df,
      periodos             = periodos,
      codigo_cuenta        = codigo_cuenta,
      pausa_entre_llamadas = pausa_entre_llamadas,
      verbose              = verbose
    )
  } else {
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

  # 5. Resumen final
  if (verbose) {
    if (is.data.frame(resultado)) {
      message(sprintf("\nListo. Filas retornadas: %d", nrow(resultado)))
    } else {
      message(sprintf(
        "\nListo. Lista dividida: $pre_2024 (%d filas) | $post_2024 (%d filas).",
        nrow(resultado$pre_2024), nrow(resultado$post_2024)
      ))
    }
  }
  resultado
}
