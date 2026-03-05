/**
 * An interface for containing data for a particular integration 
 */
interface {

    /**
     * initializes the Service
     * @data the data required by the service to perform a request
     */
    public void function initialize(required DataPacket data);

    /**
     * returns the endpoint of the API
     */
    public string function getEndPoint();

    /**
     * returns the username for accessing the API
     */
    public string function getUsername();

    /**
     * returns the API Key (password) for accessing the API
     */
    public string function getAPIKey();

    /**
     * returns the action to be taken on the request -- with REST APIs, this is usually a HTTP verb.
     */
    public string function getAction();

    /**
     * Returns an array of objects to pass to the API (often the body of requests)
     */
    public array function getFormattedData();

    /**
     * Return the response from the API in a strandardized format
	 * 
	 * @rawResponse the raw response from a Sender instance, usually a cfhttp response object (which is struct-ish)
     */
    public Response function processResponse(required struct rawResponse);

}
