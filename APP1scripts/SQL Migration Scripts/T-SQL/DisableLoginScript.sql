
--S = SQL login
--U = Windows login
--G = Windows group
--R = Server role
--C = Login mapped to a certificate
--K = Login mapped to an asymmetric key

--Description of the principal type:
--SQL_LOGIN
--WINDOWS_LOGIN
--WINDOWS_GROUP
--SERVER_ROLE
--CERTIFICATE_MAPPED_LOGIN
--ASYMMETRIC_KEY_MAPPED_LOGIN

SELECT 'ALTER LOGIN ' + name + ' DISABLE' FROM sys.server_principals  WHERE type in ('S','U','G')

-- SELECT 'ALTER LOGIN ' + name + ' DISABLE' FROM sys.database_principals WHERE type in ('S','U','G')