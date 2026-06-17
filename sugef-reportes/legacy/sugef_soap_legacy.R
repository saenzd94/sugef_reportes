
sugef <- function(opcion, resultado = NULL, argumentos = NULL){
  
  library(RCurl)
  library(xml2)
  library(XML)
  # url_SUGEF <- ("https://www.sugef.fi.cr/wsReportes/ReportesWeb.asmx") # anterior
  url_SUGEF <- ("https://www.sugef.fi.cr/wsReportes/reportesWeb.asmx") # nuevo
  
  header =
    c(Accept = "text/xml",
      Accept = "multipart/*",
      # 'Content-Type' = "text/xml; charset=utf-8", # anterior
      'Content-Type' = "application/soap+xml; charset=utf-8", # nuevo
      SOAPAction = paste0("http://tempuri.org/",opcion))
  
  body <- opRef_sugef(opcion = opcion)
  
  if(is.null(argumentos) & !opcion %in% c('ListarEntidades', 'ListarCatalogoContable')){
    output <- body %>% strsplit(., "\n") %>% 
      lapply(., function(x) x[grepl('string', x)]) %>% unlist() %>% as.character() %>% 
      strsplit(., 'string') %>% purrr::map_chr(c(1)) %>% gsub("[^a-z_A-Z]", "", .)
    print("Debe brindar un data frame en los argumentos de la función que contenga estas columnas en el siguiente orden:")
  } else if(is.null(argumentos) & opcion %in% c('ListarEntidades', 'ListarCatalogoContable')) {
    h = basicTextGatherer()
    curlPerform(url = url_SUGEF, 
                httpheader = header, 
                postfields = body, 
                writefunction = h$update, 
                verbose = FALSE)
    # Prueba de conexion al servidor
    if(grepl("Runtime Error|Request Rejected", h$value())){
      svDialogs::dlgMessage("1. No fue posible hacer conexión con el sitio web de SUGEF", type = "ok")
      output <- tibble()
    } else {
      xmlOutput <- read_xml(h$value())
      xmlOutput1 <- xmlParse(xmlOutput, asText = TRUE, 
                             # Se añaden instrucciones para mejor proc datos:
                             useInternalNodes = FALSE, isHTML = TRUE)
      # xmlOutput2 <- xmlRoot(xmlOutput1) # anterior
      xmlOutput2 <- xmlOutput1[3]$children$html # nuevo
      
      #### Proceso de descomposicion de nodos
      child <- xmlChildren(xmlOutput2)
      # Por la estructura en que viene el archivo se hace 6 veces:
      for (i in 1:6) {
        child <- xmlChildren(child[[1]])
      }
      # xmlName(child[[1]])
      # xmlValue(child[[1]])
      # xmlSize(child[[1]])
      child1 <- purrr::map(.x = child, 
                           .f = ~ xmlChildren(.x) %>% 
                             sapply(xmlValue) %>% rbind() %>% 
                             as.data.frame() %>% as_tibble()
      ) %>% bind_rows()
      
      ####
      output <- child1 %>% distinct()
    }
    
    # if(resultado[1] == "valor"){
    #   output <- sapply(xpathSApply(xmlOutput2, "//*"), xmlValue) %>% unique()
    # } else if(resultado[1] == "nombre"){
    #   output <- xmlOutput2 %>% xpathSApply(., "//*") %>% lapply(., names) %>% unique()
    # }
  } else {
    h = basicTextGatherer()
    curlPerform(url = url_SUGEF, 
                httpheader = header, 
                postfields = argumentos, 
                writefunction = h$update, 
                verbose = FALSE)
    # Prueba de conexion al servidor
    if(grepl("Runtime Error|Request Rejected", h$value())){
      svDialogs::dlgMessage("2. No fue posible hacer conexión con el sitio web de SUGEF", type = "ok")
      output <- tibble()
    } else {
      xmlOutput <- read_xml(h$value())
      xmlOutput1 <- xmlParse(xmlOutput, asText = TRUE, 
                             # Se añaden instrucciones para mejor proc datos:
                             useInternalNodes = FALSE, isHTML = TRUE)
      # xmlOutput2 <- xmlRoot(xmlOutput1) # anterior
      xmlOutput2 <- xmlOutput1[3]$children$html # nuevo
      
      #### Proceso de descomposicion de nodos
      child <- xmlChildren(xmlOutput2)
      # Por la estructura en que viene el archivo se hace 6 veces:
      for (i in 1:6) {
        child <- xmlChildren(child[[1]])
      }
      # xmlName(child[[1]])
      # xmlValue(child[[1]])
      # xmlSize(child[[1]])
      child1 <- purrr::map(.x = child, 
                           .f = ~ xmlChildren(.x) %>% 
                             sapply(xmlValue) %>% rbind() %>% 
                             as.data.frame() %>% as_tibble()
      ) %>% bind_rows()
      
      ####
      output <- child1 %>% distinct()
    }
    
    # if(resultado[1] == "valor"){
    #   output <- sapply(xpathSApply(xmlOutput2, "//*"), xmlValue) %>% unique()
    # } else if(resultado[1] == "nombre"){
    #   output <- xmlOutput2 %>% xpathSApply(., "//*") %>% lapply(., names) %>% unique()
    # }
  }
  
  return(output)
}

# opcion = 'ObtenerBalanceSituacion_x_Entidad'
# opcion = 'ObtenerIndicadoresFinancieros_x_Entidad'
# opcion = 'ListarCatalogoContable'
# opcion = 'ListarEntidades'
# resultado = "valor"
# argumentos <- opRef_sugef("ObtenerBalanceSituacion_x_Entidad") %>% strsplit(., "\n") %>% lapply(., function(x) x[grepl('string', x)]) %>% unlist() %>% as.character() %>% strsplit(., 'string') %>% purrr::map_chr(c(1)) %>% gsub("[^a-z_A-Z]", "", .)
# argumentos <- opRef_sugef("ObtenerEstadoResultados_x_Entidad") %>% strsplit(., "\n") %>% lapply(., function(x) x[grepl('string', x)]) %>% unlist() %>% as.character() %>% strsplit(., 'string') %>% purrr::map_chr(c(1)) %>% gsub("[^a-z_A-Z]", "", .)
# rm(opcion, resultado, url_SUGEF, header, body, h, xmlOutput, xmlOutput1, xmlOutput2, output, child, child1)
