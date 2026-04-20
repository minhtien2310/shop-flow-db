using DbUp;
using Npgsql;

const int exitFailure = 1;

const string journalSchema = "log";
const string journalTable = "schema_versions";

var connectionString = Environment.GetEnvironmentVariable("DATABASE_CONNECTION");
var fromVersion = Environment.GetEnvironmentVariable("Version") ?? "V1.0";

if (string.IsNullOrWhiteSpace(connectionString))
    return exitFailure;

EnsureDatabase.For.PostgresqlDatabase(connectionString);
// DbUp touches the journal before any .sql script runs; the journal schema must already exist.
EnsurePostgresqlSchemaExists(connectionString, journalSchema);

var sqlRoot = Path.Combine(AppContext.BaseDirectory, fromVersion, "Migrations");

var orderedFiles = CollectSqlFilesInOrder(sqlRoot);
if (orderedFiles.Count == 0)
{
    return exitFailure;
}

var failedFiles = new List<(string Name, Exception Error)>();
var successCount = 0;
var skippedCount = 0;

foreach (var (dir, filePath) in orderedFiles)
{
    var scriptName = Path.GetFileName(filePath);

    var engine = DeployChanges.To
        .PostgresqlDatabase(connectionString)
        .WithScriptsFromFileSystem(dir, f => string.Equals(
            Path.GetFullPath(f), Path.GetFullPath(filePath),
            StringComparison.OrdinalIgnoreCase))
        .JournalToPostgresqlTable(journalSchema, journalTable)
        .LogToNowhere()
        .Build();

    if (!engine.IsUpgradeRequired())
    {
        Console.WriteLine($"[SKIP] {scriptName}");
        skippedCount++;
        continue;
    }

    Console.WriteLine($"[RUN]  {scriptName}");
    var result = engine.PerformUpgrade();

    if (result.Successful)
    {
        Console.WriteLine($"[OK]   {scriptName}");
        successCount++;
    }
    else
    {
        Console.Error.WriteLine($"[FAIL] {scriptName}");
        Console.Error.WriteLine($"       {result.Error.Message}");
        failedFiles.Add((scriptName, result.Error));
    }
}

Console.WriteLine($"Result: {successCount} success, {skippedCount} skip, {failedFiles.Count} error.");

if (failedFiles.Count > 0)
{
    Console.Error.WriteLine("\nErrors:");
    foreach (var (name, error) in failedFiles)
        Console.Error.WriteLine($"  - {name}: {error.Message}");

    return exitFailure;
}

Console.WriteLine("Migration successfully finished.");
return 0;

static void EnsurePostgresqlSchemaExists(string connectionString, string schemaName)
{
    if (string.IsNullOrWhiteSpace(schemaName) ||
        schemaName.Any(c => !(char.IsAsciiLetterLower(c) || char.IsAsciiDigit(c) || c == '_')))
        throw new ArgumentException(
            "Schema name must be non-empty and use only lowercase letters, digits, and underscore.",
            nameof(schemaName));

    using var connection = new NpgsqlConnection(connectionString);
    connection.Open();
    using var cmd = new NpgsqlCommand($"CREATE SCHEMA IF NOT EXISTS {schemaName}", connection);
    cmd.ExecuteNonQuery();
}

static List<(string Dir, string FilePath)> CollectSqlFilesInOrder(string migrationsRoot)
{
    var result = new List<(string, string)>();

    var subdirs = Directory.GetDirectories(migrationsRoot)
        .OrderBy(Path.GetFileName, StringComparer.Ordinal)
        .ToList();

    IEnumerable<string> sources = subdirs.Count > 0
        ? subdirs
        : [migrationsRoot];

    foreach (var dir in sources)
    {
        foreach (var file in Directory.GetFiles(dir, "*.sql", SearchOption.TopDirectoryOnly)
                     .OrderBy(Path.GetFileName, StringComparer.Ordinal))
        {
            result.Add((dir, file));
        }
    }

    return result;
}
