# shop-flow-db

PostgreSQL **schema migrations** for ShopFlow, executed with **[DbUp](https://dbup.readthedocs.io/)** from a small **.NET 10** console-style app (`ShopFlowDataBase`).

SQL scripts live under `ShopFlowDataBase/V1.0/Migrations/` and are copied to the build output so the migrator can run them in order.

---

## Prerequisites

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- [PostgreSQL](https://www.postgresql.org/) (server reachable from your machine)
- An empty database (or one where you accept applying these migrations)

---

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_CONNECTION` | **Yes** | Npgsql-style connection string, e.g. `Host=localhost;Port=5432;Database=shopflow;Username=postgres;Password=***` |
| `Version` | No | Migrations root folder under `V1.0` (default: **`V1.0`**) |

The app calls **`EnsureDatabase.For.PostgresqlDatabase(connectionString)`** — if the database in the connection string does not exist, DbUp will try to create it (subject to server permissions).

---

## How to run

### Option A — from this repo (`shop-flow-db`)

1. Create a PostgreSQL database (or use an existing one).
2. Set `DATABASE_CONNECTION` (PowerShell example):

   ```powershell
   $env:DATABASE_CONNECTION = "Host=localhost;Port=5432;Database=shopflow;Username=postgres;Password=yourpassword"
   ```

3. Run the migrator:

   ```bash
   dotnet run --project ShopFlowDataBase/ShopFlowDataBase.csproj
   ```

   Working directory should be **`shop-flow-db`** (the folder that contains `ShopFlowDataBase`).

### Option B — Visual Studio / Rider

Open `ShopFlowDataBase.sln`, set **`ShopFlowDataBase`** as the startup project, choose a launch profile that defines **`DATABASE_CONNECTION`** (see `ShopFlowDataBase/Properties/launchSettings.json` — the **http** profile includes a sample connection string; adjust for your machine).

> The **https** profile in `launchSettings.json` may not set `DATABASE_CONNECTION`; set it in user secrets or environment variables before running.

### Option C — Docker

From **`shop-flow-db`** (build context is this directory):

```bash
docker build -f ShopFlowDataBase/Dockerfile -t shop-flow-db-migrator .
docker run --rm -e DATABASE_CONNECTION="Host=host.docker.internal;Port=5432;Database=shopflow;Username=postgres;Password=yourpassword" shop-flow-db-migrator
```

Adjust `host.docker.internal` / hostnames so the container can reach PostgreSQL.

---

## What runs, and in what order

Under `V1.0/Migrations/`, subfolders are processed **alphabetically**, then each `*.sql` file **alphabetically** within the folder:

1. **`001.Schema`** — create PostgreSQL schemas (`identity`, `catalog`, `log`, `platform`).
2. **`002.Table`** — create tables, indexes, constraints.
3. **`003.SeedData`** — optional sample data (e.g. `001_sample_catalog_data.sql`).

DbUp records applied scripts in **`public.schema_versions`**. On the next run, already-applied scripts are **skipped** (`[SKIP]` in the console).

---

## Output

- **`[RUN]`** / **`[OK]`** — script applied  
- **`[SKIP]`** — already in `schema_versions`  
- **`[FAIL]`** — migration error (non-zero exit code)

---

## Troubleshooting

- **`DATABASE_CONNECTION` unset or invalid** — set it explicitly; the migrator needs a valid connection string at startup.
- **Permission errors** — ensure the DB user can create schemas/tables and write to `public.schema_versions`.
- **SQL client vs seed file** — some IDEs parse `$` inside strings; the seed uses patterns like `chr(36)` for bcrypt hashes. Prefer running migrations via **`dotnet run`** or **`psql`** if the IDE mangles scripts.

---

## Related

- Application API and full stack notes: parent repo **`README.md`** (ShopFlow monorepo) if present, or `shop-flow-api` documentation.
