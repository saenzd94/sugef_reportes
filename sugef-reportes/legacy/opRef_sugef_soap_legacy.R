
opRef_sugef <- function(opcion = NULL){
  
  options <- c('ListarEntidades','ObtenerActividadEconomicayDiasAtrasoDetallado',
               'ObtenerBalanceSituacionContable_x_Entidad',
               'ObtenerBalanceSituacionContable_x_Sector',
               'ObtenerBalanceSituacion_x_Entidad',
               'ObtenerBalanceSituacion_x_Sector','ObtenerEntidadBCCR',
               'ObtenerEstadoFinancieroTotal_x_Entidad',
               'ObtenerEstadoFinancieroTotal_x_Sector',
               'ObtenerEstadoFinanciero_x_Entidad','ObtenerEstadoFinanciero_x_Sector',
               'ObtenerEstadoResultadosContable_x_Entidad',
               'ObtenerEstadoResultadosContable_x_Sector',
               'ObtenerEstadoResultados_x_Entidad','ObtenerEstadoResultados_x_Sector',
               'ObtenerIndicadoresFinancieros_x_Entidad',
               'ObtenerIndicadoresFinancieros_x_Sector','ObtenerNombreEntidadYSector',
               'ObtenerReporteActividadEconomicaGradoAtencion',
               'ObtenerReporteAmbitoTerritorial',
               'ObtenerReporteAmbitodeCambioClimatico',
               'ObtenerReporteCaracteristicasCondicionesPorEstadoOperacion',
               'ObtenerReporteCaracteristicasCondicionesPorTasaDeInteresPromedio',
               'ObtenerReporteCaracteristicasCondicionesPorTemporalidadPromedioDelFinanciamientoEnDias',
               'ObtenerReporteCaracteristicasCondicionesPorTipoCartera',
               'ObtenerReporteCaracteristicasCondicionesPorTipoCliente',
               'ObtenerReporteCaracteristicasCondicionesPorTipoGarantia',
               'ObtenerReporteCaracteristicasCondicionesPorTipoReceptor',
               'ObtenerReporteCategoriaEconomicayClasContable',
               'ObtenerReporteCategoriaEconomicayDiasAtraso',
               'ObtenerReporteCategoriaEconomicayRiesgo','ObtenerReporteCategoriaRiesgo',
               'ObtenerReporteCategoriaRiesgoyClasContable',
               'ObtenerReporteCategoriaRiesgoyClasContableSBD',
               'ObtenerReporteCategoriaRiesgoyDiasAtraso',
               'ObtenerReporteDiasAtrasoyClasContable',
               'ObtenerReporteDiasAtrasoyMoraFinanciera',
               'ObtenerReporteDiasAtrasoyMoraLegal','ObtenerReporteEncajeLegalAntes',
               'ObtenerReporteEncajeLegalDespues',
               'ObtenerReporteFinancimientoPorTemaYSubtemaDeCambioClimatico',
               'ObtenerReporteFondeador','ObtenerReporteInformacionGeneral',
               'ObtenerReporteInteresesxCobrar','ObtenerReporteSistemaBancaParaElDesarrollo',
               'ObtenerReporteTipoDeCambio','ListarCatalogoContable')
  
  nameBody <- list(list(name = 'ListarEntidades',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ListarEntidades xmlns="http://tempuri.org/" />
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerActividadEconomicayDiasAtrasoDetallado',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerActividadEconomicayDiasAtrasoDetallado xmlns="http://tempuri.org/">
      <entidades>string</entidades>
      <periodos>string</periodos>
      <tipoentidad>string</tipoentidad>
      <tipoReporte>string</tipoReporte>
    </ObtenerActividadEconomicayDiasAtrasoDetallado>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerBalanceSituacionContable_x_Entidad',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerBalanceSituacionContable_x_Entidad xmlns="http://tempuri.org/">
      <Entidad>string</Entidad>
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerBalanceSituacionContable_x_Entidad>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerBalanceSituacionContable_x_Sector',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerBalanceSituacionContable_x_Sector xmlns="http://tempuri.org/">
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <Tipo_Reporte>unsignedByte</Tipo_Reporte>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerBalanceSituacionContable_x_Sector>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerBalanceSituacion_x_Entidad',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerBalanceSituacion_x_Entidad xmlns="http://tempuri.org/">
      <Entidad>string</Entidad>
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerBalanceSituacion_x_Entidad>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerBalanceSituacion_x_Sector',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerBalanceSituacion_x_Sector xmlns="http://tempuri.org/">
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <Tipo_Reporte>unsignedByte</Tipo_Reporte>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerBalanceSituacion_x_Sector>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerEntidadBCCR',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerEntidadBCCR xmlns="http://tempuri.org/">
      <Entidad>string</Entidad>
    </ObtenerEntidadBCCR>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerEstadoFinancieroTotal_x_Entidad',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerEstadoFinancieroTotal_x_Entidad xmlns="http://tempuri.org/">
      <Entidad>string</Entidad>
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerEstadoFinancieroTotal_x_Entidad>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerEstadoFinancieroTotal_x_Sector',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerEstadoFinancieroTotal_x_Sector xmlns="http://tempuri.org/">
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <Tipo_Reporte>unsignedByte</Tipo_Reporte>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerEstadoFinancieroTotal_x_Sector>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerEstadoFinanciero_x_Entidad',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerEstadoFinanciero_x_Entidad xmlns="http://tempuri.org/">
      <Entidad>string</Entidad>
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerEstadoFinanciero_x_Entidad>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerEstadoFinanciero_x_Sector',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerEstadoFinanciero_x_Sector xmlns="http://tempuri.org/">
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <Tipo_Reporte>unsignedByte</Tipo_Reporte>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerEstadoFinanciero_x_Sector>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerEstadoResultadosContable_x_Entidad',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerEstadoResultadosContable_x_Entidad xmlns="http://tempuri.org/">
      <Entidad>string</Entidad>
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerEstadoResultadosContable_x_Entidad>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerEstadoResultadosContable_x_Sector',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerEstadoResultadosContable_x_Sector xmlns="http://tempuri.org/">
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <Tipo_Reporte>unsignedByte</Tipo_Reporte>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerEstadoResultadosContable_x_Sector>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerEstadoResultados_x_Entidad',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerEstadoResultados_x_Entidad xmlns="http://tempuri.org/">
      <Entidad>string</Entidad>
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerEstadoResultados_x_Entidad>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerEstadoResultados_x_Sector',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerEstadoResultados_x_Sector xmlns="http://tempuri.org/">
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <Tipo_Reporte>unsignedByte</Tipo_Reporte>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerEstadoResultados_x_Sector>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerIndicadoresFinancieros_x_Entidad',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerIndicadoresFinancieros_x_Entidad xmlns="http://tempuri.org/">
      <Entidad>string</Entidad>
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerIndicadoresFinancieros_x_Entidad>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerIndicadoresFinancieros_x_Sector',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerIndicadoresFinancieros_x_Sector xmlns="http://tempuri.org/">
      <Sector>string</Sector>
      <Periodos>string</Periodos>
      <Tipo_Reporte>unsignedByte</Tipo_Reporte>
      <C_Cuenta>string</C_Cuenta>
    </ObtenerIndicadoresFinancieros_x_Sector>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerNombreEntidadYSector',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerNombreEntidadYSector xmlns="http://tempuri.org/">
      <Entidad>string</Entidad>
    </ObtenerNombreEntidadYSector>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteActividadEconomicaGradoAtencion',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteActividadEconomicaGradoAtencion xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <periodos>string</periodos>
    </ObtenerReporteActividadEconomicaGradoAtencion>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteAmbitoTerritorial',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteAmbitoTerritorial xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteAmbitoTerritorial>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteAmbitodeCambioClimatico',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteAmbitodeCambioClimatico xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteAmbitodeCambioClimatico>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCaracteristicasCondicionesPorEstadoOperacion',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCaracteristicasCondicionesPorEstadoOperacion xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteCaracteristicasCondicionesPorEstadoOperacion>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCaracteristicasCondicionesPorTasaDeInteresPromedio',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCaracteristicasCondicionesPorTasaDeInteresPromedio xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteCaracteristicasCondicionesPorTasaDeInteresPromedio>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCaracteristicasCondicionesPorTemporalidadPromedioDelFinanciamientoEnDias',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCaracteristicasCondicionesPorTemporalidadPromedioDelFinanciamientoEnDias xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteCaracteristicasCondicionesPorTemporalidadPromedioDelFinanciamientoEnDias>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCaracteristicasCondicionesPorTipoCartera',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCaracteristicasCondicionesPorTipoCartera xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteCaracteristicasCondicionesPorTipoCartera>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCaracteristicasCondicionesPorTipoCliente',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCaracteristicasCondicionesPorTipoCliente xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteCaracteristicasCondicionesPorTipoCliente>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCaracteristicasCondicionesPorTipoGarantia',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCaracteristicasCondicionesPorTipoGarantia xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteCaracteristicasCondicionesPorTipoGarantia>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCaracteristicasCondicionesPorTipoReceptor',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCaracteristicasCondicionesPorTipoReceptor xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteCaracteristicasCondicionesPorTipoReceptor>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCategoriaEconomicayClasContable',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCategoriaEconomicayClasContable xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <periodos>string</periodos>
    </ObtenerReporteCategoriaEconomicayClasContable>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCategoriaEconomicayDiasAtraso',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCategoriaEconomicayDiasAtraso xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <periodos>string</periodos>
    </ObtenerReporteCategoriaEconomicayDiasAtraso>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCategoriaEconomicayRiesgo',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCategoriaEconomicayRiesgo xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <periodos>string</periodos>
    </ObtenerReporteCategoriaEconomicayRiesgo>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCategoriaRiesgo',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCategoriaRiesgo xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <periodos>string</periodos>
    </ObtenerReporteCategoriaRiesgo>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCategoriaRiesgoyClasContable',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCategoriaRiesgoyClasContable xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <periodos>string</periodos>
    </ObtenerReporteCategoriaRiesgoyClasContable>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCategoriaRiesgoyClasContableSBD',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCategoriaRiesgoyClasContableSBD xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <periodos>string</periodos>
    </ObtenerReporteCategoriaRiesgoyClasContableSBD>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteCategoriaRiesgoyDiasAtraso',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteCategoriaRiesgoyDiasAtraso xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <periodos>string</periodos>
    </ObtenerReporteCategoriaRiesgoyDiasAtraso>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteDiasAtrasoyClasContable',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteDiasAtrasoyClasContable xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <periodos>string</periodos>
    </ObtenerReporteDiasAtrasoyClasContable>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteDiasAtrasoyMoraFinanciera',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteDiasAtrasoyMoraFinanciera xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <periodos>string</periodos>
    </ObtenerReporteDiasAtrasoyMoraFinanciera>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteDiasAtrasoyMoraLegal',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteDiasAtrasoyMoraLegal xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <periodos>string</periodos>
    </ObtenerReporteDiasAtrasoyMoraLegal>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteEncajeLegalAntes',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteEncajeLegalAntes xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <TipoEntidad>string</TipoEntidad>
      <periodos>string</periodos>
      <c_tipo_moneda>string</c_tipo_moneda>
    </ObtenerReporteEncajeLegalAntes>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteEncajeLegalDespues',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteEncajeLegalDespues xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <TipoEntidad>string</TipoEntidad>
      <periodos>string</periodos>
      <c_tipo_moneda>string</c_tipo_moneda>
    </ObtenerReporteEncajeLegalDespues>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteFinancimientoPorTemaYSubtemaDeCambioClimatico',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteFinancimientoPorTemaYSubtemaDeCambioClimatico xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteFinancimientoPorTemaYSubtemaDeCambioClimatico>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteFondeador',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteFondeador xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteFondeador>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteInformacionGeneral',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteInformacionGeneral xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteInformacionGeneral>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteInteresesxCobrar',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteInteresesxCobrar xmlns="http://tempuri.org/">
      <Entidades>string</Entidades>
      <periodos>string</periodos>
    </ObtenerReporteInteresesxCobrar>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteSistemaBancaParaElDesarrollo',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteSistemaBancaParaElDesarrollo xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteSistemaBancaParaElDesarrollo>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ObtenerReporteTipoDeCambio',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ObtenerReporteTipoDeCambio xmlns="http://tempuri.org/">
      <Periodo>string</Periodo>
    </ObtenerReporteTipoDeCambio>
  </soap12:Body>
</soap12:Envelope>'),
                   list(name = 'ListarCatalogoContable',
                        body = '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ListarCatalogoContable xmlns="http://tempuri.org/" />
  </soap12:Body>
</soap12:Envelope>')
  )
  opciones <- do.call(rbind.data.frame, nameBody)
  
  if(is.null(opcion)){
    output <- options
  } else {
    output <- opciones[which(opciones$name == opcion),2]
  }
  
  return(output)
  
}

# rm(opciones, nameBody, options)