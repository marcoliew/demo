select id,Configid,ConfigValue from ConfigurationData where ConfigValue like 'localhost'

SELECT [configKey]
      ,[configValue]
  FROM [dbo].[DATACONFIG]

  WHERE [configKey] in ('ReportingServicesServerURL','TITANIUM_WEBAPPLICATIONS_URL','TITANIUM_WEBSERVICES_URL','TITANIUM_MANAGER_SERVER_LOCATION')
