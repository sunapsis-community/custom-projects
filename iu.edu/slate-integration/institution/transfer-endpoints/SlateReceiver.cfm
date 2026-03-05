<cfscript>
	import institution.integrations.dataTransfer.*;
	import institution.integrations.slate.services.SlateService;
	import institution.integrations.slate.communicators.SlateSender;
	import istart.core.ErrorLogger;

	local.configs = new DataTransferConfig()
		.setUniversityIdKey("uid");

	local.service = new IntegrationPoint(new SlateService(), new SlateSender(), local.configs);
	local.response = service.process(GetHTTPRequestData());

	cfheader(statuscode: local.response.getStatus());
	WriteOutput(local.response.getContent());
</cfscript>