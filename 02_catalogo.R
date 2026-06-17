# ==============================================================================
# 01_api_core.R
# Capa de transporte de bajo nivel para la API REST de SUGEF.
#
# API Reference:
#   https://www.sugef.fi.cr/Bccr.Sugef.Reportes_SitioWeb.API/index.html
#
# Notas sobre el formato de respuesta:
#   GET (catálogos): JSON embebido en XML/HTML → parseo en dos pasos.
#   POST (reportes): JSON directo en el cuerpo → jsonlite::fromJSON().
# ==============================================================================

#' URL base de la API REST de SUGEF
SUGEF_API_BASE <- "https://www.sugef.fi.cr/Bccr.Sugef.Reportes_SitioWeb.API"

# ------------------------------------------------------------------------------
# Funciones de transporte
# ------------------------------------------------------------------------------

#' Realiza una solicitud GET a la API de SUGEF con reintentos automáticos
#'
#' @param link character. Ruta del endpoint sin URL base.
#' @param max_reintentos integer. Reintentos máximos ante fallo.
#' @param pausa numeric. Segundos de espera entre reintentos.
#' @return Objeto de respuesta httr o NULL si todos los reintentos fallan.
#' @keywords internal
.sugef_get <- function(link, max_reintentos = 3, pausa = 1) {
  url  <- paste0(SUGEF_API_BASE, link)
  resp <- NULL
  for (i in seq_len(max_reintentos)) {
    resp <- tryCatch(
      httr::GET(url),
      error = function(e) {
        message(sprintf("  [GET intento %d/%d] Error de red: %s", i, max_reintentos, conditionMessage(e)))
        NULL
      }
    )
    if (!is.null(resp) && httr::status_code(resp) == 200L) break
    if (i < max_reintentos) Sys.sleep(pausa)
  }
  if (is.null(resp) || httr::status_code(resp) != 200L) {
    codigo <- if (!is.null(resp)) httr::status_code(resp) else "sin respuesta"
    warning(sprintf("GET fallido para '%s' (estado: %s).", url, codigo))
    return(NULL)
  }
  resp
}

#' Realiza una solicitud POST a la API de SUGEF con reintentos automáticos
#'
#' @param link character. Ruta del endpoint sin URL base.
#' @param body_list list. Se serializa a JSON como cuerpo de la solicitud.
#' @param max_reintentos integer. Reintentos máximos ante fallo.
#' @param pausa numeric. Segundos de espera entre reintentos.
#' @return Objeto de respuesta httr o NULL si todos los reintentos fallan.
#' @keywords internal
.sugef_post <- function(link, body_list, max_reintentos = 3, pausa = 1) {
  url       <- paste0(SUGEF_API_BASE, link)
  body_json <- jsonlite::toJSON(body_list, auto_unbox = TRUE)
  resp      <- NULL
  for (i in seq_len(max_reintentos)) {
    resp <- tryCatch(
      httr::POST(
        url    = url,
        body   = body_json,
        encode = "raw",
        httr::add_headers(
          "accept"       = "application/json",
          "Content-Type" = "application/json; charset=utf-8"
        )
      ),
      error = function(e) {
        message(sprintf("  [POST intento %d/%d] Error de red: %s", i, max_reintentos, conditionMessage(e)))
        NULL
      }
    )
    if (!is.null(resp) && httr::status_code(resp) == 200L) break
    if (i < max_reintentos) Sys.sleep(pausa)
  }
  if (is.null(resp) || httr::status_code(resp) != 200L) {
    codigo <- if (!is.null(resp)) httr::status_code(resp) else "sin respuesta"
    warning(sprintf("POST fallido para '%s' (estado: %s).", url, codigo))
    return(NULL)
  }
  resp
}

# ------------------------------------------------------------------------------
# Parsers de respuesta
# ------------------------------------------------------------------------------

#' Parsea la respuesta XML de los endpoints GET del catálogo
#'
#' Los endpoints de catálogo devuelven JSON embebido en XML/HTML.
#' Jerarquía: raíz XML → 2 niveles de hijos → nodo con JSON string.
#'
#' @param resp Objeto de respuesta httr (status 200).
#' @return tibble con los datos, o tibble vacío si el parseo falla.
#' @keywords internal
.parsear_xml_get <- function(resp) {
  texto <- httr::content(resp, as = "text", encoding = "UTF-8")
  tryCatch({
    salidaxml <- XML::xmlParse(texto, asText = TRUE, useInternalNodes = FALSE, isHTML = TRUE)
    hijos     <- XML::xmlChildren(XML::xmlRoot(salidaxml))
    for (i in 1:2) hijos <- XML::xmlChildren(hijos[[1]])
    json_str  <- XML::xmlValue(hijos[[1]])
    jsonlite::fromJSON(json_str)[[1]] |> tibble::as_tibble()
  }, error = function(e) {
    warning("Error al parsear respuesta XML/GET: ", conditionMessage(e))
    tibble::tibble()
  })
}

#' Parsea la respuesta JSON de los endpoints POST de reportes
#'
#' @param resp Objeto de respuesta httr (status 200).
#' @return tibble con los datos, o tibble vacío si falla o la respuesta está vacía.
#' @keywords internal
.parsear_json_post <- function(resp) {
  texto <- httr::content(resp, as = "text", encoding = "UTF-8")
  tryCatch({
    resultado <- jsonlite::fromJSON(texto)
    if (length(resultado) == 0 || is.null(resultado[[1]])) return(tibble::tibble())
    resultado[[1]] |> tibble::as_tibble()
  }, error = function(e) {
    warning("Error al parsear respuesta JSON/POST: ", conditionMessage(e))
    tibble::tibble()
  })
}
