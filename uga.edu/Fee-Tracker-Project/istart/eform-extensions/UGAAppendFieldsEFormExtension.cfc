/**
 * UGA eform extension that appends the jbEform recnum as the fee id and the sunapsis idnumber
 * Used for the Immi Fee Tracker
 */
component extends="istart.core.EFormExtension" {
	/**
	 * appends the sunapsis idnumber so it can be used with templates
	 */
	public void function appendFormData(
		required istart.core.Identifier identifier, 
		required istart.core.FormAction action, 
		required istart.core.FormObject formObject
	) {
		
		formObject.addElement("appendFeeID", "InvoiceNumber", "textfield");
		formObject.addElement("appendIDNumber", "Visitor ID Number", "textfield");
		
		formObject.getElement("appendIDNumber").setValue(identifier.getIDNumber());	
	}
	/**
	 * populates the value for eform appendedField 'Fee ID Number' with the recnum (fee id) so it can be used with templates
	 */
	public void function cleanup(
		required istart.core.Identifier identifier,
		required istart.core.FormAction action,
		required istart.core.FormObject formObject,
		required string serviceID,
		required string eformTitle,
		required istart.core.ActionResponse response
	) {
		if( formObject.getElement("recnum").getValue() > 0 )
		{
			var submittedEform = QueryExecute(
				"SELECT recnum,data FROM jbEForm WHERE recnum = :recnum1",
				{recnum1: {cfsqltype: "integer", value:formObject.getElement("recnum").getValue()}}
			);
			var eformDataXML = XMLParse(submittedEform.data);
			var pointerToElement = XmlSearch(eformDataXML, "/data/dataObject/datums/datum[@key='appendFeeID']/value");
			
			if( ArrayIsDefined(pointerToElement, 1) )
			{
				pointerToElement[1].xmlText = submittedEform.recnum;
				
				QueryExecute(
					"UPDATE jbEform SET data = :eformXML WHERE recnum = :eform",
					{
					eformXML:{cfsqltype: "nvarchar", value:eformDataXML },
					eform:{cfsqltype: "integer", value:submittedEform.recnum}
					}
				);
			}
		}
	}
}