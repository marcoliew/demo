/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [configKey]
      ,[configValue]
  FROM [Titanium_WNSW_train].[dbo].[DATACONFIG]

  WHERE [configKey] in ('ReportingServicesServerURL','TITANIUM_WEBAPPLICATIONS_URL','TITANIUM_WEBSERVICES_URL','TITANIUM_MANAGER_SERVER_LOCATION')


update DATACONFIG
set configValue = 'http://cldrssrstAPP1vo/ReportServer'
where configKey = 'ReportingServicesServerURL'

update DATACONFIG
set configValue = 'https://APP1-AWS-WEB-branch1-Train.nswhealth.net/titanium/web'
where configKey = 'TITANIUM_WEBAPPLICATIONS_URL'

update DATACONFIG
set configValue = 'https://APP1-AWS-WEB-branch1-Train.nswhealth.net/titanium'
where configKey = 'TITANIUM_WEBSERVICES_URL'

update DATACONFIG
set configValue = 'https://APP1-AWS-WEB-branch1-Train.nswhealth.net'
where configKey = 'TITANIUM_MANAGER_SERVER_LOCATION'