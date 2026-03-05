import institution.integrations.dataTransfer.ExternalService;
import institution.integrations.slate.services.SlateService;
import istart.core.*;

component implements="institution.integrations.dataTransfer.Sender" {

	public struct function send(required ExternalService package) {
		try {
			var builder = new HttpBuilder();
			builder.configure(package.getEndPoint(), package.getAction(), false);
			//builder.add("throwOnError", "true");
			builder.add("username", package.getUsername());
			builder.add("password", package.getAPIKey());

			for( var data in package.getFormattedData() ) {
				cfhttp(attributeCollection: builder.getAttributeMap()) {
					if( Len(data) > 0 ) {
						cfhttpparam(type: "header", name: "Content-Type", value: "application/json");
						cfhttpparam(type: "body", value: data);
					}
				}

				if( !package.processResponse(local.result).isSuccessful() ) {
					return local.result;
				}
			}

			return IsDefined("local.result") ? local.result : {};
		}
		catch( any error ) {
			new ErrorLogger().logError("error", "SlateSender", "send", package.getUsername(), error);
			return {};
		}
	}

}