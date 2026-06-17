# ==============================================================================
# 04_reportes_financieros.R
# Reportes financieros contables: balance, estado de resultados, indicadores.
# ==============================================================================

.CONF_REPORTES_FINANCIEROS <- list(
  balance = list(
    nombre   = "Balance de Situacion",
    endpoint = "/ReportesFinancieraContable/MAPI/ReporteBalanceSituacionAnalisisFinancieroEntidad"
  ),
  resultados = list(
    nombre   = "Estado de Resultados",
    endpoint = "/ReportesFinancieraContable/MAPI/ReporteEstadoResultadosAnalisisFinancieroEntidad"
  ),
  indicadores = list(
    nombre   = "Indicadores Financieros",
    endpoint = "/ReportesFinancieraContable/MAPI/ReporteIndicadoresFinancierosEntidad"
  )
)

#' Llamada unitaria: un reporte financiero, una entidad, un período
#' @keywords internal
.reporte_financiero_unitario <- function(tipo_reporte, cod_entidad, periodo,
                                         codigo_cuenta = "",
                                         max_reintentos = 3, pausa = 1) {
  conf      <- .CONF_REPORTES_FINANCIEROS[[tipo_reporte]]
  body_list <- list(
    parametrosEntidad = list(
      codigoEntidad = as.character(cod_entidad),
      periodos      = as.character(periodo),
      codigoCuenta  = as.character(codigo_cuenta)
    )
  )
  resp <- .sugef_post(conf$endpoint, body_list,
                      max_reintentos = max_reintentos, pausa = pausa)
  if (is.null(resp)) return(tibble::tibble())
  .parsear_json_post(resp)
}

#' Llamada en lote: N entidades × M períodos para un reporte financiero
#' @keywords internal
.obtener_reportes_financieros <- function(tipo_reporte, entidades_df, periodos,
                                           codigo_cuenta = "",
                                           pausa_entre_llamadas = 0.5,
                                           verbose = TRUE) {
  conf           <- .CONF_REPORTES_FINANCIEROS[[tipo_reporte]]
  total_llamadas <- nrow(entidades_df) * length(periodos)

  if (verbose) {
    message(sprintf(
      "\nReporte: %s\nEntidades: %d | Periodos: %d | Total llamadas: %d",
      conf$nombre, nrow(entidades_df), length(periodos), total_llamadas
    ))
  }

  resultados <- vector("list", total_llamadas)
  contador   <- 0L

  for (i in seq_len(nrow(entidades_df))) {
    ent <- entidades_df[i, ]
    for (per in periodos) {
      contador <- contador + 1L
      if (verbose) {
        message(sprintf("  [%d/%d] %-50s | %s", contador, total_llamadas, ent$NOM_ENT, per))
      }
      df <- .reporte_financiero_unitario(tipo_reporte, ent$COD_ENT, per, codigo_cuenta)
      if (nrow(df) > 0) {
        df <- tibble::add_column(df,
          COD_ENT = ent$COD_ENT, ABR_ENT = ent$ABR_ENT,
          NOM_ENT = ent$NOM_ENT, DES_SEC = ent$DES_SEC,
          COD_SEC = ent$COD_SEC, PERIODO = per,
          .before = 1
        )
      }
      resultados[[contador]] <- df
      if (pausa_entre_llamadas > 0 && contador < total_llamadas) Sys.sleep(pausa_entre_llamadas)
    }
  }

  validos <- Filter(function(x) !is.null(x) && nrow(x) > 0, resultados)
  if (length(validos) == 0) {
    warning(sprintf("No se obtuvieron datos para '%s'.", conf$nombre))
    return(tibble::tibble())
  }
  dplyr::bind_rows(validos)
}
