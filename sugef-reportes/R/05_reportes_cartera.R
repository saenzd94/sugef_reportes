# ==============================================================================
# 05_reportes_cartera.R
# Funciones para obtener reportes de cartera de crédito mediante la API REST.
#
# CAMBIO NORMATIVO ENERO 2024:
#   Antes de enero 2024 → normativa SUGEF 1-05
#     Endpoint base: /ReporteCrediticioHasta2023/MAPI/
#   Desde enero 2024   → normativa CONASSIF 14-21
#     Endpoint base: /ReporteCrediticio/MAPI/
#
#   Los cuatro tipos de reporte de cartera existen en ambas versiones del endpoint.
#   Cuando el rango de fechas solicitado cruza el corte, esta función procesa
#   cada bloque por separado y luego intenta unirlos (ver .intentar_union_cartera).
#
# NOTA SOBRE codigoTipoEntidad:
#   Los reportes de cartera requieren el código de sector (COD_SEC) de la entidad,
#   que se pasa como 'codigoTipoEntidad' en el body de la solicitud.
# ==============================================================================

library(tibble)
library(dplyr)

# ------------------------------------------------------------------------------
# Configuración de endpoints de cartera
# ------------------------------------------------------------------------------

#' Mapa de configuración de endpoints para reportes de cartera.
#' Cada entrada define: nombre, alias, y configuración por bloque (post_2023 / pre_2024),
#' con indicación de si el endpoint requiere el parámetro diasAtraso.
.CONF_REPORTES_CARTERA <- list(

  cartera_actividad = list(
    nombre  = "Cartera por Actividad Económica",
    post_2023 = list(
      endpoint        = "/ReporteCrediticio/MAPI/ReporteActividadEconomica",
      param_body      = "parametrosCrediticio",
      usa_dias_atraso = FALSE
    ),
    pre_2024 = list(
      endpoint        = "/ReporteCrediticioHasta2023/MAPI/ReporteActividadEconomicaHasta2023",
      param_body      = "parametrosCrediticio",
      usa_dias_atraso = FALSE
    )
  ),

  cartera_actividad_riesgo = list(
    nombre  = "Cartera por Actividad Económica y Categoría de Riesgo",
    post_2023 = list(
      endpoint        = "/ReporteCrediticio/MAPI/ReporteActividadEconomicaCategoriaRiesgo",
      param_body      = "parametrosCrediticio",
      usa_dias_atraso = FALSE
    ),
    pre_2024 = list(
      endpoint        = "/ReporteCrediticioHasta2023/MAPI/ReporteActividadEconomicaCategoriaRiesgoHasta2023",
      param_body      = "parametrosCrediticio",
      usa_dias_atraso = FALSE
    )
  ),

  cartera_actividad_atraso = list(
    nombre  = "Cartera por Actividad Económica y Días de Atraso",
    post_2023 = list(
      endpoint        = "/ReporteCrediticio/MAPI/ReporteActividadEconomicaDiasAtraso",
      param_body      = "parametrosCrediticioDiasAtraso",
      usa_dias_atraso = TRUE
    ),
    pre_2024 = list(
      endpoint        = "/ReporteCrediticioHasta2023/MAPI/ReporteActividadEconomicaDiasAtrasoHasta2023",
      param_body      = "parametrosCrediticioDiasAtraso",
      usa_dias_atraso = TRUE
    )
  ),

  cartera_riesgo_atraso = list(
    nombre  = "Cartera por Categoría de Riesgo y Días de Atraso",
    post_2023 = list(
      endpoint        = "/ReporteCrediticio/MAPI/ReporteCategoriaRiesgoDiasAtraso",
      param_body      = "parametrosCrediticioDiasAtraso",
      usa_dias_atraso = TRUE
    ),
    pre_2024 = list(
      endpoint        = "/ReporteCrediticioHasta2023/MAPI/ReporteCategoriaRiesgoDiasAtrasoHasta2023",
      param_body      = "parametrosCrediticioDiasAtraso",
      usa_dias_atraso = TRUE
    )
  )
)

# ------------------------------------------------------------------------------
# Llamada unitaria (una entidad, un período)
# ------------------------------------------------------------------------------

#' Obtiene un reporte de cartera para una entidad y un período específicos
#'
#' Determina automáticamente si el período cae antes o después del corte de
#' enero 2024 y usa el endpoint y la normativa correspondientes.
#'
#' @param tipo_reporte  character. Clave interna del reporte de cartera.
#' @param cod_entidad   character. COD_ENT (cédula jurídica) de la entidad.
#' @param cod_sector    character. COD_SEC del sector de la entidad.
#' @param periodo       character. Período en formato YYYYMMDD.
#' @param normativa     character. Código de normativa para el período correspondiente.
#' @param dias_atraso   character. Filtro de días de atraso (vacío = todos).
#'   Valores válidos: "" (todos), "1" (al día), "2" (1-30 d.), "3" (31-60 d.),
#'   "4" (61-90 d.), "5" (91-180 d.), "6" (181 o más), "7" (cobro judicial).
#' @param max_reintentos integer. Reintentos en caso de fallo de red.
#' @param pausa         numeric. Segundos de espera entre reintentos.
#' @return tibble con el reporte, o tibble vacío si no hay datos.
.reporte_cartera_unitario <- function(tipo_reporte, cod_entidad, cod_sector,
                                      periodo, normativa = "1", dias_atraso = "",
                                      max_reintentos = 3, pausa = 1) {
  periodo_dt <- as.Date(periodo, format = "%Y%m%d")
  es_pre_2024 <- periodo_dt < FECHA_CORTE_CARTERA

  conf_periodo <- if (es_pre_2024) {
    .CONF_REPORTES_CARTERA[[tipo_reporte]]$pre_2024
  } else {
    .CONF_REPORTES_CARTERA[[tipo_reporte]]$post_2023
  }

  # Construir parámetros base
  params <- list(
    codigoEntidad     = as.character(cod_entidad),
    codigoTipoEntidad = as.character(cod_sector),
    periodos          = as.character(periodo),
    normativa         = as.character(normativa)
  )
  # Añadir diasAtraso solo si el endpoint lo requiere
  if (conf_periodo$usa_dias_atraso) {
    params$diasAtraso <- as.character(dias_atraso)
  }

  body_list <- setNames(list(params), conf_periodo$param_body)
  resp <- .sugef_post(conf_periodo$endpoint, body_list,
                      max_reintentos = max_reintentos, pausa = pausa)
  if (is.null(resp)) return(tibble::tibble())
  .parsear_json_post(resp)
}

# ------------------------------------------------------------------------------
# Llamada en lote con manejo del corte normativo
# ------------------------------------------------------------------------------

#' Recopila un bloque de reportes de cartera (N entidades × M períodos del mismo bloque)
#'
#' Función interna auxiliar. Itera entidades × períodos, añade metadatos de
#' identificación y combina en un tibble.
#'
#' @param tipo_reporte  character. Clave interna del reporte.
#' @param entidades_df  tibble. Entidades resueltas.
#' @param periodos_bloque character. Períodos del bloque (todos pre-2024 o todos post).
#' @param normativa     character. Normativa para este bloque.
#' @param dias_atraso   character. Filtro de días de atraso.
#' @param pausa_entre_llamadas numeric. Segundos entre llamadas.
#' @param verbose       lógico. Si TRUE muestra progreso.
#' @param offset_contador integer. Offset para mostrar el contador global correctamente.
#' @param total_global  integer. Total global de llamadas (para el contador).
#' @return tibble combinado del bloque.
.recopilar_bloque_cartera <- function(tipo_reporte, entidades_df, periodos_bloque,
                                       normativa, dias_atraso = "",
                                       pausa_entre_llamadas = 0.5, verbose = TRUE,
                                       offset_contador = 0L, total_global = NULL) {
  if (length(periodos_bloque) == 0) return(tibble::tibble())
  total_bloque <- nrow(entidades_df) * length(periodos_bloque)
  total_mostrar <- if (!is.null(total_global)) total_global else total_bloque
  resultados <- vector("list", total_bloque)
  contador   <- 0L

  for (i in seq_len(nrow(entidades_df))) {
    ent <- entidades_df[i, ]
    for (per in periodos_bloque) {
      contador <- contador + 1L
      if (verbose) {
        message(sprintf(
          "  [%d/%d] %-50s | %s",
          offset_contador + contador, total_mostrar, ent$NOM_ENT, per
        ))
      }
      df <- .reporte_cartera_unitario(
        tipo_reporte = tipo_reporte,
        cod_entidad  = ent$COD_ENT,
        cod_sector   = ent$COD_SEC,
        periodo      = per,
        normativa    = normativa,
        dias_atraso  = dias_atraso
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
      if (pausa_entre_llamadas > 0 && (offset_contador + contador) < total_mostrar) {
        Sys.sleep(pausa_entre_llamadas)
      }
    }
  }

  validos <- Filter(function(x) !is.null(x) && nrow(x) > 0, resultados)
  if (length(validos) == 0) return(tibble::tibble())
  dplyr::bind_rows(validos)
}

#' Obtiene reportes de cartera para múltiples entidades y períodos,
#' manejando el corte normativo de enero 2024
#'
#' Si el rango de fechas no cruza enero 2024, procesa todo en un único bloque.
#' Si el rango cruza el corte, procesa ambos bloques por separado (pre y post) e
#' intenta unirlos en un único tibble. El comportamiento ante diferencias de columnas
#' está controlado por el argumento \code{intentar_union}.
#'
#' @param tipo_reporte         character. Clave interna del reporte de cartera.
#' @param entidades_df         tibble. Salida de .resolver_entidades().
#' @param periodos             character. Vector de períodos en formato YYYYMMDD.
#' @param normativa_pre        character. Normativa para períodos pre-2024. Default "1".
#' @param normativa_post       character. Normativa para períodos post-2023. Default "1".
#' @param dias_atraso          character. Filtro de días de atraso.
#' @param intentar_union       lógico. Si TRUE, intenta unir bloques pre/post 2024.
#'   Si FALSE, retorna siempre una lista con $pre_2024 y $post_2024.
#' @param pausa_entre_llamadas numeric. Segundos entre llamadas sucesivas.
#' @param verbose              lógico. Si TRUE, muestra progreso detallado.
#' @return
#'   Un tibble combinado, o una lista con $pre_2024 y $post_2024 si no fue posible unir.
.obtener_reportes_cartera <- function(tipo_reporte, entidades_df, periodos,
                                       normativa_pre = "1", normativa_post = "1",
                                       dias_atraso = "", intentar_union = TRUE,
                                       pausa_entre_llamadas = 0.5, verbose = TRUE) {
  conf           <- .CONF_REPORTES_CARTERA[[tipo_reporte]]
  total_llamadas <- nrow(entidades_df) * length(periodos)
  corte          <- .detectar_corte_cartera(periodos)

  if (verbose) {
    message(sprintf(
      "\nReporte: %s\nEntidades: %d | Períodos: %d | Total de llamadas: %d",
      conf$nombre, nrow(entidades_df), length(periodos), total_llamadas
    ))
    if (corte$hay_corte) {
      message(sprintf(
        paste0("  Advertencia: el rango cruza el corte normativo de enero 2024.\n",
               "  Pre-2024  (%d períodos): %s\n",
               "  Post-2023 (%d períodos): %s"),
        length(corte$pre_2024),  paste(corte$pre_2024,  collapse = ", "),
        length(corte$post_2024), paste(corte$post_2024, collapse = ", ")
      ))
    }
  }

  # --- Sin corte: procesar en un único bloque ---
  if (!corte$hay_corte) {
    es_pre <- length(corte$pre_2024) > 0
    return(.recopilar_bloque_cartera(
      tipo_reporte         = tipo_reporte,
      entidades_df         = entidades_df,
      periodos_bloque      = if (es_pre) corte$pre_2024 else corte$post_2024,
      normativa            = if (es_pre) normativa_pre  else normativa_post,
      dias_atraso          = dias_atraso,
      pausa_entre_llamadas = pausa_entre_llamadas,
      verbose              = verbose,
      offset_contador      = 0L,
      total_global         = total_llamadas
    ))
  }

  # --- Con corte: procesar cada bloque por separado ---
  n_pre  <- nrow(entidades_df) * length(corte$pre_2024)
  n_post <- nrow(entidades_df) * length(corte$post_2024)

  if (verbose) message(sprintf("\n--- BLOQUE PRE-2024 (normativa: SUGEF 1-05) [%d llamadas] ---", n_pre))
  df_pre <- .recopilar_bloque_cartera(
    tipo_reporte         = tipo_reporte,
    entidades_df         = entidades_df,
    periodos_bloque      = corte$pre_2024,
    normativa            = normativa_pre,
    dias_atraso          = dias_atraso,
    pausa_entre_llamadas = pausa_entre_llamadas,
    verbose              = verbose,
    offset_contador      = 0L,
    total_global         = total_llamadas
  )

  if (verbose) message(sprintf("\n--- BLOQUE POST-2023 (normativa: CONASSIF 14-21) [%d llamadas] ---", n_post))
  df_post <- .recopilar_bloque_cartera(
    tipo_reporte         = tipo_reporte,
    entidades_df         = entidades_df,
    periodos_bloque      = corte$post_2024,
    normativa            = normativa_post,
    dias_atraso          = dias_atraso,
    pausa_entre_llamadas = pausa_entre_llamadas,
    verbose              = verbose,
    offset_contador      = n_pre,
    total_global         = total_llamadas
  )

  # --- Si el usuario no quiere unión ---
  if (!intentar_union) {
    if (verbose) message("\nintentар_union = FALSE. Retornando lista con $pre_2024 y $post_2024.")
    return(list(pre_2024 = df_pre, post_2024 = df_post))
  }

  # --- Intentar unión ---
  if (verbose) message("\nIntentando unir bloques pre/post 2024...")
  resultado <- .intentar_union_cartera(df_pre, df_post)

  if (is.list(resultado) && !is.data.frame(resultado) && isTRUE(resultado$no_unificado)) {
    if (verbose) {
      message("Union no posible por incompatibilidad de tipos. Se retorna lista con $pre_2024 y $post_2024.")
    }
  } else if (!is.null(attr(resultado, "advertencia_union"))) {
    if (verbose) {
      message(sprintf(
        "Union completada con %d filas. Hay diferencias de columnas (ver advertencias).",
        nrow(resultado)
      ))
    }
  } else if (verbose) {
    message(sprintf("Union exitosa: %d filas en total.", nrow(resultado)))
  }

  resultado
}
