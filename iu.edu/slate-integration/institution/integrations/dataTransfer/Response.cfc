/**
 * this stores a http response header and content to be passed back to sunapsis.
 * @accessors true
 */
component {

	/**
	 * The HTTP Response code (200, 500, etc.)
	 */
	property numeric status;
	/**
	 * The status text ("OK," "Internal Server Error," etc.)
	 */
	property string statusText;
	/**
	 * Response content: the body of the http response.
	 */
	property string content;

	/**
	 * initializes the response to a generic failure
	 */
	public Response function init() {
		setStatus(500);
		setStatusText("Internal Server Error");
		setContent("Unknown Error");

		return this;
	}

	/**
	 * returns if the request was successful or not
	 */
	public boolean function isSuccessful() {
		return getStatus() == 200;
	}

}
