CREATE VIEW [dbo].[TRANS4] 
AS SELECT * from Titanium_WS_train..TRANS4
GO
CREATE VIEW dbo.branch2_clinics
AS
SELECT        RecordNum AS [Clinic Id], code AS [Clinic Code], description AS [Clinic Name], bInternal AS Internal, CASE WHEN bInactive = 0 THEN 1 ELSE 0 END AS Active, address1 AS [Street Address], suburb, phone, fax, 
                         facilityID AS [Facility Id], AGIReference AS [AGI Reference], serviceUnitOspID AS [Unit OSP Id], Region
FROM            dbo.CLINIC
WHERE        (Deleted = 0) AND (bInactive = 0)
GO
CREATE VIEW dbo.branch2_providers
AS
SELECT        dbo.DENTIST4.code AS [Provider Id], dbo.DENTIST4.name AS [Provider Name], 
                         CASE WHEN wProviderType = 0 THEN 'Dentist' WHEN wProviderType = 1 THEN 'Hygienist' WHEN wProviderType = 2 THEN 'Orthodontist' WHEN wProviderType = 3 THEN 'Oral Surgeon' WHEN wProviderType = 4 THEN 'Periodontist'
                          WHEN wProviderType = 5 THEN 'Therapist' WHEN wProviderType = 6 THEN 'Lab Tech' WHEN wProviderType = 7 THEN 'Advanced Dental Tech' WHEN wProviderType = 8 THEN 'Specialist' WHEN wProviderType = 9 THEN 'Radiologist'
                          WHEN wProviderType = 11 THEN 'Chair Side Assistant' WHEN wProviderType = 12 THEN 'Other' WHEN wProviderType = 13 THEN 'Prosthetist' WHEN wProviderType = 15 THEN 'Oral Health Therapist' END AS [Provider Type], 
                         query_role.Code AS [Role Code], query_role.Description AS Role, CASE WHEN bIsStudent = 1 THEN 1 ELSE 0 END AS Student, CASE WHEN wProviderExternal = 0 THEN 1 ELSE 0 END AS [Internal Staff]
FROM            dbo.DENTIST4 LEFT OUTER JOIN
                             (SELECT        dbo.ProviderAttributes.ProviderId, dbo.ProviderRoles.Code, dbo.ProviderRoles.Description
                               FROM            dbo.ProviderAttributes LEFT OUTER JOIN
                                                         dbo.ProviderRoles ON dbo.ProviderAttributes.Value = dbo.ProviderRoles.Id AND dbo.ProviderRoles.Deleted = 0
                               WHERE        (dbo.ProviderAttributes.Deleted = 0)) AS query_role ON dbo.DENTIST4.code = query_role.ProviderId
WHERE        (dbo.DENTIST4.Deleted = 0)
GO
CREATE VIEW dbo.branch2_patients
AS
SELECT        dbo.DEBTOR4.RecordNum AS [Ti Patient Id], dbo.DEBTOR4.code AS [ISOH Id], sq_ext_pat_id.AUID AS [AU Id], sq_ext_pat_id.[DRN - WM] AS [DRN WM], sq_ext_pat_id.[DRN - MT] AS [DRN MT], 
                         sq_ext_pat_id.[DRN - BT] AS [DRN BLK], { fn CONCAT(dbo.DEBTOR4.firstName COLLATE Latin1_General_CI_AS, { fn CONCAT(' ', UPPER(dbo.DEBTOR4.lastName COLLATE Latin1_General_CI_AS)) }) } AS [Full Name], 
                         dbo.DEBTOR4.title, dbo.DEBTOR4.firstName AS [First Name], dbo.DEBTOR4.lastName AS Surname, CASE WHEN dtbirth IS NULL THEN '' ELSE CONVERT(DATE, dtbirth, 103) END AS DOB, 
                         CASE WHEN debtor4.wdeceased = 0 THEN NULL ELSE CONVERT(DATE, dtdeath, 103) END AS DOD, CASE WHEN wassex = 1 THEN 'Male' WHEN wassex = 2 THEN 'Female' ELSE NULL END AS Sex, 
                         dbo.DEBTOR4.address1 AS [Street Address], dbo.DEBTOR4.address2 AS Suburb, dbo.DEBTOR4.address4 AS State, dbo.DEBTOR4.postCode1 AS Postcode, dbo.DEBTOR4.workAddr3 AS [Postal Street Address], 
                         dbo.DEBTOR4.workAddr4 AS [Postal Suburb], dbo.DEBTOR4.workAddr5 AS [Postal State], dbo.DEBTOR4.workPostcode AS [Postal Postcode], dbo.DEBTOR4.homePhone AS [Primary Phone], 
                         dbo.DEBTOR4.phoneOther AS [Secondary Phone], dbo.DEBTOR4.workPhone AS [Work Phone], CASE WHEN LEFT(DEBTOR4.homePhone, 2) = '04' AND Len(DEBTOR4.homePhone) 
                         = 10 THEN DEBTOR4.homePhone WHEN LEFT(DEBTOR4.phoneOther, 2) = '04' AND Len(DEBTOR4.phoneOther) = 10 THEN DEBTOR4.phoneOther WHEN LEFT(DEBTOR4.workPhone, 2) = '04' AND Len(DEBTOR4.workPhone) 
                         = 10 THEN DEBTOR4.workPhone WHEN Len(DEBTOR4.homePhone) = 10 THEN DEBTOR4.homePhone WHEN Len(DEBTOR4.homePhone) = 8 THEN '02' + DEBTOR4.homePhone WHEN Len(DEBTOR4.phoneOther) 
                         = 10 THEN DEBTOR4.phoneOther WHEN Len(DEBTOR4.phoneOther) = 8 THEN '02' + DEBTOR4.phoneOther WHEN len(DEBTOR4.workPhone) = 10 THEN DEBTOR4.workPhone WHEN len(DEBTOR4.workPhone) 
                         = 9 THEN '02' + DEBTOR4.workPhone ELSE NULL END AS [SMS Phone], 
                         CASE WHEN waboriginality = 0 THEN '' WHEN waboriginality = 1 THEN 'Aboriginal but not Torres Strait Islander' WHEN waboriginality = 2 THEN 'Torres Strait Islander but not Aboriginal' WHEN waboriginality = 3 THEN 'Both Aboriginal and Torres Strait Islander'
                          WHEN waboriginality = 4 THEN 'Neither' WHEN waboriginality = 7 THEN '' WHEN waboriginality = 8 THEN 'Declined to Respond' WHEN waboriginality = 9 THEN 'Not Stated' END AS Aboriginality, 
                         CASE WHEN wInactive = 0 THEN 1 ELSE 0 END AS Active, dbo.DEBTOR4.bSMS AS [SMS Permission], dbo.DEBTOR4.email AS Email
FROM            dbo.DEBTOR4 LEFT OUTER JOIN
                             (SELECT        ridPatient, MAX(CASE WHEN idtype = 'AUID' THEN externalid ELSE NULL END) AS AUID, MAX(CASE WHEN idtype = 'DRN-WM' THEN externalid ELSE NULL END) AS [DRN - WM], 
                                                         MAX(CASE WHEN idtype = 'DRN-BT' THEN externalid ELSE NULL END) AS [DRN - BT], MAX(CASE WHEN idtype = 'DRN-MT' THEN externalid ELSE NULL END) AS [DRN - MT]
                               FROM            dbo.EXT_PAT_ID
                               GROUP BY ridPatient) AS sq_ext_pat_id ON dbo.DEBTOR4.RecordNum = sq_ext_pat_id.ridPatient
GO
CREATE VIEW dbo.branch2_voucher_transactions
AS
SELECT        TOP (100) PERCENT dbo.TRANS4.RecordNum AS [Ti Transaction Id], dbo.TRANS4.invNum AS [Transaction Code], CAST(dbo.TRANS4.dtTrns AS date) AS [Transaction Date], LEFT(dbo.TRANS4.userComment_0, 
                         CHARINDEX('(Voucher)', dbo.TRANS4.userComment_0) - 2) AS [Voucher Type], dbo.TRANS4.userComment_1 AS [Patient Name], dbo.TRANS4.uidCOT AS [Ti Course of Care Id], dbo.branch2_providers.[Provider Name], 
                         dbo.branch2_clinics.[Clinic Name] AS [External Clinic Name], CAST(dbo.TRANS4.cuAmount AS money) AS [Transaction Amount]
FROM            dbo.TRANS4 LEFT OUTER JOIN
                         dbo.branch2_providers ON dbo.TRANS4.provider = dbo.branch2_providers.[Provider Id] LEFT OUTER JOIN
                         dbo.branch2_clinics ON dbo.TRANS4.treatmentClinic = dbo.branch2_clinics.[Clinic Code]
WHERE        (dbo.TRANS4.invNum NOT LIKE 'VC%') AND (dbo.TRANS4.Deleted = 0) AND (dbo.TRANS4.payorCode IN ('EXT-EMER', 'EXT-GEN', 'EXT-PROS'))
GO

CREATE VIEW dbo.branch2_vouchers
AS
SELECT        dbo.TRANS4.RecordNum AS [Ti Transaction Id], dbo.TRANS4.invNum AS [Voucher Code], dbo.TRANS4.ridPatient AS [Ti Patient Id], dbo.TRANS4.uidCOT AS [Ti Course of Care Id], CONVERT(date, dbo.TRANS4.dtTrns, 203) 
                         AS [Voucher Date], CASE WHEN MONTH(TRANS4.dtTrns) <= 6 THEN CAST(YEAR(TRANS4.dtTrns) - 1 AS varchar(4)) + '-' + CAST(YEAR(TRANS4.dtTrns) AS varchar(4)) ELSE CAST(YEAR(TRANS4.dtTrns) AS varchar(4)) 
                         + '-' + CAST(YEAR(TRANS4.dtTrns) + 1 AS varchar(4)) END AS Voucher_Financial_Year, pvcode.[Funding Scheme], dbo.TRANS4.enteredBy AS [Voucher Entered By], dbo.TRANS4.clinic AS [Voucher Clinic], 
                         CASE WHEN TRANS4.bauthoritycancelled = 1 THEN 'Cancelled' WHEN subq_voucher_transactions.sumtransactionamount = 0 THEN 'Claimed no Fee' WHEN subq_voucher_transactions.sumtransactionamount IS NULL 
                         THEN 'Not Claimed' WHEN subq_voucher_transactions.sumtransactionamount > 0 THEN 'Claimed' END AS [Voucher Status], dbo.TRANS4.bPrinted AS Printed, CAST(subq_voucherlimit.maxvoucherlimit AS money) 
                         AS [Voucher Fee Limit], CAST(subq_voucher_transactions.sumtransactionamount AS money) AS [Voucher Fee Claimed], 
                         CASE WHEN TRANS4.bauthoritycancelled = 1 THEN 0 WHEN subq_voucher_transactions.sumtransactionamount IS NULL 
                         THEN subq_voucherlimit.maxvoucherlimit ELSE subq_voucher_transactions.sumtransactionamount END AS [Voucher Carrying Fee], CONVERT(date, subq_voucher_transactions.maxtransactiondate, 203) 
                         AS [Latest Voucher Fee Claim Date], DWAUclaim.DWAU
FROM            dbo.TRANS4 LEFT OUTER JOIN
                             (SELECT        uidCOT, MAX(cuVoucherLimit) AS maxvoucherlimit
                               FROM            dbo.CHART5
                               WHERE        (cuVoucherLimit > 0)
                               GROUP BY uidCOT) AS subq_voucherlimit ON dbo.TRANS4.uidCOT = subq_voucherlimit.uidCOT LEFT OUTER JOIN
                             (SELECT        [Ti Course of Care Id], MAX([Transaction Date]) AS maxtransactiondate, SUM([Transaction Amount]) AS sumtransactionamount
                               FROM            dbo.branch2_voucher_transactions
                               GROUP BY [Ti Course of Care Id]) AS subq_voucher_transactions ON dbo.TRANS4.uidCOT = subq_voucher_transactions.[Ti Course of Care Id] LEFT OUTER JOIN
                             (SELECT        uidCOT AS [Ti Course of Care Id], pvCode AS [Funding Scheme]
                               FROM            dbo.CHART5 AS CHART5_1
                               GROUP BY uidCOT, pvCode) AS pvcode ON dbo.TRANS4.uidCOT = pvcode.[Ti Course of Care Id] LEFT OUTER JOIN
                             (SELECT        [Ti Patient Id], [Ti Course of Care Id], MAX([Date Completed]) AS [Date Last Update], COUNT(*) AS Items, SUM(DWAU) AS DWAU
                               FROM            dbo.branch2_service_items
                               WHERE        (LEN([Date Completed]) > 0)
                               GROUP BY [Ti Patient Id], [Ti Course of Care Id]) AS DWAUclaim ON dbo.TRANS4.uidCOT = DWAUclaim.[Ti Course of Care Id]
WHERE        (dbo.TRANS4.invNum LIKE 'VC%') AND (dbo.TRANS4.payorCode = '')
GO
CREATE VIEW dbo.branch2_vouchersold
AS
SELECT        dbo.branch2_vouchers.[Latest Voucher Fee Claim Date] AS [Date Updated], dbo.branch2_vouchers.[Voucher Date] AS [Date Entered], DATEPART(week, dbo.branch2_vouchers.[Voucher Date]) AS [Entered Calendar Week], 
                         DATEPART(year, dbo.branch2_vouchers.[Voucher Date]) AS [Entered Calendar Year], dbo.branch2_vouchers.[Voucher Date] AS [Date Transaction], dbo.branch2_vouchers.[Voucher Code] AS [Voucher Number], 
                         dbo.branch2_patients.[Full Name] AS [Patient Name], dbo.branch2_vouchers.[Voucher Entered By], dbo.branch2_vouchers.[Voucher Clinic], dbo.branch2_vouchers.Printed AS [Printed Status], 
                         CASE WHEN [Voucher Status] = 'Cancelled' THEN 'Cancelled' ELSE 'Not Cancelled' END AS [Cancelled Status], dbo.branch2_vouchers.[Ti Patient Id], dbo.branch2_patients.[AU Id], dbo.branch2_patients.[Full Name], 
                         dbo.branch2_patients.[DRN WM], dbo.branch2_patients.DOB, dbo.branch2_vouchers.[Ti Course of Care Id], dbo.branch2_vouchers.[Voucher Fee Claimed], dbo.branch2_vouchers.[Voucher Fee Limit], 
                         dbo.branch2_vouchers.[Voucher Carrying Fee], CASE WHEN DatePart(Month, [Voucher Date]) >= 7 THEN DatePart(Year, [Voucher Date]) + 1 ELSE DatePart(Year, [Voucher Date]) END AS [Transaction Financial Year], 
                         CASE WHEN DatePart(Month, [Voucher Date]) >= 7 THEN DatePart(Month, [Voucher Date]) - 6 ELSE DatePart(Month, [Voucher Date]) + 6 END AS [Transaction Financial Month]
FROM            dbo.branch2_vouchers LEFT OUTER JOIN
                         dbo.branch2_patients ON dbo.branch2_vouchers.[Ti Patient Id] = dbo.branch2_patients.[Ti Patient Id]
GO

CREATE VIEW dbo.branch2_service_plans
AS
SELECT DISTINCT 
                         ridPatient AS [Ti Patient Id], uidCOT AS [Ti Course of Care Id], CONVERT(date, dtFirstAttendance, 23) AS [Date Started], CONVERT(date, dtComplete, 23) AS [Date Completed], CONVERT(date, dtCharged, 23) AS [Date Last Charged], 
                         entryClinic AS [Entry Clinic], provider AS [Entry Provider Id], pvCode AS [Funding Scheme]
FROM            dbo.CHART5
WHERE        (LEFT(userComment, 14) = 'Course of Care') AND (Deleted = 0)
GO
CREATE VIEW dbo.branch2_service_items
AS
SELECT        TOP (100) PERCENT dbo.CHART5.ridPatient AS [Ti Patient Id], dbo.CHART5.uidCOT AS [Ti Course of Care Id], dbo.CHART5.service AS [Service Item], dbo.DSERV4.ADACode_0 AS [ADA Code], 
                         dbo.CHART5.userComment AS [Service Comment], CONVERT(date, dbo.CHART5.dtPlanned, 23) AS [Date Planned], CONVERT(date, dbo.CHART5.dtComplete, 23) AS [Date Completed], CONVERT(date, chart5.[dtcharged ], 23) 
                         AS [Date Charged], dbo.CHART5.provider AS [Item Provider Id], dbo.CHART5.clinic AS Clinic, dbo.DSERV4.dStdTimeUnit AS DWAU, dbo.CHART5.pvCode AS [Funding Scheme]
FROM            dbo.CHART5 LEFT OUTER JOIN
                         dbo.DSERV4 ON dbo.CHART5.service = dbo.DSERV4.code
WHERE        (dbo.CHART5.Deleted = 0) AND (LEN(dbo.CHART5.service) > 1) AND (dbo.CHART5.uidCOT IS NOT NULL) AND (dbo.CHART5.uidCOT NOT IN (' ', '')) AND (dbo.CHART5.dtPlanned IS NOT NULL)
GO
CREATE VIEW dbo.branch2_amm_assignments
AS
SELECT        Id AS [Ti Assignment Id], CreatedDate AS [Assignment Date], PatientId AS [Ti Patient Id], ProviderId AS [Provider Id], ProcessingUserCode AS [Processing User], 
                         CASE WHEN Status = 0 THEN 'Active' WHEN Status = 1 THEN 'Complete' WHEN Status = 2 THEN 'Pending Reassignment' WHEN Status = 3 THEN 'Pending Assistance' WHEN Status = 4 THEN 'Temporary' WHEN Status = 5 THEN
                          'Discharge' WHEN Status = 6 THEN 'Inactive' WHEN Status = 7 THEN 'Pending Inactivation' WHEN Status = 8 THEN 'Pending Discharged' WHEN Status = 9 THEN 'Cancelled' WHEN Status = 10 THEN 'Pending Reactivation' ELSE
                          '# Value not expected' END AS [Assignment Status], Notes
FROM            dbo.AcademicAssignment
WHERE        (Deleted = 0)
GO
CREATE VIEW dbo.branch2_waitlist_suitability
AS
select ridWaitlistEntry [Ti Waitlist Id], [Suitability Note] = STUFF
((select ', ' + [suitability note]
from 
(select 
dbo.PATSUITABILITY.ridWaitlistEntry,
case
when suitability = '0' then 'Dentist'
when suitability = '1' then 'Hygienist'
when suitability = '11' then ''
when suitability = '12' then 'Other'
when suitability = '13' then 'Prosthetist'
when suitability = '14' then 'Technician'
when suitability = '15' then 'Oral Health Therapist'
when suitability = '16' then 'Prosthodontist'
when suitability = '17' then 'Endodontist'
when suitability = '18' then 'Paediatric Dentist'
when suitability = '19' then 'Oral Medicine'
when suitability = '2' then 'Orthodontist'
when suitability = '22' then 'Special Needs Specialist'
when suitability = '3' then 'Oral Surgeon'
when suitability = '30' then 'Student Suitable'
when suitability = '31' then 'Unknown'
when suitability = '4' then 'Periodontist'
when suitability = '5' then 'Therapist'
when suitability = '8' then 'Specialist'
when suitability = '9' then 'Radiologist'
when suitability = 'EDUCA' then 'Clinical Educator'
when suitability = 'NOTSTU' then 'Not Student'
when suitability = 'PGRAD' then 'Post-Graduate'
when suitability = 'PSYCH' then 'Clinical Psychologist'
when suitability = 'SPATHO' then 'Speech Pathologist'
when suitability = 'VDO' then 'Visiting Dental Officer'
end as [suitability note]
from PATSUITABILITY
where Deleted = 0 ) ps2
where ps1.ridWaitlistEntry = ps2.ridWaitlistEntry
FOR XML PATH(''), TYPE ).value('.', 'varchar(max)'), 1, 1, '')
from PATSUITABILITY ps1
group by ridWaitlistEntry
GO
CREATE VIEW dbo.branch2_waitlist_treatmentneeds
AS
select ridWaitlistEntry [Ti Waitlist Id], [Treatment Needs] = STUFF
((select ', ' + treatmentNeed
from PATTXNEED ptn2
where ptn1.ridWaitlistEntry = ptn2.ridWaitlistEntry
FOR XML PATH(''), TYPE ).value('.', 'varchar(max)'), 1, 1, '')
from PATTXNEED ptn1
where deleted = 0
group by ridWaitlistEntry
GO
CREATE VIEW dbo.branch2_recall
AS
SELECT        dbo.RECALL.RecordNum AS [Ti Recall Id], CONVERT(date, dbo.RECALL.dtCreated, 23) AS [Date Listed], CONVERT(date, DATEADD(month, dbo.RECALL.lInterval, dbo.RECALL.dtCreated), 23) AS [Date Due], 
                         dbo.RECALL.typecode AS [Recall Type], CASE WHEN wRiskStatus = 0 THEN 'Low Risk' WHEN wRiskStatus = 1 THEN 'Medium Risk' WHEN wRiskStatus = 2 THEN 'High Risk' END AS [Patient Risk Status], 
                         CASE WHEN wstatus = 0 THEN 'Void' WHEN wstatus = 1 THEN 'On Recall' WHEN wstatus = 2 THEN 'Ready' WHEN wstatus = 3 THEN 'Responded' WHEN wstatus = 4 THEN 'Purged' WHEN wstatus = 5 THEN 'Cancelled' WHEN wstatus
                          = 6 THEN 'Complete' END AS [Recall Status], dbo.RECALL.clinicCode AS Clinic, CASE WHEN provider = 'UNKNOWN' THEN '' ELSE provider END AS [Provider Id], dbo.RECALL.ridDebtor AS [Ti Patient Id], 
                         dbo.branch2_notes.Comment AS [Recall Comment]
FROM            dbo.RECALL LEFT OUTER JOIN
                         dbo.branch2_notes ON dbo.RECALL.uidComment = dbo.branch2_notes.[Ti Comment Id]
WHERE        (dbo.RECALL.Deleted = 0)
GO
CREATE VIEW dbo.branch2_lab_case
AS
SELECT        dbo.LABCASES.RecordNum AS [Ti Lab Case Id], CAST(dbo.LABCASES.lLabRequestNum AS varchar) AS [Request Id], dbo.LABCASES.ridPatient AS [Ti Patient Id], CAST(dbo.LABCASES.labCasedate AS date) AS [Date Planned], 
                         CAST(dbo.LABCASES.dtJobRequired AS date) AS [Date Required], CAST(dbo.LABCASES.dtComplete AS date) AS [Date Completed], 
                         CASE WHEN labcasestatus = 1 THEN 'Requested' WHEN labcasestatus = 2 THEN 'Assigned' WHEN labcasestatus = 3 THEN 'Ready' WHEN labcasestatus = 4 THEN 'Complete' WHEN labcasestatus = 5 THEN 'Cancelled' END AS
                          [Case Status], dbo.LABCASES.Clinician AS [Provider Id], dbo.LABCASES.Clinic, dbo.LABCASES.labCaseType AS [Case Type], dbo.LABCASES.labJobType AS [Job Type], CAST(dbo.LABCASES.dRequestedUnits AS int) 
                         AS [Case Units], dbo.branch2_notes.Comment AS [Case Comment]
FROM            dbo.LABCASES LEFT OUTER JOIN
                         dbo.branch2_notes ON dbo.LABCASES.uidComments = dbo.branch2_notes.[Ti Comment Id]
WHERE        (dbo.LABCASES.Deleted = 0)
GO
CREATE VIEW dbo.branch2_lab_stage
AS
SELECT        dbo.LABSTAGE.RecordNum AS [Ti Lab Stage Id], dbo.LABSTAGE.ridLabRequest AS [Ti Lab Case Id], 
                         CASE WHEN wStatus = 1 THEN 'Requested' WHEN wStatus = 2 THEN 'Assigned' WHEN wStatus = 3 THEN 'On Hold' WHEN wStatus = 4 THEN 'Cancelled' WHEN wStatus = 5 THEN 'Complete' END AS [Stage Status], 
                         dbo.LABSTAGE.ssStageType AS [Stage Type], CAST(dbo.LABSTAGE.dtRequiredBy AS date) AS [Date Stage Required], CAST(dbo.LABSTAGE.dtFTADate AS date) AS [Date FTA], CAST(dbo.LABSTAGE.dtCollectionDate AS date) 
                         AS [Date Collected], dbo.LABSTAGE.ssLabTechnican1 AS [Lab Technician 1], dbo.LABSTAGE.ssLabTechnican2 AS [Lab Technician 2], dbo.LABSTAGE.ssQATechnican AS [QA Technician], dbo.LABSTAGE.bRemake AS Remake, 
                         dbo.LABSTAGE.uOvertime AS Overtime, dbo.branch2_notes.Comment AS [Stage Comment]
FROM            dbo.LABSTAGE LEFT OUTER JOIN
                         dbo.branch2_notes ON dbo.LABSTAGE.uidComments = dbo.branch2_notes.[Ti Comment Id]
WHERE        (dbo.LABSTAGE.Deleted = 0)
GO
CREATE VIEW dbo.branch2_consents
AS
SELECT        dbo.CONSPATIENT.RecordNum AS [Ti Consent Id], dbo.CONSPATIENT.ridPatient AS [Ti Patient Id], dbo.CONSPATIENT.dtCreated AS [Date Created], dbo.CONSENT.consentname AS [Consent Name], 
                         dbo.CONSPATIENT.creatorUser AS [Provider Id], CASE WHEN dtinactivated IS NOT NULL 
                         THEN 'Void' WHEN binactive = 0 THEN 'Active' WHEN binactive = 1 THEN 'Active with Document' WHEN binactive = 2 THEN 'Active with Signature' END AS [Consent Status]
FROM            dbo.CONSPATIENT LEFT OUTER JOIN
                         dbo.CONSENT ON dbo.CONSPATIENT.ridConsent = dbo.CONSENT.RecordNum
WHERE        (dbo.CONSPATIENT.Deleted = 0) AND (dbo.CONSENT.Deleted = 0)
GO
CREATE VIEW dbo.branch2_referrals
AS
SELECT dbo.REFERRAL.RecordNum AS [Ti Referral Id], CASE WHEN wreferraltype = 0 THEN 'Referral In' WHEN wreferraltype = 1 THEN 'Referral Out' WHEN wreferraltype = 2 THEN 'Internal Referral' END AS [Referral Type], 
                  dbo.REFERRAL.referredTo AS [Referred To Provider], dbo.REFERRAL.ridDebtor AS [Ti Patient Id], CONVERT(date, dbo.REFERRAL.dtRefEntered, 23) AS [Date of Entry], CONVERT(date, dbo.REFERRAL.dtContact, 23) AS [Date of Contact], 
                  CONVERT(date, dbo.REFERRAL.dtOutcome, 23) AS [Date of Outcome], dbo.REFERRAL.reasonOutcome AS [Outcome Reason], dbo.REFERRAL.clinic AS [Referred To Clinic], 
                  CASE WHEN dbo.REFERRAL.wStatus = 0 THEN 'Received' WHEN dbo.REFERRAL.wStatus = 2 THEN 'Accepted' WHEN dbo.REFERRAL.wStatus = 3 THEN 'Rejected' WHEN dbo.REFERRAL.wStatus = 5 THEN 'Complete' WHEN dbo.REFERRAL.wStatus
                   = 7 THEN 'Purged' END AS [Referral Status], dbo.REFERRAL.referrer AS [Referred From], dbo.REFERRAL.referringClinic AS [Referred From Clinic], CASE WHEN usercomment IS NULL THEN '' ELSE userComment END AS Note
FROM     dbo.REFERRAL LEFT OUTER JOIN
                  dbo.GENCMT3 ON dbo.REFERRAL.uidRefferalnotes = dbo.GENCMT3.uidComment AND dbo.GENCMT3.Deleted = 0
WHERE  (dbo.REFERRAL.Deleted = 0)
GO

CREATE VIEW dbo.branch2_missing_items2
AS
SELECT        dbo.branch2_appointments.[Ti Appointment Id], dbo.branch2_appointments.[Ti Patient Id], dbo.branch2_appointments.[Appointment Date], dbo.branch2_appointments.[Appointment Time], dbo.branch2_appointments.[Appointment Length], 
                         dbo.branch2_appointments.[Appointment Status], dbo.branch2_appointments.Clinic, dbo.branch2_appointments.Chair, dbo.branch2_appointments.[Provider Id], dbo.branch2_appointments.[Ti Course of Care Id], 
                         dbo.branch2_appointments.[Appointment Comment], dbo.branch2_appointments.[Ti WaitlistRecall Id], dbo.branch2_patients.[Ti Patient Id] AS Expr1, dbo.branch2_patients.[ISOH Id], dbo.branch2_patients.[AU Id], 
                         dbo.branch2_patients.[DRN WM], dbo.branch2_patients.[DRN MT], dbo.branch2_patients.[DRN BLK], dbo.branch2_patients.[Full Name], dbo.branch2_patients.title, dbo.branch2_patients.[First Name], dbo.branch2_patients.Surname, 
                         dbo.branch2_patients.DOB, dbo.branch2_patients.DOD, dbo.branch2_patients.Sex, dbo.branch2_patients.[Street Address], dbo.branch2_patients.Suburb, dbo.branch2_patients.State, dbo.branch2_patients.Postcode, 
                         dbo.branch2_patients.[Postal Street Address], dbo.branch2_patients.[Postal Suburb], dbo.branch2_patients.[Postal State], dbo.branch2_patients.[Postal Postcode], dbo.branch2_patients.[Primary Phone], 
                         dbo.branch2_patients.[Secondary Phone], dbo.branch2_patients.[Work Phone], dbo.branch2_patients.[SMS Phone], dbo.branch2_patients.Aboriginality, dbo.branch2_patients.Active, dbo.branch2_patients.[SMS Permission], 
                         dbo.branch2_patients.Email, dbo.branch2_service_items.[Ti Patient Id] AS Expr2, dbo.branch2_service_items.[Ti Course of Care Id] AS Expr3, dbo.branch2_service_items.[Service Item], dbo.branch2_service_items.[ADA Code], 
                         dbo.branch2_service_items.[Service Comment], dbo.branch2_service_items.[Date Planned], dbo.branch2_service_items.[Date Completed], dbo.branch2_service_items.[Date Charged], dbo.branch2_service_items.[Item Provider Id], 
                         dbo.branch2_service_items.Clinic AS Expr4, dbo.branch2_service_items.DWAU, dbo.branch2_service_items.[Funding Scheme], sq_items.[Ti Patient Id] AS Expr5, sq_items.Clinic AS Expr6, sq_items.[Date Completed] AS Expr7, 
                         sq_items.Count, CASE WHEN branch2_appointments.Clinic IN ('MTOH', 'MTOS') THEN branch2_patients.[DRN MT] ELSE branch2_patients.[DRN WM] END AS DRN
FROM            dbo.branch2_appointments LEFT OUTER JOIN
                         dbo.branch2_patients ON dbo.branch2_appointments.[Ti Patient Id] = dbo.branch2_patients.[Ti Patient Id] LEFT OUTER JOIN
                         dbo.branch2_service_items ON dbo.branch2_appointments.[Appointment Date] = dbo.branch2_service_items.[Date Completed] AND dbo.branch2_appointments.[Ti Patient Id] = dbo.branch2_service_items.[Ti Patient Id] AND 
                         dbo.branch2_appointments.Clinic <> dbo.branch2_service_items.Clinic LEFT OUTER JOIN
                             (SELECT        [Ti Patient Id], Clinic, [Date Completed], COUNT(*) AS Count
                               FROM            dbo.branch2_service_items AS branch2_service_items_1
                               WHERE        ([Date Completed] IS NOT NULL)
                               GROUP BY [Ti Patient Id], Clinic, [Date Completed]) AS sq_items ON dbo.branch2_appointments.[Ti Patient Id] = sq_items.[Ti Patient Id] AND dbo.branch2_appointments.Clinic = sq_items.Clinic AND 
                         dbo.branch2_appointments.[Appointment Date] = sq_items.[Date Completed] AND sq_items.[Date Completed] >= '2019-07-01'
WHERE        (dbo.branch2_appointments.[Appointment Status] NOT IN ('Deleted', 'Cancelled', 'Booked', 'Confirmed')) AND (dbo.branch2_appointments.[Appointment Date] >= '2019-07-01') AND (sq_items.Count IS NULL)
GO
CREATE VIEW dbo.branch2_referrals_log
AS
SELECT TOP (100) PERCENT ridReferrer AS [Ti Referral Id], CONVERT(date, dtChanged, 23) AS [Date Changed], CONVERT(time, CreatedTime, 108) AS [Time Changed], 
                  CASE WHEN wStatus = 0 THEN 'Received' WHEN wStatus = 2 THEN 'Accepted' WHEN wStatus = 3 THEN 'Rejected' WHEN wStatus = 5 THEN 'Complete' WHEN wStatus = 7 THEN 'Purged' END AS [Referral Status], userCode AS [User]
FROM     dbo.REFLOG
ORDER BY [Ti Referral Id], CreatedDate DESC, CreatedTime DESC
GO
CREATE VIEW dbo.branch2_waitlist_log
AS
SELECT TOP (100) PERCENT ridWaitlist AS [Ti Waitlist Id], CONVERT(date, dtChanged, 23) AS [Date Changed], CONVERT(time, CreatedTime, 108) AS [Time Changed], 
                  CASE WHEN wStatus = 0 THEN 'Waiting' WHEN wStatus = 1 THEN 'Active' WHEN wStatus = 2 THEN 'Complete' WHEN wStatus = 3 THEN 'Deleted/Purged' WHEN wStatus = 4 THEN 'Deferred' WHEN wStatus = 5 THEN 'Transfer' WHEN wStatus
                   = 6 THEN 'Ready' WHEN wStatus = 7 THEN 'Booked' WHEN wStatus = 8 THEN 'Transferred to another clinic – DHSV' WHEN wStatus = 9 THEN 'Suspended – DHSV' WHEN wStatus = 999 THEN 'All' WHEN wStatus = 10 THEN 'Contacted' WHEN
                   wStatus = - 1 THEN 'Undefined' END AS [Waitlist Status], userCode AS [User]
FROM     dbo.WLLOG
ORDER BY [Ti Waitlist Id] DESC, CreatedDate DESC, CreatedTime DESC
GO
CREATE VIEW dbo.branch2_appointment_books
AS
SELECT RecordNum AS [Ti Appointment Book Id], name AS [Appointment Book Name], REPLACE(resources, '>', '') AS Chairs, clinicCode AS Clinic
FROM     dbo.APPBOOK
WHERE  (Deleted = 0)
GO
CREATE VIEW dbo.branch2_chairs
AS
SELECT RecordNum AS [Ti Chair Id], name AS Chair, clinic AS Clinic, bInactive AS Inactive, bRadiologyRoom AS [Radiology Room]
FROM     dbo.APPTRES
WHERE  (Deleted = 0)
GO
CREATE VIEW dbo.branch2_users
AS
SELECT TOP (100) PERCENT dbo.WINLOGON.RecordNum AS [Ti User Id], dbo.WINLOGON.NTUsername AS [Network Id], dbo.WINLOGON.name AS [User Short Name], dbo.WINLOGON.userName AS [User Full Name], 
                  securitygroups.[Security Group], dbo.WINLOGON.bAdmin AS [Admin Checkbox], CASE WHEN iLogonStatus_0 = 0 THEN 'Active' WHEN iLogonStatus_0 = 1 THEN 'Disabled' WHEN iLogonStatus_0 = 2 THEN 'Locked' END AS [User Status], 
                  lastlogon.[Date Last Activity]
FROM     dbo.WINLOGON LEFT OUTER JOIN
                      (SELECT uidFileNumber AS uidsecurity, code AS [Security Group]
                       FROM      dbo.SERCURE) AS securitygroups ON dbo.WINLOGON.uidSecurity = securitygroups.uidsecurity LEFT OUTER JOIN
                      (SELECT userCode AS [User Short Name], CONVERT(date, MAX(CreatedDate), 23) AS [Date Last Activity]
                       FROM      dbo.AUDITEVT2
                       GROUP BY userCode) AS lastlogon ON dbo.WINLOGON.name = lastlogon.[User Short Name]
WHERE  (dbo.WINLOGON.Deleted = 0)
ORDER BY [User Short Name]
GO
CREATE VIEW dbo.branch2_blocks
AS
SELECT RecordNum AS [Ti Block Id], CONVERT(date, dtDate, 23) AS [Block Date], room AS Chair, wStartTime, wLength, reason AS [Block Note]
FROM     dbo.BLOCK6
GO
CREATE VIEW dbo.branch2_notes
AS
SELECT        uidcomment[Ti Comment Id], Comment = STUFF
                             ((SELECT        ',' + CAST(REPLACE(usercomment, char(0x001F), '') AS VARCHAR(MAX))
                                 FROM            GENCMT3 AS T2
                                 /* You only want to combine rows for a single ID here:*/ 
WHERE T2.uidComment = T1.uidComment
and t2.Deleted = 0
                                 ORDER BY uidComment FOR XML PATH(''), TYPE ).value('.', 'varchar(max)'), 1, 1, '')
FROM            GENCMT3 AS T1
WHERE        Deleted = 0
GROUP BY uidComment
GO
CREATE VIEW dbo.branch2_students
AS
SELECT        TOP (100) PERCENT ace.ProviderId AS 'User/Provider Code', wl.userName AS 'User Name', sec.code AS 'Security Group', d4.name AS 'Provider Name', ac.Description AS 'Academic Course', acl.Description AS 'Academic Level', 
                         ay.Description AS 'Academic Year'
FROM            dbo.AcademicCourseEnrolmentYear AS acey INNER JOIN
                         dbo.AcademicCourseEnrolment AS ace ON ace.Id = acey.AcademicCourseEnrolmentId INNER JOIN
                         dbo.AcademicCourseLevel AS acl ON acl.Id = acey.AcademicCourseLevelId INNER JOIN
                         dbo.AcademicCourse AS ac ON ac.Id = acl.AcademicCourseId INNER JOIN
                         dbo.AcademicYear AS ay ON ay.Id = acey.AcademicCourseYearId INNER JOIN
                         dbo.WINLOGON AS wl ON wl.name = ace.ProviderId INNER JOIN
                         dbo.DENTIST4 AS d4 ON d4.code = ace.ProviderId LEFT OUTER JOIN
                         dbo.SERCURE AS sec ON sec.uidFileNumber = wl.uidSecurity
WHERE        (acey.CreatedDate =
                             (SELECT        MAX(CreatedDate) AS Expr1
                               FROM            dbo.AcademicCourseEnrolmentYear AS acey2
                               WHERE        (AcademicCourseEnrolmentId = acey.AcademicCourseEnrolmentId)))
ORDER BY 'Academic Course', 'Academic Year', 'Academic Level', 'User/Provider Code'
GO
CREATE VIEW dbo.branch2_cdbs_service_items
AS
--10/05/2021
--enhancement for cdbs to show the fee$

SELECT        
dbo.branch2_service_items.[Ti Patient Id], 
dbo.branch2_service_items.[Ti Course of Care Id], 
dbo.branch2_service_items.[ADA Code], 
dbo.branch2_service_items.[Service Item],
dbo.branch2_service_items.[Service Comment], 
dbo.branch2_service_items.[Date Charged], 
dbo.branch2_service_items.[Item Provider Id] AS [Provider Id], 
dbo.branch2_service_items.Clinic, dbo.branch2_patients.[Full Name],
dbo.branch2_patients.DOB,
dbo.branch2_patients.[Street Address] + ' ' + dbo.branch2_patients.Suburb + ' ' + dbo.branch2_patients.State + ' ' + dbo.branch2_patients.Postcode AS Address,
sq_medicare.[Medicare Number],
sq_medicare.[Medicare Reference], 
sq_medicare.[Medicare Expiry], 
dbo.branch2_patients.[DRN WM],

case 
when datepart(year, [Date Charged]) >= 2021 then [2021]
else [2014]
end as [Fee]

FROM dbo.branch2_service_items 

--join patient information
LEFT OUTER JOIN dbo.branch2_patients 
ON dbo.branch2_service_items.[Ti Patient Id] = dbo.branch2_patients.[Ti Patient Id] 

--add medicare details from debtor tbl
LEFT OUTER JOIN 
(SELECT 
RecordNum AS [Ti Patient Id], 
CASE 
WHEN medicareNumber IS NULL OR len(medicarenumber) <> 11 THEN NULL 
ELSE LEFT(medicareNumber, 10)
END AS [Medicare Number], 
CASE 
WHEN medicareNumber IS NULL OR len(medicarenumber) <> 11 THEN NULL 
ELSE RIGHT(medicareNumber, 1) END AS [Medicare Reference], 
CASE WHEN dtmedicareexp IS NULL OR len(dtmedicareexp) = 0 THEN NULL 
ELSE CONVERT(date, dtmedicareexp, 23) 
END AS [Medicare Expiry]
FROM            dbo.DEBTOR4
WHERE        (Deleted = 0)) AS sq_medicare 
ON dbo.branch2_service_items.[Ti Patient Id] = sq_medicare.[Ti Patient Id] 

--trim down to only claimable items.
--new subquery will show fee schedules for both years.
INNER JOIN
(select * from 
(select 
	ItemCode [Service Item],
	datepart(year, ActiveDate) [Active Year],
	Fee  
from FeeScheduleFee
where FundingScheme = 'CDBS') cdbsschedule_qry

pivot
(min([Fee]) for [Active Year] in ([2014], [2021])) cdbsschedule_pv) AS sq_cdbsitems 
ON dbo.branch2_service_items.[Service Item] = sq_cdbsitems.[Service Item]

--take only cdbs items from the branch2 view.
--limitation here is for items that have been deleted through reversals.

WHERE (dbo.branch2_service_items.[Funding Scheme] = 'CDBS')
GO
CREATE VIEW dbo.branch2_appointments
AS
SELECT        dbo.APPT6.RecordNum AS [Ti Appointment Id], dbo.APPT6.ridPatient AS [Ti Patient Id], CONVERT(date, dbo.APPT6.dtDate, 203) AS [Appointment Date], CONVERT(varchar(5), dbo.APPT6.tmTime, 108) AS [Appointment Time], 
                         dbo.APPT6.uLength AS [Appointment Length], 
                         CASE WHEN wStatus = 1 THEN 'Booked' WHEN wStatus = 2 THEN 'Arrived' WHEN wStatus = 3 THEN 'Complete' WHEN wStatus = 5 THEN 'Seated' WHEN wStatus = 6 THEN 'Confirmed' WHEN wStatus = 7 THEN 'Cancelled' WHEN
                          wStatus = 8 THEN 'Deleted' ELSE '# value not expected' END AS [Appointment Status], dbo.APPT6.clinicCode AS Clinic, dbo.APPT6.room AS Chair, dbo.APPT6.dentist AS [Provider Id], dbo.APPT6.uidCOT AS [Ti Course of Care Id], 
                         dbo.branch2_notes.Comment AS [Appointment Comment], dbo.APPT6.ridLinkedWaitlistRecall AS [Ti WaitlistRecall Id]
FROM            dbo.APPT6 LEFT OUTER JOIN
                         dbo.branch2_notes ON dbo.APPT6.uidComment = dbo.branch2_notes.[Ti Comment Id]
WHERE        (dbo.APPT6.Deleted = 0)
GO
CREATE VIEW dbo.branch2_sms_reminder
AS
SELECT        Format(GETDATE(), 'yyyyMMdd') AS export_date, Format(GETDATE(), 'HHmm') AS export_time, LEFT(dbo.APPT6.RecordNum, 10) AS appt_id, CASE WHEN LEFT(cliniccode, 2) 
                         = 'MT' THEN 'Mount Druitt Community Dental Clinic' WHEN LEFT(cliniccode, 3) = 'BLK' THEN 'Blacktown Community Dental Clinic' ELSE 'Westmead Centre for Oral Health' END AS Hospital_Name, 
                         CASE WHEN appt6.wstatus IN (7, 8) 
                         THEN 'ANY' WHEN dbo.appt6.room = 'GPAD-22' THEN 'GPAD2' WHEN dbo.appt6.room = 'SCU-GAA' THEN 'OMEDSCU2' WHEN dbo.appt6.room LIKE 'LV1C%' THEN 'EMERGAD2' WHEN dbo.appt6.cliniccode = 'MTOS' THEN 'MTOH'
                          ELSE dbo.appt6.cliniccode END AS Clinic_code, '' AS Clinic_description, dbo.APPT6.room AS location, CASE WHEN appt6.wstatus IN (7, 8) 
                         THEN 'ANY' WHEN dbo.appt6.room = 'GPAD-22' THEN 'Assessment Clinic Level 1' WHEN dbo.appt6.room = 'SCU-GAA' THEN 'Special Care Consult Clinic Level 1' WHEN dbo.appt6.room LIKE 'LV1C%' THEN 'Extraction Clinic Level 1'
                          WHEN dbo.appt6.cliniccode = 'UNIGP-3' THEN 'University General Practice Level 1' ELSE dbo.clinic.description END AS Department, Format(dbo.APPT6.dtDate, 'yyyyMMdd') AS appointment_date, Format(dbo.APPT6.tmTime, 
                         'HHmm') AS appt_time, dbo.DENTIST4.name AS cmo, 'N' AS Interpreter, 'N' AS Resource_interpreter, 'N' AS opt_out, '' AS comments, CASE WHEN dbo.branch2_patients.[drn wm] IS NULL 
                         THEN '' ELSE dbo.branch2_patients.[drn wm] END AS mrn, CASE WHEN dbo.branch2_patients.[au id] IS NULL THEN '' ELSE dbo.branch2_patients.[au id] END AS auid, dbo.branch2_patients.Surname, 
                         dbo.branch2_patients.[First Name] AS Given_name, Format(dbo.branch2_patients.DOB, 'yyyyMMdd') AS dob, dbo.branch2_patients.[SMS Phone] AS phone, '' AS mobile, '' AS [2nd_phone], '' AS Other_phone, '' AS work_phone, 
                         '' AS email, '' AS home_address, '' AS state, '' AS pcode, '' AS suburb, '' AS [language spoken], CASE WHEN appt6.wstatus IN (7, 8) THEN 'Cancelled' ELSE 'Booked' END AS session_code, 'Titanium' AS souce_system
FROM            dbo.APPT6 LEFT OUTER JOIN
                         dbo.CLINIC ON dbo.APPT6.clinicCode = dbo.CLINIC.code AND dbo.CLINIC.Deleted = 0 LEFT OUTER JOIN
                         dbo.branch2_patients ON dbo.APPT6.ridPatient = dbo.branch2_patients.[Ti Patient Id] LEFT OUTER JOIN
                         dbo.DENTIST4 ON dbo.APPT6.dentist = dbo.DENTIST4.code AND dbo.DENTIST4.Deleted = 0
WHERE        (dbo.APPT6.dtDate >= CAST(GETDATE() AS date)) AND (dbo.APPT6.wStatus IN (7, 8)) AND (dbo.APPT6.clinicCode NOT IN ('CWGA', 'H&NECKMH', 'ORTHOEXT', 'PSMDP', 'SCUGA', 'MTAMS', 'MTMH', 'OMEDMH', 'OMFSGA', 
                         'PAEDSEXT', 'PAEDSWRD', 'SCUEXT', 'SCUMH', 'SCUWL')) AND (dbo.branch2_patients.DOD IS NULL) AND (dbo.branch2_patients.[SMS Phone] IS NOT NULL) AND (dbo.APPT6.room NOT IN ('EMG-T1', 'EMG-T2', 'EMG-T3', 'EMG-T4', 
                         'EMG-T5', 'EMG-T6', 'PAGA-1', 'PAGA-2', 'PAED-T1', 'PAED-T2', 'PAED-T3', 'PAED-T4', 'OMEDSCU-T1', 'MTOS-GA', 'TRIA-1')) AND (dbo.branch2_patients.[SMS Permission] = 1) AND (dbo.APPT6.Deleted = 0) AND 
                         (dbo.APPT6.CreatedDate <> DATEADD(day, - 1, CAST(GETDATE() AS date))) AND (dbo.APPT6.UpdatedDate = DATEADD(day, - 1, CAST(GETDATE() AS date))) OR
                         (dbo.APPT6.dtDate >= CAST(GETDATE() AS date)) AND (dbo.APPT6.wStatus NOT IN (7, 8)) AND (dbo.APPT6.clinicCode NOT IN ('CWGA', 'H&NECKMH', 'ORTHOEXT', 'PSMDP', 'SCUGA', 'MTAMS', 'MTMH', 'OMEDMH', 'OMFSGA', 
                         'PAEDSEXT', 'PAEDSWRD', 'SCUEXT', 'SCUMH', 'SCUWL')) AND (dbo.branch2_patients.DOD IS NULL) AND (dbo.branch2_patients.[SMS Phone] IS NOT NULL) AND (dbo.APPT6.room NOT IN ('EMG-T1', 'EMG-T2', 'EMG-T3', 'EMG-T4', 
                         'EMG-T5', 'EMG-T6', 'PAGA-1', 'PAGA-2', 'PAED-T1', 'PAED-T2', 'PAED-T3', 'PAED-T4', 'OMEDSCU-T1', 'MTOS-GA', 'TRIA-1')) AND (dbo.branch2_patients.[SMS Permission] = 1) AND (dbo.APPT6.Deleted = 0)
GO
CREATE VIEW dbo.branch2_waitlist
AS
SELECT        dbo.WAITLIST.RecordNum AS [Ti Waitlist Id], dbo.WAITLIST.waitlist AS Waitlist, dbo.WAITLIST.clinic AS Clinic, CONVERT(date, dbo.WAITLIST.dtListed, 203) AS [Date Listed], CONVERT(date, dbo.WAITLIST.dtAssigned, 203) 
                         AS [Date Assigned], CONVERT(date, dbo.WAITLIST.UpdatedDate, 203) AS [Date Last Updated], 
                         CASE WHEN waitlist.wStatus = 0 THEN 'Waiting' WHEN waitlist.wStatus = 1 THEN 'Active' WHEN waitlist.wStatus = 2 THEN 'Complete' WHEN waitlist.wStatus = 3 THEN 'Deleted/Purged' WHEN waitlist.wStatus = 4 THEN 'Deferred'
                          WHEN waitlist.wStatus = 5 THEN 'Transfer' WHEN waitlist.wStatus = 6 THEN 'Ready' WHEN waitlist.wStatus = 7 THEN 'Booked' WHEN waitlist.wStatus = 8 THEN 'Transferred to another clinic – DHSV' WHEN waitlist.wStatus = 9 THEN
                          'Suspended – DHSV' WHEN waitlist.wStatus = 999 THEN 'All' WHEN waitlist.wStatus = 10 THEN 'Contacted' WHEN waitlist.wStatus = - 1 THEN 'Undefined' END AS [Waitlist Status], 
                         CASE WHEN dbo.WAITLIST.description = ' ' THEN '' ELSE dbo.WAITLIST.description END AS [Sub Class 1], CASE WHEN dbo.WAITLIST.[2ndSubClass] = ' ' THEN '' ELSE dbo.WAITLIST.[2ndSubClass] END AS [Sub Class 2], 
                         CASE WHEN dbo.WAITLIST.description = '1' AND Waitlist IN ('Assessment Adult', 'Assessment Child') THEN 1 WHEN dbo.WAITLIST.description = '2' AND Waitlist IN ('Assessment Adult', 'Assessment Child') 
                         THEN 3 WHEN dbo.WAITLIST.description = '3a' AND Waitlist IN ('Assessment Adult', 'Assessment Child') THEN 7 WHEN dbo.WAITLIST.description = '3b' AND Waitlist IN ('Assessment Adult', 'Assessment Child') 
                         THEN 30 WHEN dbo.WAITLIST.description = '3c' AND Waitlist IN ('Assessment Adult', 'Assessment Child') THEN 90 WHEN dbo.WAITLIST.description = '4' AND Waitlist IN ('Assessment Adult', 'Assessment Child') 
                         THEN 180 WHEN dbo.WAITLIST.description = '5' AND Waitlist IN ('Assessment Adult', 'Assessment Child') THEN 360 WHEN dbo.WAITLIST.description = '6' AND Waitlist IN ('Assessment Adult', 'Assessment Child') 
                         THEN 720 WHEN dbo.WAITLIST.description = 'A' AND Waitlist = 'Treatment Adult' THEN 14 WHEN dbo.WAITLIST.description = 'B' AND Waitlist = 'Treatment Adult' THEN 90 WHEN dbo.WAITLIST.description = 'C' AND 
                         Waitlist = 'Treatment Adult' THEN 180 WHEN dbo.WAITLIST.description = 'D' AND Waitlist = 'Treatment Adult' THEN 270 WHEN dbo.WAITLIST.description = 'E' AND 
                         Waitlist = 'Treatment Adult' THEN 365 WHEN dbo.WAITLIST.description = 'F' AND Waitlist = 'Treatment Adult' THEN 720 WHEN dbo.WAITLIST.description = 'A' AND 
                         Waitlist = 'Treatment Child' THEN 14 WHEN dbo.WAITLIST.description = 'B' AND Waitlist = 'Treatment Child' THEN 90 WHEN dbo.WAITLIST.description = 'C' AND 
                         Waitlist = 'Treatment Child' THEN 180 WHEN dbo.WAITLIST.description = 'D' AND 
                         Waitlist = 'Treatment Child' THEN 365 WHEN dbo.WAITLIST.description = 'X' THEN 30 WHEN dbo.WAITLIST.description = 'Y' THEN 90 WHEN dbo.WAITLIST.description = 'Z' THEN 365 WHEN dbo.WAITLIST.description = '1' THEN
                          7 WHEN dbo.WAITLIST.description = '2' THEN 30 WHEN dbo.WAITLIST.description = '3' THEN 90 WHEN dbo.WAITLIST.description = '4' THEN 365 WHEN [2ndSubClass] = 'X' THEN 30 WHEN [2ndSubClass] = 'Y' THEN 90 WHEN
                          [2ndSubClass] = 'Z' THEN 365 WHEN [2ndSubClass] = '1' THEN 7 WHEN [2ndSubClass] = '2' THEN 30 WHEN [2ndSubClass] = '3' THEN 90 WHEN [2ndSubClass] = '4' THEN 365 ELSE NULL END AS [POHP Benchmark Days], 
                         dbo.branch2_waitlist_suitability.[Suitability Note], dbo.branch2_waitlist_treatmentneeds.[Treatment Needs], dbo.branch2_notes.Comment, dbo.WAITLIST.ridPatient AS [Ti Patient Id]
FROM            dbo.WAITLIST LEFT OUTER JOIN
                         dbo.branch2_notes ON dbo.WAITLIST.uidNotes = dbo.branch2_notes.[Ti Comment Id] LEFT OUTER JOIN
                         dbo.branch2_waitlist_suitability ON dbo.WAITLIST.RecordNum = dbo.branch2_waitlist_suitability.[Ti Waitlist Id] LEFT OUTER JOIN
                         dbo.branch2_waitlist_treatmentneeds ON dbo.WAITLIST.RecordNum = dbo.branch2_waitlist_treatmentneeds.[Ti Waitlist Id]
WHERE        (dbo.WAITLIST.Deleted = 0)
GO
CREATE VIEW dbo.branch2_missing_items
AS
SELECT        dbo.branch2_patients.[DRN WM], dbo.branch2_patients.[Full Name], dbo.branch2_patients.DOB, dbo.branch2_appointments.[Ti Patient Id], dbo.branch2_appointments.[Ti Appointment Id], dbo.branch2_appointments.[Appointment Date], 
                         dbo.branch2_appointments.[Appointment Time], dbo.branch2_appointments.Clinic, dbo.branch2_appointments.[Provider Id], dbo.branch2_appointments.[Appointment Status], sq_clinicitem.Items AS [Clinic Items], 
                         sq_item.Items AS [Other Clinic Items]
FROM            dbo.branch2_appointments LEFT OUTER JOIN
                             (SELECT        [Ti Patient Id], clinic AS Clinic, [Date Completed], COUNT(*) AS Items
                               FROM            dbo.branch2_service_items
                               WHERE        (LEN([Date Completed]) > 0)
                               GROUP BY [Ti Patient Id], clinic, [Date Completed]) AS sq_clinicitem ON dbo.branch2_appointments.[Ti Patient Id] = sq_clinicitem.[Ti Patient Id] AND dbo.branch2_appointments.Clinic = sq_clinicitem.Clinic AND 
                         dbo.branch2_appointments.[Appointment Date] = sq_clinicitem.[Date Completed] LEFT OUTER JOIN
                             (SELECT        [Ti Patient Id], [Date Completed], COUNT(*) AS Items
                               FROM            dbo.branch2_service_items AS branch2_service_items_1
                               WHERE        (LEN([Date Completed]) > 0)
                               GROUP BY [Ti Patient Id], [Date Completed]) AS sq_item ON dbo.branch2_appointments.[Ti Patient Id] = sq_item.[Ti Patient Id] AND dbo.branch2_appointments.[Appointment Date] = sq_item.[Date Completed] LEFT OUTER JOIN
                         dbo.branch2_patients ON dbo.branch2_appointments.[Ti Patient Id] = dbo.branch2_patients.[Ti Patient Id]
WHERE        (dbo.branch2_appointments.[Appointment Status] NOT IN ('Deleted', 'Cancelled', 'Booked', 'Confirmed')) AND (sq_clinicitem.Items IS NULL)
GO
