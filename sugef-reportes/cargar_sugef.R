# ==============================================================================
# cargar_sugef.R
# Script de carga: fuente todos los módulos del proyecto sugef-reportes en el
# orden correcto de dependencias.
#
# Uso desde cualquier script del proyecto:
#   source(here::here("cargar_sugef.R"))
#
# O desde la raíz del proyecto:
#   source("cargar_sugef.R")
# ==============================================================================

# Dependencias de paquetes CRAN
paquetes_requeridos <- c(
  "dplyr",      # Manipulación de datos
  "tibble",     # Tibbles
  "httr",       # Solicitudes HTTP GET/POST
  "XML",        # Parseo de respuestas XML (catálogos GET)
  "jsonlite",   # Parseo de JSON (respuestas POST)
  "here"        # Rutas relativas al proyecto
)

paquetes_faltantes <- paquetes_requeridos[
  !sapply(paquetes_requeridos, requireNamespace, quietly = TRUE)
]
if (length(paquetes_faltantes) > 0) {
  message("Instalando paquetes faltantes: ", paste(paquetes_faltantes, collapse = ", "))
  install.packages(paquetes_faltantes, repos = "https://cloud.r-project.org")
}

# Cargar paquetes
invisible(lapply(paquetes_requeridos, library, character.only = TRUE, quietly = TRUE))

# Cargar módulos del proyecto en orden de dependencias
archivos_R <- sort(list.files(
  path = here::here("R"),
  pattern = "\\.R$",
  full.names = TRUE
))

invisible(lapply(archivos_R, source, local = FALSE))

message(sprintf(
  "[sugef-reportes] %d módulos cargados correctamente. Función principal: obtener_reporte_sugef()",
  length(archivos_R)
))
message("  Use listar_reportes_disponibles() para ver los tipos de reporte.")
message("  Use listar_entidades() y listar_sectores() para explorar el catálogo.")
