component accessors=true {

	/**
	 * The key for the university id. Defaults to "University ID"
	 */
	property string universityIdKey;
	/**
	 * The key for the associated id if a Systems Information section is present. Defaults to "Associated ID"
	 */
	property string associatedIdKey;
	/**
	 * The key for the institutional id if a Systems Information section is present. Defaults to "Institution ID"
	 */
	property string institutionalIdKey;
	/**
	 * The key for the data if a Systems Information section is present. Defaults to "Data"
	 */
	property string dataKey;

	public DataTransferConfig function init() {
		setUniversityIdKey("University ID");
		setAssociatedIdKey("Associated ID");
		setInstitutionalIdKey("Institution ID");
		setDataKey("Data");
		return this;
	}

}
