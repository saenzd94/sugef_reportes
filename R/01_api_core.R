# ==============================================================================
# 01_api_core.R
# Capa de transporte de bajo nivel para la API REST de SUGEF.
# Contiene los wrappers de GET/POST y los parsers de respuesta.
#
# API Reference:
#   https://www.sugef.fi.cr/Bccr.Sugef.Reportes_SitioWeb.API/index.html
#
# Notas sobre el formato de respuesta:
#   - Endpoints GET (catálogos): devuelven JSON embebido dentro de XML/HTML.
#     Requieren parseo en dos pasos: XML -> nodo interno -> fromJSON().
#   - Endpoints POST (reportes): devuelven JSON directamente en el cuerpo.
#     Parseo directo con jsonlite::fromJSON().
# ==============================================================================

library(httr)
library(XML)
library(jsonlite)
library(tibble)

#' URL base de la API REST de SUGEF
SUGEF_API_BASE <- "https://www.sugef.fi.cr/Bccr.Sugef.Reportes_SitioWeb.API"

# ------------------------------------------------------------------------------
# Funciones de transporte
# ------------------------------------------------------------------------------

#' Realiza una solicitud GET a la API de SUGEF con reintentos
#'
#' @param link   character. Ruta del endpoint, sin URL base (ej: "/Catalogo/MAPI/ListarEntidades").
#' @param max_reintentos integer. Número máximo de reintentos ante fallo de red o HTTP != 200.
#' @param pausa  numeric. Segundos de espera entre reintentos.
#' @return Objeto de respuesta httr, o NULL si todos los reintentos fallan.
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

#' Realiza una solicitud POST a la API de SUGEF con reintentos
#'
#' @param link      character. Ruta del endpoint, sin URL base.
#' @param body_list list. Lista R que se serializa a JSON para el cuerpo de la solicitud.
#' @param max_reintentos integer. Número máximo de reintentos.
#' @param pausa  numeric. Segundos de espera entre reintentos.
#' @return Objeto de respuesta httr, o NULL si todos los reintentos fallan.
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
#' Los endpoints de catálogo devuelven un JSON embebido dentro de una estructura
#' XML/HTML. La jerarquía es: raíz XML -> (2 niveles de hijos) -> nodo con JSON string.
#'
#' @param resp Objeto de respuesta httr (status 200).
#' @return tibble con los datos, o tibble vacío si el parseo falla.
.parsear_xml_get <- function(resp) {
  texto <- httr::content(resp, as = "text", encoding = "UTF-8")
  tryCatch({
    salidaxml  <- XML::xmlParse(texto, asText = TRUE, useInternalNodes = FALSE, isHTML = TRUE, encoding = "UTF-8")
    nodo_raiz  <- XML::xmlRoot(salidaxml)
    hijos      <- XML::xmlChildren(nodo_raiz)
    # La estructura XML envuelve el JSON en 2 niveles de anidamiento
    for (i in 1:2) hijos <- XML::xmlChildren(hijos[[1]])
    json_str   <- XML::xmlValue(hijos[[1]])
    resultado  <- jsonlite::fromJSON(json_str)
    resultado[[1]] %>% tibble::as_tibble()
  }, error = function(e) {
    warning("Error al parsear respuesta XML/GET: ", conditionMessage(e))
    tibble::tibble()
  })
}

#' Parsea la respuesta JSON de los endpoints POST de reportes
#'
#' @param resp Objeto de respuesta httr (status 200).
#' @return tibble con los datos, o tibble vacío si el parseo falla o la respuesta está vacía.
.parsear_json_post <- function(resp) {
  texto <- httr::content(resp, as = "text", encoding = "UTF-8")
  tryCatch({
    resultado <- jsonlite::fromJSON(texto)
    if (length(resultado) == 0 || is.null(resultado[[1]])) return(tibble::tibble())
    resultado[[1]] %>% tibble::as_tibble()
  }, error = function(e) {
    warning("Error al parsear respuesta JSON/POST: ", conditionMessage(e))
    tibble::tibble()
  })
}
