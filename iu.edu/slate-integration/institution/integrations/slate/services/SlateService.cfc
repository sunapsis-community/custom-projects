import institution.integrations.dataTransfer.*;
import istart.core.EncryptionHandler;

component implements="institution.integrations.dataTransfer.ExternalService" {

	property string endpoint;
	property string username;
	property string apiKey;
	property string certificateURL;
	property DataPacket packet;

	public void function initialize(required DataPacket data) {
		variables.packet = data;
		variables.endpoint = "";
		variables.username = "";
		variables.apiKey = "";

		if( getPacket().getData().keyExists("status") && getPacket().getData()["status"] != "I" ) {
			Throw("This student is not in Initial Status", "UnnecessarySubmitException");
		}

		if( getPacket().getData().keyExists("sevisid") && getPacket().getData()["sevisid"].len() == 0 ) {
			Throw("This student doesn't have a document yet", "UnnecessarySubmitException");
		}

		if( getPacket().getData().keyExists("app_nbr") ) {
			var lookupConfigs = QueryExecute(
				"SELECT
					configIntegrations.recnum,
					configIntegrations.endPoint,
					configIntegrations.username,
					configIntegrations.password AS apiKey
				FROM dbo.iuieAdmissions
				INNER JOIN dbo.configIntegrations
					ON configIntegrations.campus IN (N'ALL', iuieAdmissions.INST_CD)
					AND configIntegrations.name = N'Slate'
				WHERE iuieAdmissions.APPL_NBR = :appNumber;",
				{ appNumber: {cfsqltype: "varchar", value: data.getData()["app_nbr"]} }
			);

			if( lookupConfigs.recordCount > 0 ) {
				variables.endpoint = lookupConfigs.endpoint;
				variables.username = lookupConfigs.username;
				variables.apiKey = new EncryptionHandler()
					.decryptField(lookupConfigs.apiKey, "configIntegrations", lookupConfigs.recnum)
					.getString();
			}
		}
	}

	private DataPacket function getPacket() {
		return variables.packet;
	}

	public string function getEndPoint() {
		return variables.endpoint;
	}

	public string function getUsername() {
		return variables.username;
	}

	public string function getAPIKey() {
		return variables.apiKey;
	}

	public string function getAction() {
		return "post";
	}

	public array function getFormattedData() {
		return [formatData()];
	}


	private string function formatData() {
		return SerializeJSON(
			data: {
				"uid": getPacket().getUniversityID(),
				"app_nbr": getPacket().getData()["app_nbr"],
				"hasSEVISdoc": getPacket().getData()["sevisid"].len() > 0
			},
			useSecureJSONPrefix: false
		);
	}

	/**
	 * Takes a raw http response and converts it to a response object
	 *
	 * @rawResponse an http response struct
	 */
	public Response function processResponse(required struct rawResponse) {
		if( rawResponse.keyExists("responseHeader")
			&& rawResponse.responseHeader.keyExists("status_code")
			&& rawResponse.keyExists("fileContent")
		) {
			return new Response()
				.setStatus(rawResponse.responseHeader.status_code)
				.setStatusText("")
				.setContent(rawResponse.fileContent);
		}

		return new Response();
	}

}
