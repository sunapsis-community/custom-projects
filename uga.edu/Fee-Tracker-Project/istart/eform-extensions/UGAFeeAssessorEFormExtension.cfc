/**
 * UGA eform extension for adding NEW Fee Tracker rows
 */
component extends="istart.core.EFormExtension" {
	Variables.debug = false;
	/**
	 * cleanup
	 */
	public void function cleanup(
		required istart.core.Identifier identifier,
		required istart.core.FormAction action,
		required istart.core.FormObject formObject,
		required string serviceID,
		required string eformTitle,
		required istart.core.ActionResponse response
	) {
		assessImmiFee(formObject);
	}
	
	/**
	 * assessImmiFee
	 */
	private void function assessImmiFee(required istart.core.FormObject formObject)
	{
		var unknownEform = QueryExecute(
			"SELECT jbEForm.recnum as [invoiceNumber],jbEForm.idnumber,IStartEForms.metaInfo,jbEform.serviceID,FORMAT(createDate,'yyyy-MM-dd') as dateAdded, mapUGAFeeFields.feeName
			FROM jbEForm,IStartEForms,mapUGAFeeFields
			WHERE jbEForm.serviceID=IStartEForms.serviceID AND jbEForm.serviceID=mapUGAFeeFields.invoiceNumberServiceID AND jbEForm.recnum = :eform",
			{
				eform:{cfsqltype: "integer", value:formObject.getElement("recnum").getValue()}
			}
		);
		var feeExists = duplicateFeeChecker(unknownEform.feeName, unknownEform.idnumber, unknownEform.invoiceNumber, unknownEform.dateAdded);
	
		if( feeExists == 0 )
		{
			var feeField = QueryExecute(
				"SELECT top 1 * FROM mapUGAFeeFields where mapUGAFeeFields.invoiceNumberServiceID = :serviceID",
				{serviceID: {cfsqltype: "nvarchar", value:unknownEform.serviceID}}
			);
	
			//suggestedDueDate = calculateDueDate(feeField.toBePaidBy, unknownEform.idnumber, unknownEform.invoiceNumber);
			
			QueryExecute(
				"INSERT INTO jbCustomFields9 
				(idnumber,customField2,customField4,customField5,customField6,customField8,customField10,customField12,customField14,customField22,datestamp)
				VALUES
				(:idnumber,:feeName,:invoiceNumber,:invoiceStatus,:idnumber,:feeAmount,:eformFeeAmount,:suggestedDueDate,:toBePaidBy,:speedType,GETDATE())",
				{ 
					idnumber:{cfsqltype: 			"integer",  value:unknownEform.idnumber},
					feeName:{cfsqltype: 			"nvarchar", value:feeField.feeName},
					invoiceNumber:{cfsqltype: 		"integer",  value:unknownEform.invoiceNumber},
					invoiceStatus:{cfsqltype: 		"nvarchar", value:"NoBill"},
					feeAmount:{cfsqltype: 			"nvarchar", value:feeField.feeAmount},
					eformFeeAmount:{cfsqltype: 		"nvarchar", value:formObject.getElement(feeField.feeFieldID).getValue()},
					suggestedDueDate:{cfsqltype: 	"nvarchar", value:"2079-06-06"},
					toBePaidBy:{cfsqltype: 			"nvarchar", value:feeField.toBePaidBy},
					speedtype:{cfsqltype: 			"nvarchar", value:formObject.getElement(feeField.speedtype).getValue()}
				}
			);
		}
	}
	
	/**
	 * verifies the submitted data
	 */
	public boolean function verifyFormActionResponse(
		required istart.core.Identifier identifier,
		required istart.core.FormAction action,
		required istart.core.FormObject formObject,
		required istart.core.ActionResponse response
	) {
		return true;
	}
	
	/**
	 * calculateDueDate
	 */
	private string function calculateDueDate(
		required string category,
		required integer personID,
		required integer invoiceNumber
	){
		dueDate = QueryExecute(
			"SELECT TOP 1 format(createDate,'yyyy-MM-dd') as createDate FROM jbEform where jbEform.recnum = :feeID",
			{feeID: {cfsqltype: "integer", value:invoiceNumber}}
		);
		return dueDate.createDate;
	}
	
	/**
	 * duplicateFeeChecker
	 */
	private numeric function duplicateFeeChecker(
		required string feeName,
		required integer personID,
		required integer invoiceNumber,
		required string newDate
	){
		/**Check Invoice ID**/
		var duplicateInvoice = QueryExecute(
			"SELECT count(recnum) as count FROM jbCustomFields9 
			WHERE customField4=:invoiceNo",
			{ invoiceNo:{cfsqltype: "integer", value:invoiceNumber} }
		);
		
		/**Reasonable amount of time check to allow same fee**/
		var duplicateService = QueryExecute(
			"SELECT
				count(recnum) as count
			FROM
				jbCustomFields9 
			WHERE
				customField2=:feeName 
				AND jbCustomFields9.idnumber=:idnumber
				AND ( DATEDIFF(DAY,jbCustomFields9.customField12,:newDate)<30 )",
			{ feeName:{cfsqltype: "nvarchar", value:feeName},
			  idnumber:{cfsqltype: "integer", value:personID},
			  newDate:{cfsqltype: "nvarchar", value:newDate}
			}
		);
		if(Variables.debug)
		{
			new istart.core.ErrorLogger().logMessage("AssessImmiFee", "fee name", "micah" ,feeName);
			new istart.core.ErrorLogger().logMessage("AssessImmiFee", "invoice number", "micah" ,invoiceNumber);
			new istart.core.ErrorLogger().logMessage("AssessImmiFee", "duplicateInvoice", "micah" ,duplicateInvoice.count);
			new istart.core.ErrorLogger().logMessage("AssessImmiFee", "duplicateService", "micah" ,duplicateService.count);
		}
		
		return duplicateInvoice.count + duplicateService.count;
	}
}