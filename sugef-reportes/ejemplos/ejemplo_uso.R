# ==============================================================================
# ejemplos/ejemplo_uso.R
# Ejemplos completos de uso de obtener_reporte_sugef()
#
# Ejecutar desde la raíz del proyecto o con here::here():
#   source(here::here("cargar_sugef.R"))
#   source(here::here("ejemplos", "ejemplo_uso.R"))
# ==============================================================================

source(here::here("cargar_sugef.R"))

# ==============================================================================
# 0. EXPLORACIÓN DEL CATÁLOGO
# ==============================================================================

# Ver todos los tipos de reporte disponibles y sus aliases
listar_reportes_disponibles()

# Ver entidades supervisadas
entidades <- listar_entidades(verbose = TRUE)
View(entidades)

# Ver sectores disponibles
listar_sectores()

# Ver catálogo contable (filtrado al más común: vigente desde 2008)
catalogo <- listar_catalogo_contable(verbose = TRUE)
catalogo_2008 <- catalogo %>%
  dplyr::filter(grepl("2008", nombreTipoCatalogo), cuentaPadre != 0)

# ==============================================================================
# 1. REPORTES FINANCIEROS — POR ENTIDAD
# ==============================================================================

# --- Balance de situación: una entidad, un mes ---
# Busca por abreviatura (parcial, sin distinción de mayúsculas)
bs_bcr_jun24 <- obtener_reporte_sugef(
  entidad = "BCR",
  reporte = "balance",
  from    = "2024-06-01"
)
glimpse(bs_bcr_jun24)

# --- Balance de situación: un mes, buscando por cédula jurídica (COD_ENT) ---
bs_bcr_jun24_v2 <- obtener_reporte_sugef(
  entidad = "4000000019",
  reporte = "bs",               # alias corto
  from    = "20240601"          # también acepta formato YYYYMMDD
)

# --- Estado de resultados: una entidad, rango de 12 meses ---
er_bcr_2024 <- obtener_reporte_sugef(
  entidad = "BCR",
  reporte = "resultados",
  from    = "2024-01-01",
  to      = "2024-12-01"
)
glimpse(er_bcr_2024)

# --- Indicadores financieros: una entidad, un trimestre ---
ind_bcr <- obtener_reporte_sugef(
  entidad = "BCR",
  reporte = "indicadores",
  from    = "2024-04-01",
  to      = "2024-06-01"
)

# --- Filtrar por cuenta contable específica ---
bs_cuenta <- obtener_reporte_sugef(
  entidad       = "BCR",
  reporte       = "balance",
  from          = "2024-06-01",
  codigo_cuenta = "1"           # Activos totales (ejemplo; verifique en catálogo)
)

# ==============================================================================
# 2. REPORTES FINANCIEROS — POR SECTOR
# ==============================================================================

# --- Balance de situación: todos los bancos estatales ---
bs_estatales <- obtener_reporte_sugef(
  sector  = "BANCOS COMERCIALES DEL ESTADO",
  reporte = "balance",
  from    = "2024-06-01"
)
# Resumen por entidad
bs_estatales %>%
  dplyr::group_by(NOM_ENT) %>%
  dplyr::summarise(n_cuentas = dplyr::n())

# --- Estado de resultados: bancos privados, primer semestre 2024 ---
er_privados <- obtener_reporte_sugef(
  sector  = "BANCOS PRIVADOS",   # coincidencia parcial: incluye "BANCOS PRIVADOS Y COOPERATIVOS"
  reporte = "er",
  from    = "2024-01-01",
  to      = "2024-06-01"
)

# --- Indicadores: OCACS (Organizaciones Cooperativas de Ahorro y Crédito) ---
ind_ocacs <- obtener_reporte_sugef(
  sector  = "COOPERATIVAS",      # coincidencia parcial
  reporte = "indicadores",
  from    = "2024-06-01"
)

# ==============================================================================
# 3. REPORTES DE CARTERA — SIN CRUCE DEL CORTE (todo en un mismo bloque)
# ==============================================================================

# --- Cartera por actividad económica: post-2024, una entidad ---
cartera_act_bcr <- obtener_reporte_sugef(
  entidad = "BCR",
  reporte = "cartera_actividad",
  from    = "2024-01-01",
  to      = "2024-06-01"
)

# --- Cartera por actividad económica: pre-2024, un sector ---
cartera_act_2023 <- obtener_reporte_sugef(
  sector  = "BANCOS COMERCIALES DEL ESTADO",
  reporte = "cartera_actividad",
  from    = "2023-01-01",
  to      = "2023-12-01"
)

# --- Cartera por actividad económica y categoría de riesgo ---
cartera_act_riesgo <- obtener_reporte_sugef(
  entidad = "BCR",
  reporte = "cartera_actividad_riesgo",
  from    = "2024-06-01"
)

# --- Cartera por actividad económica y días de atraso (todos los tramos) ---
cartera_act_atraso_todos <- obtener_reporte_sugef(
  entidad     = "BCR",
  reporte     = "cartera_actividad_atraso",
  from        = "2024-06-01",
  dias_atraso = ""   # "" = todos los tramos de atraso
)

# --- Cartera por actividad económica y días de atraso (solo cobro judicial) ---
cartera_cob_jud <- obtener_reporte_sugef(
  entidad     = "BCR",
  reporte     = "act_econ_atraso",   # alias
  from        = "2024-06-01",
  dias_atraso = "7"   # 7 = cobro judicial
)

# --- Cartera por categoría de riesgo y días de atraso ---
cartera_riesgo_atraso <- obtener_reporte_sugef(
  entidad = "BCR",
  reporte = "cartera_riesgo_atraso",
  from    = "2024-01-01",
  to      = "2024-06-01"
)

# ==============================================================================
# 4. REPORTES DE CARTERA — CRUZANDO EL CORTE NORMATIVO (ENERO 2024)
# ==============================================================================

# El rango 2023-10 a 2024-03 cruza enero 2024.
# La función detecta el corte, procesa cada bloque con su normativa correspondiente
# e intenta unir los resultados.

# --- Con intento de unión (comportamiento por defecto) ---
cartera_cruce_union <- obtener_reporte_sugef(
  entidad        = "BCR",
  reporte        = "cartera_actividad",
  from           = "2023-10-01",
  to             = "2024-03-01",
  intentar_union = TRUE   # default: intenta bind_rows(), avisa si difieren columnas
)

# Si la unión fue exitosa, cartera_cruce_union es un tibble
# Si las columnas difieren, tiene atributo "advertencia_union" = TRUE
if (is.data.frame(cartera_cruce_union)) {
  message("Union exitosa: ", nrow(cartera_cruce_union), " filas.")
  if (!is.null(attr(cartera_cruce_union, "advertencia_union"))) {
    message("Hay diferencias de columnas. Columnas solo en pre-2024: ",
            paste(attr(cartera_cruce_union, "cols_solo_pre_2024"), collapse = ", "))
    message("Columnas solo en post-2024: ",
            paste(attr(cartera_cruce_union, "cols_solo_post_2024"), collapse = ", "))
  }
}

# --- Sin intento de unión: recibe siempre la lista separada ---
cartera_cruce_sep <- obtener_reporte_sugef(
  entidad        = "BCR",
  reporte        = "cartera_actividad",
  from           = "2023-10-01",
  to             = "2024-03-01",
  intentar_union = FALSE
)
# cartera_cruce_sep$pre_2024  → tibble con datos bajo SUGEF 1-05
# cartera_cruce_sep$post_2024 → tibble con datos bajo CONASSIF 14-21
glimpse(cartera_cruce_sep$pre_2024)
glimpse(cartera_cruce_sep$post_2024)

# Unión manual con diagnóstico posterior (si el usuario desea más control)
cols_comunes <- intersect(
  names(cartera_cruce_sep$pre_2024),
  names(cartera_cruce_sep$post_2024)
)
cartera_manual <- dplyr::bind_rows(
  cartera_cruce_sep$pre_2024  %>% dplyr::select(dplyr::all_of(cols_comunes)),
  cartera_cruce_sep$post_2024 %>% dplyr::select(dplyr::all_of(cols_comunes))
)

# --- Cruce con rango más amplio: un año completo que incluye el corte ---
cartera_2023_2024 <- obtener_reporte_sugef(
  sector         = "BANCOS COMERCIALES DEL ESTADO",
  reporte        = "cartera_actividad",
  from           = "2023-01-01",
  to             = "2024-12-01",
  intentar_union = TRUE
)

# ==============================================================================
# 5. MÚLTIPLES ENTIDADES POR NOMBRE
# ==============================================================================

# Puede pasar un vector de nombres o códigos mezclados
multi_bancos_estat <- obtener_reporte_sugef(
  entidad = c("BCR", "BNCR", "BPDC"),   # abreviaturas parciales
  reporte = "balance",
  from    = "2024-06-01"
)
# Verificar cuántos registros por entidad
multi_bancos_estat %>% dplyr::count(NOM_ENT)

# ==============================================================================
# 6. AJUSTES DE VELOCIDAD Y VERBOSIDAD
# ==============================================================================

# Para consultas largas (muchas entidades × meses), ajuste la pausa y verbosidad
er_sector_silencioso <- obtener_reporte_sugef(
  sector               = "BANCOS PRIVADOS",
  reporte              = "resultados",
  from                 = "2024-01-01",
  to                   = "2024-06-01",
  pausa_entre_llamadas = 1.0,    # más pausa entre llamadas (recomendado para sectores grandes)
  verbose              = FALSE   # sin mensajes de progreso
)

# ==============================================================================
# 7. ANÁLISIS BÁSICO DE UN RESULTADO
# ==============================================================================

# Ejemplo: evolución del balance para BCR en 2024
bs_bcr_2024 <- obtener_reporte_sugef(
  entidad = "BCR",
  reporte = "balance",
  from    = "2024-01-01",
  to      = "2024-12-01"
)

# Las columnas del reporte varían según el tipo; explorar primero
glimpse(bs_bcr_2024)
head(bs_bcr_2024)

# Convertir PERIODO a Date para graficar
bs_bcr_2024 <- bs_bcr_2024 %>%
  dplyr::mutate(FECHA = as.Date(PERIODO, format = "%Y%m%d"))
