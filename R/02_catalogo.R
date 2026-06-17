# ==============================================================================
# 02_catalogo.R
# Funciones para obtener los catálogos de referencia de la API de SUGEF:
#   - Lista de entidades supervisadas (49 entidades, 5 columnas)
#   - Catálogo de cuentas contables (11,849 filas, 7 columnas)
#
# Implementa caché en memoria para evitar llamadas repetidas a la API durante
# una misma sesión de R. El caché se limpia con limpiar_cache_sugef().
# ==============================================================================

library(dplyr)
library(tibble)

# Entorno privado para caché (persiste en la sesión de R)
.sugef_cache <- new.env(parent = emptyenv())

# ------------------------------------------------------------------------------
# Catálogo de entidades
# ------------------------------------------------------------------------------

#' Lista las entidades supervisadas por SUGEF
#'
#' Consulta el endpoint GET de catálogo de entidades y retorna un tibble con
#' las 49 entidades supervisadas y sus metadatos. Usa caché en memoria para
#' evitar llamadas repetidas a la API.
#'
#' Columnas del resultado:
#' \itemize{
#'   \item \strong{COD_ENT}: Cédula jurídica de la entidad (usada como ID en la API).
#'   \item \strong{ABR_ENT}: Nombre abreviado de la entidad.
#'   \item \strong{NOM_ENT}: Nombre completo de la entidad.
#'   \item \strong{DES_SEC}: Descripción del sector al que pertenece.
#'   \item \strong{COD_SEC}: Código del sector (usado en reportes de cartera).
#' }
#'
#' @param usar_cache lógico. Si TRUE (default), retorna datos del caché si existen.
#' @param verbose   lógico. Si TRUE, muestra mensajes informativos.
#' @return tibble con 5 columnas y una fila por entidad.
#' @export
#'
#' @examples
#' \dontrun{
#' entidades <- listar_entidades()
#' View(entidades)
#' }
listar_entidades <- function(usar_cache = TRUE, verbose = FALSE) {
  if (usar_cache && exists("entidades", envir = .sugef_cache)) {
    if (verbose) message("  [caché] Lista de entidades recuperada desde memoria.")
    return(get("entidades", envir = .sugef_cache))
  }
  if (verbose) message("Consultando lista de entidades desde la API de SUGEF...")
  resp <- .sugef_get("/Catalogo/MAPI/ListarEntidades")
  if (is.null(resp)) stop("No se pudo obtener la lista de entidades de SUGEF.")

  df <- .parsear_xml_get(resp) %>%
    setNames(c("COD_ENT", "ABR_ENT", "NOM_ENT", "DES_SEC", "COD_SEC")) %>%
    dplyr::mutate(dplyr::across(dplyr::everything(), as.character))

  assign("entidades", df, envir = .sugef_cache)
  if (verbose) message(sprintf("  %d entidades obtenidas.", nrow(df)))
  df
}

# ------------------------------------------------------------------------------
# Catálogo contable
# ------------------------------------------------------------------------------

#' Lista el catálogo de cuentas contables de SUGEF
#'
#' Consulta el endpoint GET de catálogo contable. El catálogo completo incluye
#' ~11,849 filas. Se recomienda filtrar por \code{nombreTipoCatalogo} (ej: cuentas
#' "a partir de 2008") y por \code{cuentaPadre != 0} para obtener solo cuentas hoja.
#'
#' @param usar_cache lógico. Si TRUE (default), retorna datos del caché si existen.
#' @param verbose   lógico. Si TRUE, muestra mensajes informativos.
#' @return tibble con el catálogo completo de cuentas contables.
#' @export
#'
#' @examples
#' \dontrun{
#' catalogo <- listar_catalogo_contable()
#' # Filtrar solo cuentas del catálogo 2008 que no sean raíz:
#' catalogo_filtrado <- catalogo %>%
#'   filter(grepl("2008", nombreTipoCatalogo), cuentaPadre != 0)
#' }
listar_catalogo_contable <- function(usar_cache = TRUE, verbose = FALSE) {
  if (usar_cache && exists("catalogo", envir = .sugef_cache)) {
    if (verbose) message("  [caché] Catálogo contable recuperado desde memoria.")
    return(get("catalogo", envir = .sugef_cache))
  }
  if (verbose) message("Consultando catálogo contable desde la API de SUGEF...")
  resp <- .sugef_get("/Catalogo/MAPI/ListarCatalogoCuentasContables")
  if (is.null(resp)) stop("No se pudo obtener el catálogo contable de SUGEF.")

  df <- .parsear_xml_get(resp)
  assign("catalogo", df, envir = .sugef_cache)
  if (verbose) message(sprintf("  %d cuentas en el catálogo.", nrow(df)))
  df
}

# ------------------------------------------------------------------------------
# Utilidades de catálogo
# ------------------------------------------------------------------------------

#' Lista los sectores disponibles según la lista de entidades
#'
#' @param verbose lógico. Si TRUE, muestra mensajes informativos.
#' @return tibble con columnas COD_SEC y DES_SEC, una fila por sector único.
#' @export
listar_sectores <- function(verbose = FALSE) {
  listar_entidades(verbose = verbose) %>%
    dplyr::select(COD_SEC, DES_SEC) %>%
    dplyr::distinct() %>%
    dplyr::arrange(COD_SEC)
}

#' Limpia el caché de catálogos en memoria
#'
#' Útil cuando se desea forzar una nueva consulta a la API, por ejemplo
#' si se sospecha que la lista de entidades ha cambiado.
#'
#' @return invisible TRUE
#' @export
limpiar_cache_sugef <- function() {
  rm(list = ls(envir = .sugef_cache), envir = .sugef_cache)
  message("Caché de catálogos SUGEF limpiado.")
  invisible(TRUE)
}
