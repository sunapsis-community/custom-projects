/**  TITLE:UGA ISCF is due alert

ADAPT-70 Issue
This alert looks at active J-1 Scholars to send an ISCF is due alert. Alerts levels will be used to send past due reminders.

This alert will operate on the New Immi Fee Tracker table. If the ISCF due date is after yesterday and the fee
status is 'has been processed'
*/
component extends="AbstractSimpleAlert" {

	public AlertType function getAlertType() {
	
		
		var alertType = new AlertType();
		
		alertType.setServiceID(getImplementedServiceID());
		alertType.setAlertName(getServiceLabelType() & "UGA Recurring ISCF Fee Alert");
		alertType.setAlertDescription("UGA alert for the J-1 Scholar ISCF fee is due");
		alertType.setLevelDescription("Low and Guarded Status Only (UGA)");
		alertType.setOverride(true);
		
		return alertType;
	}

	public string function getQueryString() {
		new istart.core.ErrorLogger().logMessage("ISCF Reminder", "getQueryString", "" ,"");
		var db_query =  "SELECT
							jbInternational.idnumber
							, jbInternational.sevisid
							, jbInternational.campus
							, 5 AS threatLevel
							, 'ISCF 50+ is due' AS alertMessage

						FROM
							dbo.jbInternational
							INNER JOIN dbo.jbCustomFields9
								ON jbCustomFields9.idnumber = jbInternational.idnumber
									AND customField2 like 'ISCF J-1 Scholar 50+'
									AND customField18 IS NULL
									AND customField5 IN ('YesBill')
									AND CAST(customField12 as DATE) < GETDATE()+7
							INNER JOIN dbo.sevisDS2019Program
								ON jbInternational.sevisid = sevisDS2019Program.sevisid
								AND
								sevisDS2019Program.status IN ('A', 'I')
								AND
								sevisDS2019Program.prgEndDate > (GETDATE()+1)
							WHERE
								customField12 >= '2025-03-01'

						UNION

						SELECT
							jbInternational.idnumber
							, jbInternational.sevisid
							, jbInternational.campus
							, 4 AS threatLevel
							, 'ISCF 50- is due' AS alertMessage

						FROM
							dbo.jbInternational
							INNER JOIN dbo.jbCustomFields9
								ON jbCustomFields9.idnumber = jbInternational.idnumber
									AND customField2 like 'ISCF J-1 Scholar 50-'
									AND customField18 IS NULL
									AND customField5 IN ('YesBill')
									AND CAST(customField12 as DATE) < GETDATE()+7
							INNER JOIN dbo.sevisDS2019Program
								ON jbInternational.sevisid = sevisDS2019Program.sevisid
								AND
								sevisDS2019Program.status IN ('A', 'I') 
								AND
								sevisDS2019Program.prgEndDate > (GETDATE()+1)
							WHERE
								customField12 >= '2025-03-01'
		";
		
		return db_query;
    }

	public boolean function isSEVISAlert() {
		//new istart.core.ErrorLogger().logMessage("ISCF Due Alert Test - sevisalert", "fee name", "micah" ,"another column");
		return false;
	}
}
