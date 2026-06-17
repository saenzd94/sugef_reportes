# ==============================================================================
# 02_catalogo.R
# Catálogos de referencia de la API de SUGEF con caché en memoria.
# ==============================================================================

# Entorno privado de caché — se inicializa al cargar el paquete
.sugef_cache <- new.env(parent = emptyenv())

# ------------------------------------------------------------------------------
# Catálogo de entidades
# ------------------------------------------------------------------------------

#' Lista las entidades supervisadas por SUGEF
#'
#' Consulta el endpoint GET de catálogo y retorna las ~49 entidades supervisadas.
#' Usa caché en memoria para evitar llamadas repetidas durante la misma sesión.
#'
#' Columnas del resultado:
#' - **COD_ENT**: Cédula jurídica (ID usado como `codigoEntidad` en la API).
#' - **ABR_ENT**: Nombre abreviado.
#' - **NOM_ENT**: Nombre completo.
#' - **DES_SEC**: Descripción del sector supervisor.
#' - **COD_SEC**: Código de sector (usado como `codigoTipoEntidad` en reportes de cartera).
#'
#' @param usar_cache lógico. Si `TRUE` (default), usa datos en memoria si existen.
#' @param verbose   lógico. Si `TRUE`, muestra mensajes informativos.
#' @return tibble con 5 columnas y una fila por entidad supervisada.
#' @export
#'
#' @examples
#' \dontrun{
#' entidades <- listar_entidades()
#' }
listar_entidades <- function(usar_cache = TRUE, verbose = FALSE) {
  if (usar_cache && exists("entidades", envir = .sugef_cache)) {
    if (verbose) message("  [cache] Lista de entidades recuperada desde memoria.")
    return(get("entidades", envir = .sugef_cache))
  }
  if (verbose) message("Consultando lista de entidades desde la API de SUGEF...")
  resp <- .sugef_get("/Catalogo/MAPI/ListarEntidades")
  if (is.null(resp)) stop("No se pudo obtener la lista de entidades de SUGEF.")

  df <- .parsear_xml_get(resp) |>
    stats::setNames(c("COD_ENT", "ABR_ENT", "NOM_ENT", "DES_SEC", "COD_SEC")) |>
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
#' Retorna el catálogo completo (~11,849 filas). Se recomienda filtrar
#' por `nombreTipoCatalogo` (ej: cuentas vigentes desde 2008) y
#' por `cuentaPadre != 0` para obtener solo cuentas hoja.
#'
#' @param usar_cache lógico. Si `TRUE` (default), usa datos en memoria si existen.
#' @param verbose   lógico. Si `TRUE`, muestra mensajes informativos.
#' @return tibble con el catálogo completo de cuentas contables.
#' @export
#'
#' @examples
#' \dontrun{
#' catalogo <- listar_catalogo_contable()
#' catalogo_2008 <- catalogo |>
#'   dplyr::filter(grepl("2008", nombreTipoCatalogo), cuentaPadre != 0)
#' }
listar_catalogo_contable <- function(usar_cache = TRUE, verbose = FALSE) {
  if (usar_cache && exists("catalogo", envir = .sugef_cache)) {
    if (verbose) message("  [cache] Catalogo contable recuperado desde memoria.")
    return(get("catalogo", envir = .sugef_cache))
  }
  if (verbose) message("Consultando catalogo contable desde la API de SUGEF...")
  resp <- .sugef_get("/Catalogo/MAPI/ListarCatalogoCuentasContables")
  if (is.null(resp)) stop("No se pudo obtener el catalogo contable de SUGEF.")

  df <- .parsear_xml_get(resp)
  assign("catalogo", df, envir = .sugef_cache)
  if (verbose) message(sprintf("  %d cuentas en el catalogo.", nrow(df)))
  df
}

# ------------------------------------------------------------------------------
# Utilidades de catálogo
# ------------------------------------------------------------------------------

#' Lista los sectores supervisados disponibles
#'
#' @param verbose lógico. Si `TRUE`, muestra mensajes informativos.
#' @return tibble con columnas `COD_SEC` y `DES_SEC`, una fila por sector único.
#' @export
listar_sectores <- function(verbose = FALSE) {
  listar_entidades(verbose = verbose) |>
    dplyr::select(COD_SEC, DES_SEC) |>
    dplyr::distinct() |>
    dplyr::arrange(COD_SEC)
}

#' Limpia el caché de catálogos en memoria
#'
#' Fuerza una nueva consulta a la API en la próxima llamada a `listar_entidades()`
#' o `listar_catalogo_contable()`.
#'
#' @return invisible `TRUE`
#' @export
limpiar_cache_sugef <- function() {
  rm(list = ls(envir = .sugef_cache), envir = .sugef_cache)
  message("Cache de catalogos SUGEF limpiado.")
  invisible(TRUE)
}
