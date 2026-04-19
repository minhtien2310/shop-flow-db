using DbUp;

const int exitFailure = 1;


var connectionString = Environment.GetEnvironmentVariable("DATABASE_CONNECTION");
var fromVersion = Environment.GetEnvironmentVariable("Version")!;

if (string.IsNullOrWhiteSpace(connectionString))
{
    Console.Error.WriteLine(
        "Thiếu connection string. Đặt ConnectionStrings:PostgreDatabase trong appsettings.json " +
        "hoặc biến môi trường SHOPFLOW_DATABASE_CONNECTION.");
    return exitFailure;
}

var sqlRoot = Path.Combine(AppContext.BaseDirectory, fromVersion, "Migrations");

var schemaScripts = Path.Combine(sqlRoot, "001.Schema");
var tableScripts = Path.Combine(sqlRoot, "002.Table");

var upgradeBuilder = DeployChanges.To
    .PostgresqlDatabase(connectionString)
    .WithScriptsFromFileSystem(schemaScripts)
    .WithScriptsFromFileSystem(tableScripts)
    .JournalToPostgresqlTable("public", "schema_versions");

var engine = upgradeBuilder.LogToConsole().Build();

if (!engine.IsUpgradeRequired())
{
    Console.WriteLine("Cơ sở dữ liệu đã ở phiên bản mới nhất.");
    return 0;
}

var result = engine.PerformUpgrade();
if (!result.Successful)
{
    Console.Error.WriteLine(result.Error);
    return exitFailure;
}

Console.WriteLine("Áp dụng migration thành công.");
return 0;