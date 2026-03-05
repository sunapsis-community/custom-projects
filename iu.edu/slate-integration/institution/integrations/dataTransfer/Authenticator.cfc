import istart.core.EncryptionHandler;

/**
 * This class verifies the username/password HTTP Basic Auth method for incoming Data Tranfer API requests
 *
 * It *does not* handle secretKey authentication
 */
component {

	property string username;
	property string password;
	property boolean useSecretKey;

	/**
	 * Parses HTTP Basic Auth credentials out of the incoming HTTP request
	 */
	public Authenticator function init(required struct httpRequest, required struct urlScope) {
		variables.username = "";
		variables.password = "";
		variables.useSecretKey = false;

		if( httpRequest.keyExists("headers")
			&& httpRequest.headers.keyExists("authorization")
		) {
			setCredentialsFromBasicAuth(httpRequest);
		}
		else if( urlScope.keyExists("timestamp") && urlScope.keyExists("user") && urlScope.keyExists("hash") ) {
			setCredentialsFromSecretKey(urlScope);
		}
		return this;
	}

	private void function setCredentialsFromBasicAuth(required struct httpRequest) {
		// credentials are in the format "Basic <encoded string>"
		var encodedCredentials = ListLast(httpRequest.headers.authorization, " "); // get the encoded part
		var credentialsString = ToString(ToBinary(encodedCredentials)); // decode
		variables.username = ListFirst(credentialsString, ":");
		variables.password = ListLast(credentialsString, ":");
	}

	private void function setCredentialsFromSecretKey(required struct urlScope) {
		variables.username = urlScope.user;
		variables.password = urlScope.timestamp & urlScope.hash;
		variables.useSecretKey = true;
	}

    /**
     * Checks if the credentials on the Data Transfer API request match the configured credentials
	 *
	 * Throws AuthenticationException on failure
     */
	public void function check() {
		var lookupCredentials = QueryExecute(
			"SELECT
                configDataTransferService.recnum,
	            configDataTransferService.username,
	            configDataTransferService.password,
				configDataTransferService.secretKey
            FROM dbo.configDataTransferService
            WHERE configDataTransferService.url = :url",
            { url: {cfsqltype: "nvarchar", value: 'https://' & CGI.SERVER_NAME & CGI.SCRIPT_NAME}}
		);

		if( lookupCredentials.recordCount > 0 ) {
			var handler = new EncryptionHandler();
			var password = handler.decryptField(lookupCredentials.password, "configDataTransferService", lookupCredentials.recnum).getString();
			var secretKey = handler.decryptField(lookupCredentials.secretKey, "configDataTransferService", lookupCredentials.recnum).getString();

			if( !shouldUseSecretKey()
				&& getUsername().compare(lookupCredentials.username) == 0
                && getPassword().compare(password) == 0
            ) {
                return;
            }

			if( shouldUseSecretKey()
				&& getUsername().compare(lookupCredentials.username) == 0
				&& isValidSecretKey(getPassword(), secretKey)
			) {
				return;
			}

            Throw("Invalid credentials", "AuthenticationException");
		}

		Throw("Invalid endpoint", "AuthenticationException");
	}

	private boolean function shouldUseSecretKey() {
		return variables.useSecretKey;
	}

	private string function getUsername() {
		return variables.username;
	}

	private string function getPassword() {
		return variables.password;
	}

	private boolean function isValidSecretKey(required string password, required string secretKey) {
		var timeFormat = "yyyyMMddHHnnss";
		var timeString = Left(password, Len(timeFormat));
		try {
			var timestamp = ParseDateTime(timeString, timeFormat);
			if( DateDiff("s", timestamp, Now()) <= 30 ) {
				var hash = LCase(Hash(timeString & secretKey, "SHA-256"));
				return Compare(password, hash) == 0
			}
		}
		catch( any error ) {
			return false;
		}
	}

}
