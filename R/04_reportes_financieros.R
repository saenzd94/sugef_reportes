# ==============================================================================
# 04_reportes_financieros.R
# Funciones para obtener reportes financieros contables mediante la API REST:
#   - Balance de Situación
#   - Estado de Resultados
#   - Indicadores Financieros
#
# Todos usan POST con body tipo "parametrosEntidad" y el mismo patrón de parsing.
# ==============================================================================

library(tibble)
library(dplyr)

# ------------------------------------------------------------------------------
# Configuración de endpoints
# ------------------------------------------------------------------------------

#' Mapa de configuración para reportes financieros
#' Cada entrada define el endpoint y la estructura del cuerpo de solicitud.
.CONF_REPORTES_FINANCIEROS <- list(
  balance = list(
    nombre   = "Balance de Situación",
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

# ------------------------------------------------------------------------------
# Llamada unitaria (una entidad, un período)
# ------------------------------------------------------------------------------

#' Obtiene un reporte financiero para una entidad y un período específicos
#'
#' Función interna de bajo nivel. Construye el body JSON, llama al endpoint POST
#' y parsea la respuesta. Retorna tibble vacío si la llamada falla o la entidad
#' no tiene datos para ese período.
#'
#' @param tipo_reporte  character. Clave interna: "balance", "resultados" o "indicadores".
#' @param cod_entidad   character. COD_ENT (cédula jurídica) de la entidad.
#' @param periodo       character. Período en formato YYYYMMDD.
#' @param codigo_cuenta character. Código de cuenta para filtrar (vacío = todas las cuentas).
#' @param max_reintentos integer. Reintentos en caso de fallo de red.
#' @param pausa         numeric. Segundos de espera entre reintentos.
#' @return tibble con el reporte, o tibble vacío si no hay datos o falla la llamada.
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

# ------------------------------------------------------------------------------
# Llamada en lote (N entidades × M períodos)
# ------------------------------------------------------------------------------

#' Obtiene reportes financieros para múltiples entidades y períodos
#'
#' Itera secuencialmente por cada combinación entidad × período, añade columnas
#' de identificación a cada resultado y combina todo en un único tibble.
#' Las combinaciones que no retornan datos se omiten silenciosamente;
#' si ninguna retorna datos, emite una advertencia y devuelve tibble vacío.
#'
#' Columnas añadidas al inicio de cada resultado (antes de las columnas propias del reporte):
#' COD_ENT, ABR_ENT, NOM_ENT, DES_SEC, COD_SEC, PERIODO.
#'
#' @param tipo_reporte        character. "balance", "resultados" o "indicadores".
#' @param entidades_df        tibble. Salida de .resolver_entidades().
#' @param periodos            character. Vector de períodos en formato YYYYMMDD.
#' @param codigo_cuenta       character. Código de cuenta para filtrar.
#' @param pausa_entre_llamadas numeric. Segundos de espera entre llamadas sucesivas.
#' @param verbose             lógico. Si TRUE, muestra progreso llamada a llamada.
#' @return tibble combinado con todas las filas de todos los reportes.
.obtener_reportes_financieros <- function(tipo_reporte, entidades_df, periodos,
                                           codigo_cuenta = "",
                                           pausa_entre_llamadas = 0.5,
                                           verbose = TRUE) {
  conf           <- .CONF_REPORTES_FINANCIEROS[[tipo_reporte]]
  total_llamadas <- nrow(entidades_df) * length(periodos)

  if (verbose) {
    message(sprintf(
      "\nReporte: %s\nEntidades: %d | Períodos: %d | Total de llamadas: %d",
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
      df <- .reporte_financiero_unitario(
        tipo_reporte  = tipo_reporte,
        cod_entidad   = ent$COD_ENT,
        periodo       = per,
        codigo_cuenta = codigo_cuenta
      )
      if (nrow(df) > 0) {
        df <- tibble::add_column(df,
          COD_ENT = ent$COD_ENT,
          ABR_ENT = ent$ABR_ENT,
          NOM_ENT = ent$NOM_ENT,
          DES_SEC = ent$DES_SEC,
          COD_SEC = ent$COD_SEC,
          PERIODO = per,
          .before = 1
        )
      }
      resultados[[contador]] <- df
      if (pausa_entre_llamadas > 0 && contador < total_llamadas) Sys.sleep(pausa_entre_llamadas)
    }
  }

  validos <- Filter(function(x) !is.null(x) && nrow(x) > 0, resultados)
  if (length(validos) == 0) {
    warning(sprintf(
      "No se obtuvieron datos para '%s'. Verifique las entidades y períodos.", conf$nombre
    ))
    return(tibble::tibble())
  }
  dplyr::bind_rows(validos)
}
