import istart.core.ErrorLogger;

/**
 * Calls an external integration endpoint.
 */
component {

	property ExternalService service;
	property Sender sender;
	property DataTransferConfig configs;

	/**
	 * Creates an integration service
	 *
	 * @service an ExternalService implementation for handling the data for this integration
	 * @sender a Sender implementation for handling communication for this integration
	 * @configs a struct
	 */
	public IntegrationPoint function init(
		required ExternalService service,
		required Sender sender,
		DataTransferConfig configs=new DataTransferConfig()
	) {
		variables.service = service;
		variables.sender = sender;
		variables.configs = configs
		return this;
	}

	/**
	 * Run the integration request
	 *
	 * @httpRequest Data to feed to the request, specified in the format of the Data Transfer API
	 * @authenticate whether or not to run Data Transfer API Authentication (defaults to true)
	 *
	 * @returns a Response object with API response information
	 */
	public Response function process(required struct httpRequest, boolean authenticate=true, struct urlScope=URL) {
		try {
			if( authenticate ) {
				new Authenticator(httpRequest, urlScope).check();
			}

			var data = httpRequest.keyExists("content") ? ToString(httpRequest.content) : "";
			var dataPacket = new DataPacket(data, getConfigs());
			getService().initialize(dataPacket);
			var rawResponse = getSender().send(getService());
			return getService().processResponse(rawResponse);
		}
		catch( AuthenticationException exception ) {
			// login failure
			var response = new Response();
			response.setStatus(401);
			response.setStatusText("Unauthorized");
			response.setContent(exception.getMessage());
			return response;
		}
		catch( UnnecessarySubmitException exception ) {
			// this is a success, because data did not need to be sent.
			var response = new Response();
			response.setStatus(200);
			response.setStatusText("OK");
			response.setContent("");
			return response;
		}
		catch( any exception ) {
			// some other error happened
			var response = new Response();
			response.setStatusText("Internal Server Error");
			response.setContent(exception.getMessage());
			new ErrorLogger().logError("integration", "IntegrationPoint", "process", "", exception);
			return response;
		}
	}

	/**
	 * getter for ExternalService instance
	 */
	public ExternalService function getService() {
		return variables.service;
	}

	/**
	 * getter for Sender instance
	 */
	public Sender function getSender() {
		return variables.sender;
	}

	public DataTransferConfig function getConfigs() {
		return variables.configs;
	}

	/**
	 * utility method for transforming a generic struct of data into
	 * the Data Transer API format.
	 *
	 * @data a struct to transform
	 *
	 * @returns a struct with the same data, but in the format expected by the process method
	 */
	public struct function createInputFromData(required struct data) {
		var jsonData = SerializeJSON(data);
		return {content: jsonData};
	}

}
