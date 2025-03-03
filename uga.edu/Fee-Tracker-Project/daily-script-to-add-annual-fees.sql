/** 
** PROD
**Logic to add annual fees for J1 Scholars
**/
DECLARE @currentDayPlus7 nvarchar(max) = FORMAT(getDATE()+7, 'MM-dd')
DECLARE @idnumber INT, @feeName nvarchar(100), @feeAmount nvarchar(100), @dueDate nvarchar(100)

DECLARE newFees CURSOR FOR
(
	SELECT
		programDetails.idnumber, programDetails.feeName, programDetails.feeAmount
	FROM
		(
		/**J-1 SCHOLARS WITH 50% OR MORE FUNDING FROM UGA**/
			SELECT jbinternational.idnumber,prgStartDate as [start date], prgEndDate as [end date], [status], categoryCode,mapUGAFeeFields.feeAmount, mapUGAFeeFields.feeName
			FROM jbinternational
				INNER JOIN sevisDS2019Program ON sevisDS2019Program.idnumber = jbInternational.idnumber
				INNER JOIN mapUGAFeeFields ON mapUGAFeeFields.feeName = 'ISCF J-1 Scholar 50+'
				INNER JOIN jbUGAFields ON jbUGAFields.idnumber = jbInternational.idnumber AND jbUGAFields.fundingLevel = 'UGA50+'
		UNION
		/**J-1 SCHOLAR WITH LESS THAN 50% FUNDING FROM UGA**/
			SELECT jbinternational.idnumber,prgStartDate as [start date], prgEndDate as [end date], [status], categoryCode,mapUGAFeeFields.feeAmount, mapUGAFeeFields.feeName
			FROM jbinternational
				INNER JOIN sevisDS2019Program ON sevisDS2019Program.idnumber = jbInternational.idnumber
				INNER JOIN mapUGAFeeFields ON mapUGAFeeFields.feeName = 'ISCF J-1 Scholar 50-'
				INNER JOIN jbUGAFields ON jbUGAFields.idnumber = jbInternational.idnumber AND jbUGAFields.fundingLevel = 'UGA50-'
		) programDetails
	WHERE
		format(programDetails.[start date],'MM-dd') = @currentDayPlus7
		AND
		programDetails.[end date] >= GETDATE()
		AND
		programDetails.status IN ('A','I')
		AND
		categoryCode NOT IN ('1A','1B','1C','1D','1E','1F')
)


OPEN newFees
	FETCH NEXT FROM newFees INTO @idnumber, @feeName, @feeAmount
	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRANSACTION
			IF NOT EXISTS(SELECT 0 FROM jbCustomFields9 WHERE idnumber=@idnumber AND customField12=format(getDate(),'yyyy-MM-dd'))
				INSERT INTO jbCustomfields9 
				( idnumber,customField2,customField5,customField6,customField8,customField12,customField14,datestamp )
				VALUES 
				( @idnumber,@feeName,'YesBill',@idnumber,@feeAmount,@currentDayPlus7,'Scholar', GETDATE())
		COMMIT TRANSACTION
	FETCH NEXT FROM newFees INTO @idnumber, @feeName, @feeAmount
	END
	CLOSE newFees  
DEALLOCATE newFees
