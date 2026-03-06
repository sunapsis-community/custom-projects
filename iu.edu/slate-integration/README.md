This is code for IU's Slate Integration. I believe that it should work for anyone on 4.2. This probably seems over-engineered, but I have about a dozen integrations using the components in the integrations.dataTransfer package.

The entry point for this code is transfer-endpoints/SlateReceiver.cfm.  It receives data from sunapsis' Data Transfer API.

DataTransferConfig configures what the data is expected to look like (based on the Data Transfer Service configuration options within sunapsis).

It then builds an IntegrationPoint, injecting the SlateService and the SlateSender.

The service processes the incoming request (using ColdFusion's built-in `GetHTTPRequestData()` function), and then returns a response.  It handles verifying the authentication coming from sunapsis (to ensure that you're not accepting requests from the outside world), parsing the incoming data into a DataPacket object, and calling on the Service and Sender components to do the real work.

The SlateService handles filtering out requests that Slate doesn't care about and looking up Slate credentials (in `initialize`) and transforming the in-coming request to the format that Slate is expecting (`formatData`).

SlateSender handles actually sending data to Slate -- using the login information and data from the Service to produce the expected HTTP request.
