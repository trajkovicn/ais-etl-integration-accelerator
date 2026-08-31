using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Azure.Core;
using Azure.Identity;

static string? GetArg(string[] args, string name)
{
    var idx = Array.FindIndex(args, a => a.Equals(name, StringComparison.OrdinalIgnoreCase));
    return (idx >= 0 && idx + 1 < args.Length) ? args[idx + 1] : null;
}

var subscriptionId = GetArg(args, "--subscriptionId") ?? Environment.GetEnvironmentVariable("AZURE_SUBSCRIPTION_ID");
var resourceGroup = GetArg(args, "--resourceGroup");
var integrationAccount = GetArg(args, "--integrationAccount");
var location = GetArg(args, "--location");
var mapFile = GetArg(args, "--mapFile");
var mapName = GetArg(args, "--mapName") ?? "hello-xml-to-json";

if (string.IsNullOrWhiteSpace(subscriptionId) || string.IsNullOrWhiteSpace(resourceGroup) ||
    string.IsNullOrWhiteSpace(integrationAccount) || string.IsNullOrWhiteSpace(location) ||
    string.IsNullOrWhiteSpace(mapFile))
{
    Console.WriteLine(
        """
        Usage:
          dotnet run -- --subscriptionId <subId> --resourceGroup <rg> --integrationAccount <iaName> --location <region> --mapFile <path> [--mapName <name>]

        Auth: DefaultAzureCredential (az login / VS / MI). You can set AZURE_SUBSCRIPTION_ID env var.
        """);
    return;
}

var credential = new DefaultAzureCredential();
var token = await credential.GetTokenAsync(new TokenRequestContext(new[] { "https://management.azure.com/.default" }));

using var http = new HttpClient();
http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token.Token);

var mapContent = await File.ReadAllTextAsync(mapFile);

var uri = $"https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationAccounts/{integrationAccount}/maps/{mapName}?api-version=2019-05-01";

var payload = new
{
    location,
    properties = new
    {
        mapType = "Liquid",
        content = mapContent
    }
};

var json = JsonSerializer.Serialize(payload, new JsonSerializerOptions { WriteIndented = true });

var resp = await http.PutAsync(uri, new StringContent(json, Encoding.UTF8, "application/json"));
var respText = await resp.Content.ReadAsStringAsync();

if (!resp.IsSuccessStatusCode)
{
    Console.Error.WriteLine(
        $"""
        Upload failed ({(int)resp.StatusCode} {resp.ReasonPhrase})
        {respText}
        """);
    Environment.ExitCode = 1;
    return;
}

Console.WriteLine($"Uploaded map '{mapName}' to Integration Account '{integrationAccount}'.");
