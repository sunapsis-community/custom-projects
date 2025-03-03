/**
Logic for checking when a one-time fee is ready to be billed
**/

DECLARE
@trackerID AS INTEGER,
@invoiceNumber AS INTEGER,
@invoiceStatus AS NVARCHAR(100),
@blockingEformStatus AS NVARCHAR(100)

DECLARE fees cursor for
(
	/**** EFORMS THAT HAVE AN EGROUP and a blocking e-form  ****/
	SELECT
		[Fee Row].recnum [tracker id],
		[Fee Row].customField4 [invoice number],
		[Fee Row].customField5 [fee status],
		invoiceStatus.status [blocking eform status]
	FROM
		jbCustomFields9 [Fee Row]
		INNER JOIN jbEForm invoiceNumber ON invoiceNumber.recnum = [Fee Row].customField4
		INNER JOIN mapUGAFeeFields feeInfo ON feeInfo.invoiceNumberServiceID = invoiceNumber.serviceID
		INNER JOIN jbEForm invoiceStatus 
			ON invoiceStatus.idnumber=[Fee Row].idnumber 
			AND invoiceStatus.serviceID=feeInfo.invoiceStatusServiceID
			AND invoiceNumber.eformGroup = invoiceStatus.eformGroup
			AND invoiceNumber.eformGroup not in (0)
		INNER JOIN [jbEFormActionLog] ON [jbEFormActionLog].eform = invoiceNumber.recnum
	WHERE
		[Fee Row].customField5 NOT IN ('YesBill','PaidBill')
		AND
		--FIND THE LATEST EFORM ACTION FOR THE STATUS
		NOT EXISTS (select * from [jbEFormActionLog] limiter where limiter.datestamp<[jbEFormActionLog].datestamp AND limiter.eform = invoiceNumber.recnum)

	UNION 

	/**** EFORMS THAT DO NOT HAVE AN EGROUP  (INVOICE NUMBER AND INVOICE STATUS ARE THE SAME EFORM, EGROUP=0)****/
	SELECT
		[Fee Row].recnum [tracker id],
		[Fee Row].customField4 [invoice number],
		[Fee Row].customField5 [fee status],
		invoiceNumber.status [blocking eform status]

	FROM
		jbCustomFields9 [Fee Row]
		INNER JOIN jbEForm invoiceNumber ON invoiceNumber.recnum = [Fee Row].customField4
		INNER JOIN mapUGAFeeFields feeInfo ON
			feeInfo.invoiceNumberServiceID = invoiceNumber.serviceID
			AND invoiceNumber.eformGroup in (0)
		INNER JOIN [jbEFormActionLog] ON [jbEFormActionLog].eform = invoiceNumber.recnum
	WHERE
		[Fee Row].customField5 NOT IN ('YesBill','PaidBill')
		AND
		--FIND THE LATEST FORM ACTION FOR THE STATUS
		NOT EXISTS (select * from [jbEFormActionLog] limiter where limiter.datestamp<[jbEFormActionLog].datestamp AND limiter.eform = invoiceNumber.recnum)

	UNION 

	/**** PR Fees that get Second Approved by Robin, user jbEform approverSigned field ****/
	SELECT
		[Fee Row].recnum [tracker id],
		[Fee Row].customField4 [invoice number],
		[Fee Row].customField5 [fee status],
		'Approved' as [blocking eform status]

	FROM
		jbCustomFields9 [Fee Row]
		INNER JOIN jbEForm invoiceNumber ON
			invoiceNumber.recnum = [Fee Row].customField4
			and invoiceNumber.approverSigned = 1
		INNER JOIN mapUGAFeeFields feeInfo ON
			feeInfo.invoiceNumberServiceID = invoiceNumber.serviceID 
			AND feeInfo.invoiceStatusServiceID='secondApprover'
		INNER JOIN [jbEFormActionLog] ON [jbEFormActionLog].eform = invoiceNumber.recnum
	WHERE
		[Fee Row].customField5 NOT IN ('YesBill','PaidBill')
		AND
		--FIND THE LATEST FORM ACTION FOR THE STATUS
		NOT EXISTS (select * from [jbEFormActionLog] limiter where limiter.datestamp<[jbEFormActionLog].datestamp AND limiter.eform = invoiceNumber.recnum)
)

OPEN fees
	FETCH NEXT FROM fees INTO @trackerID,@invoiceNumber, @invoiceStatus ,@blockingEformStatus
	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE jbcustomFields9
		SET customField5 = 'YesBill', customField12=FORMAT(GETDATE(),'yyyy-MM-dd'), datestamp=GETDATE()
		WHERE jbCustomFields9.recnum = @trackerID AND @blockingEformStatus = 'Approved'
		FETCH NEXT FROM fees INTO @trackerID,@invoiceNumber, @invoiceStatus ,@blockingEformStatus
	END
	CLOSE fees  
DEALLOCATE fees