/**
 * An interface for communicating with an external API
 */
interface {

	/**
	 * Takes the information present in an ExternalService and uses it to make 
	 * a request to an API.
	 * 
	 * @package the service data for making the request
	 * 
	 * @returns a struct of the raw data for a response. Usually a cfhttp response object (which is struct-ish)
	 */
    public struct function send(required ExternalService package);

}
