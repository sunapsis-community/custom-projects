/**
 * A container for incoming Data Transfer API requests
 */
component {

	property string transaction;
	property string eventType;
	property string universityID;
	property string associatedID;
	property string institutionalID;
	property struct data;

	/**
	 * Poplates the properties on the DataPacket from the incoming Data Transfer API request JSON
	 *
	 * @json The JSON from the Data Transfer API request
	 * @configs The configurations describing the exected incoming JSON
	 */
	public DataPacket function init(required string json, DataTransferConfig configs=new DataTransferConfig()) {
		populateDataPacket(json, configs);
		return this;
	}

	private void function populateDataPacket(
		required string json,
		required DataTransferConfig configs
	) {
		setTransaction("");
		setEventType("");
		setUniversityID("");
		setData({});

		if( IsJSON(json) ) {
			var dataStruct = DeserializeJSON(json);
			if( IsStruct(dataStruct) ) {
				if( dataStruct.keyExists("Systems Information") && IsStruct(dataStruct["Systems Information"]) ) {
					var sysInfo = dataStruct["Systems Information"];
					if( sysInfo.keyExists("Transaction Type") ) {
						setTransaction(sysInfo["Transaction Type"]);
					}
					if( sysInfo.keyExists("SQL Event Type") ) {
						setEventType(sysInfo["SQL Event Type"]);
					}
					if( sysInfo.keyExists(configs.getUniversityIdKey()) ) {
						setUniversityID(sysInfo[configs.getUniversityIdKey()]);
					}
					if( sysInfo.keyExists(configs.getAssociatedIdKey()) ) {
						setAssociatedID(sysInfo[configs.getAssociatedIdKey()]);
					}
					if( sysInfo.keyExists(configs.getInstitutionalIdKey()) ) {
						setInstitutionalID(sysInfo[configs.getInstitutionalIdKey()]);
					}
					if( dataStruct.keyExists(configs.getDataKey()) && IsStruct(dataStruct[configs.getDataKey()]) ) {
						setData(dataStruct[configs.getDataKey()]);
					}

					return;
				}
				else {
					if( dataStruct.keyExists(configs.getUniversityIdKey()) ) {
						setUniversityID(dataStruct[configs.getUniversityIdKey()]);
						StructDelete(dataStruct, configs.getUniversityIdKey());
					}
					setData(dataStruct);
				}
			}
		}
	}

	private void function setTransaction(required string transaction) {
		variables.transaction = transaction;
	}

	private void function setEventType(required string eventType) {
		variables.eventType = eventType;
	}

	public void function setUniversityID(required string universityID) {
		variables.universityID = universityID;
	}

	private void function setAssociatedID(required string associatedID) {
		variables.associatedID = associatedID;
	}

	private void function setInstitutionalID(required string institutionalID) {
		variables.institutionalID = institutionalID;
	}

	private void function setData(required struct data) {
		variables.data = data;
	}

	/**
	 * returns the Transaction Type (systemInfoTypeCode) from the Data Transfer API request
	 */
	public string function getTransaction() {
		return variables.transaction;
	}

	/**
	 * returns the SQL event (INSERT, UPDATE, DELETE) that triggered the Data Transfer API request.
	 * Only included if Include Event Type (systemInfoRequireSQLEventType) is checked in the configs
	 */
	public string function getEventType() {
		return variables.eventType;
	}

	/**
	 * returns the University ID.
	 */
	public string function getUniversityID() {
		return variables.universityID;
	}

	/**
	 * returns the Associated ID.
	 */
	public string function getAssociatedID() {
		return variables.associatedID;
	}

	/**
	 * returns the Institutional ID.
	 */
	public string function getInstitutionalID() {
		return variables.institutionalID;
	}

	/**
	 * returns the data.
	 */
	public struct function getData() {
		return variables.data;
	}

	/**
	 * Checks that all the liststed required fields exist
	 *
	 * Throws MissingRequiredFieldException if one is missing
	 *
	 * @requiredFieldList a comma-separated list of field names to require
	 */
	public void function validateRequiredFields(required string requiredFieldList) {
		for( var field in requiredFieldList ) {
			if( fieldExists(field) ) { }
			else {
				Throw("Missing required field: " & field, "MissingRequiredFieldException", "Existing data: " & SerializeJSON(getData()));
			}
		}
	}

	private boolean function fieldExists(required string fieldName) {
		return getData().keyExists(fieldName)
			&& (!IsValid("string", getData()[fieldName])
				|| Len(Trim(getData()[fieldName])) > 0
			);
	}

	/**
	 * returns true if the given field exists
	 *
	 * @fieldName a field to check for
	 */
	public boolean function hasOptionalField(required string fieldName) {
		return fieldExists(fieldName);
	}

}
