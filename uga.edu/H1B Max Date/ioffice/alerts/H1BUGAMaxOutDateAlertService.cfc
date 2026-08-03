/** H1B Max Out Date Alert - within 2 years
IMMI-43 Issue

The H-1B Initial template will pull in the date entered by the user into the new Max Out field. 

If you are transferring your H status to UGA, this is your original H-1B start date plus 6 years

If this is your first H petition, this is the date you will begin your H-1B employment here at UGA plus 6 years

*/
component extends="AbstractSimpleAlert" {

	public AlertType function getAlertType() {
		var alertType = new AlertType();
		alertType.setServiceID(getImplementedServiceID());
		alertType.setAlertName(getServiceLabelType() & "Maximum Employment Time Expiring (UGA)");
		alertType.setAlertDescription("H1B Maximum Time Allowed Alert (UGA)");
		alertType.setLevelDescription("Low and High Statuses Only (UGA)");	
		alertType.setOverride(true);
		return alertType;
	}

	public string function getQueryString() {
		return "
			SELECT
				employeeList.*
				,1 AS threatlevel
				,'Within 1 year of time allowed for H1B employment (UGA).' as alertMessage
			FROM
			(
				SELECT DISTINCT
					person.idnumber
					,employment.billingStartDate AS [Max Out Date]
					,person.campus
				FROM 
					jbEmployeeH1BInfo employment --Employment Summary
					INNER JOIN jbInternational person ON person.idnumber = employment.idnumber
					RIGHT OUTER JOIN iuieEmployee employeeDatafeed on employeeDatafeed.idnumber=employment.idnumber
					RIGHT OUTER JOIN jbEmployeeAppointment [authorization] ON person.idnumber = [authorization].idnumber --Appointment Information
				WHERE
					employeeDatafeed.EMP_STAT_CD in ('A') AND person.immigrationStatus in ('H1B')
			) employeeList
					
			WHERE 
				employeeList.[Max Out Date] > DATEADD(DAY, -30, GETDATE()) AND employeeList.[Max Out Date] < DATEADD(YEAR, 1, GETDATE())

			UNION

			SELECT
				employeeList.*
				,2 AS threatlevel
				,'Within 2 years of time allowed for H1B employment (UGA).' as alertMessage
			FROM
			(
				SELECT DISTINCT
					person.idnumber
					,employment.billingStartDate AS [Max Out Date]
					,person.campus
				FROM 
					jbEmployeeH1BInfo employment --Employment Summary
					INNER JOIN jbInternational person ON person.idnumber = employment.idnumber
					RIGHT OUTER JOIN iuieEmployee employeeDatafeed on employeeDatafeed.idnumber=employment.idnumber
					RIGHT OUTER JOIN jbEmployeeAppointment [authorization] ON person.idnumber = [authorization].idnumber --Appointment Information
				WHERE
					employeeDatafeed.EMP_STAT_CD in ('A') AND person.immigrationStatus in ('H1B')
			) employeeList
					
			WHERE 
				employeeList.[Max Out Date] > DATEADD(YEAR, 1, GETDATE()) AND employeeList.[Max Out Date] < DATEADD(YEAR, 2, GETDATE())
			"
    }

	public boolean function isSEVISAlert() {
		return false;
	}

}