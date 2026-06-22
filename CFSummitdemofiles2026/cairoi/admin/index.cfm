<cfsetting showdebugoutput="false">
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>CAIROI Admin</title>
    <link rel="stylesheet" href="../dashboard/assets/cairoi.css">
</head>
<body>
<main class="shell">
    <div class="topbar">
        <div class="brand">
            <h1>CAIROI Admin</h1>
            <p>Local MVP administration for applications, pricing, and setup.</p>
        </div>
        <nav class="nav">
            <a href="setup.cfm">Setup</a>
            <a href="applications.cfm">Applications</a>
            <a href="prices.cfm">Prices</a>
            <a href="../dashboard/index.cfm">Dashboard</a>
        </nav>
    </div>

    <section class="grid">
        <a class="panel" href="setup.cfm">
            <h2>Setup</h2>
            <p class="muted">Create the embedded Derby database and seed the local demo app/key/prices.</p>
        </a>
        <a class="panel" href="applications.cfm">
            <h2>Applications</h2>
            <p class="muted">List and manage apps that can submit telemetry.</p>
        </a>
        <a class="panel" href="prices.cfm">
            <h2>Prices</h2>
            <p class="muted">Manage model pricing used for estimated cost calculations.</p>
        </a>
    </section>
</main>
</body>
</html>
