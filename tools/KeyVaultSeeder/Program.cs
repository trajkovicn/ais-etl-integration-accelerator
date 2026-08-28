using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

static string? GetArg(string[] args, string name)
{
    var idx = Array.FindIndex(args, a => a.Equals(name, StringComparison.OrdinalIgnoreCase));
    return (idx >= 0 && idx + 1 < args.Length) ? args[idx + 1] : null;
}

var vaultName = GetArg(args, "--vault") ?? GetArg(args, "--vaultName");
var secretName = GetArg(args, "--name");
var secretValue = GetArg(args, "--value");

if (string.IsNullOrWhiteSpace(vaultName) || string.IsNullOrWhiteSpace(secretName) || secretValue is null)
{
    Console.WriteLine(
        """
        Usage:
          dotnet run -- --vault <kvName> --name <secretName> --value <secretValue>

        Auth: DefaultAzureCredential (az login / VS / MI).
        """);
    return;
}

var uri = new Uri($"https://{vaultName}.vault.azure.net/");
var client = new SecretClient(uri, new DefaultAzureCredential());

await client.SetSecretAsync(secretName, secretValue);
Console.WriteLine($"Set secret '{secretName}' in vault '{vaultName}'.");
