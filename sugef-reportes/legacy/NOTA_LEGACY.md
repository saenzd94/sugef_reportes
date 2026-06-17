# Archivos legacy (API SOAP)

Estos archivos corresponden a la implementación original basada en la API SOAP de SUGEF:
- `https://www.sugef.fi.cr/wsReportes/reportesWeb.asmx`

La API SOAP fue reemplazada por la API REST, que es la que utiliza el proyecto principal.
Estos archivos se conservan únicamente como referencia histórica.

## Archivos
- `sugef_soap_legacy.R`: función `sugef()` para llamadas SOAP con `RCurl`
- `opRef_sugef_soap_legacy.R`: plantillas XML para los bodies SOAP

## API REST actual
- URL: `https://www.sugef.fi.cr/Bccr.Sugef.Reportes_SitioWeb.API`
- Documentación: `https://www.sugef.fi.cr/Bccr.Sugef.Reportes_SitioWeb.API/index.html`
