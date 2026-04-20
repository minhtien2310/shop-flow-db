using DbUp;

const int exitFailure = 1;

var connectionString = Environment.GetEnvironmentVariable("DATABASE_CONNECTION");
var fromVersion = Environment.GetEnvironmentVariable("Version");

if (string.IsNullOrWhiteSpace(connectionString))
{
    Console.Error.WriteLine(
        "Thiếu connection string. Đặt biến môi trường DATABASE_CONNECTION.");
    return exitFailure;
}

if (string.IsNullOrWhiteSpace(fromVersion))
{
    Console.Error.WriteLine("Thiếu biến môi trường Version (ví dụ V1.0).");
    return exitFailure;
}

Console.WriteLine("Kiểm tra database...");
EnsureDatabase.For.PostgresqlDatabase(connectionString);
Console.WriteLine("Database sẵn sàng.");

var sqlRoot = Path.Combine(AppContext.BaseDirectory, fromVersion, "Migrations");

if (!Directory.Exists(sqlRoot))
{
    Console.Error.WriteLine($"Không tìm thấy thư mục migrations: {sqlRoot}");
    return exitFailure;
}

var orderedFiles = CollectSqlFilesInOrder(sqlRoot);
if (orderedFiles.Count == 0)
{
    Console.Error.WriteLine($"Không có file .sql nào trong: {sqlRoot}");
    return exitFailure;
}

Console.WriteLine($"Tìm thấy {orderedFiles.Count} script(s). Bắt đầu migration...");
Console.WriteLine(new string('-', 60));

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
        .JournalToPostgresqlTable("public", "schema_versions")
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

Console.WriteLine(new string('-', 60));
Console.WriteLine($"Kết quả: {successCount} thành công, {skippedCount} bỏ qua, {failedFiles.Count} lỗi.");

if (failedFiles.Count > 0)
{
    Console.Error.WriteLine("\nDanh sách file lỗi:");
    foreach (var (name, error) in failedFiles)
        Console.Error.WriteLine($"  - {name}: {error.Message}");

    return exitFailure;
}

Console.WriteLine("Tất cả migration đã áp dụng thành công.");
return 0;

/// <summary>
/// Quét thư mục con của Migrations theo thứ tự tên (001.Schema trước 002.Table...).
/// Trả về danh sách (thư mục chứa file, đường dẫn đầy đủ tới file) để
/// DbUp tự đọc file qua WithScriptsFromFileSystem — không đọc nội dung file trong code.
/// </summary>
static List<(string Dir, string FilePath)> CollectSqlFilesInOrder(string migrationsRoot)
{
    var result = new List<(string, string)>();

    var subdirs = Directory.GetDirectories(migrationsRoot)
        .OrderBy(d => Path.GetFileName(d), StringComparer.Ordinal)
        .ToList();

    IEnumerable<string> sources = subdirs.Count > 0
        ? subdirs
        : [migrationsRoot];

    foreach (var dir in sources)
    {
        foreach (var file in Directory.GetFiles(dir, "*.sql", SearchOption.TopDirectoryOnly)
                     .OrderBy(f => Path.GetFileName(f), StringComparer.Ordinal))
        {
            result.Add((dir, file));
        }
    }

    return result;
}
