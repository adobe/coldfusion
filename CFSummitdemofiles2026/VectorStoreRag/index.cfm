<cfscript>
apiKeyReady = len(trim(application.openAiApiKey)) > 0;
ingestReady = structKeyExists(application, "ingestStatus") && application.ingestStatus.ready;
vectorReady = structKeyExists(application, "vectorClient") && isObject(application.vectorClient);
</cfscript>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Glaze Against The Machine - ColdFusion AI</title>
    <link rel="stylesheet" href="assets/app.css">
    <link rel="stylesheet" href="../assets/demo-window.css">
</head>
<body class="home-page demo-windowed-scroll">
    <div class="demo-windowbar">
        <a class="demo-windowbar-back" href="/CFSummit2026/demos/" aria-label="Back to demo home">Back to home</a>
        <span class="demo-windowbar-title">CF2025 AI Demo</span>
        <span class="demo-windowbar-name">Glaze Against The Machine</span>
    </div>
    <header class="header">
        <div class="header-top">
            <a class="logo logo-image-lockup" href="index.cfm" aria-label="Glaze Against The Machine home">
                <img class="header-logo-image" src="img/gatm_rect_logo.png" alt="">
                <span class="logo-badge">CF AI</span>
            </a>
            <nav class="nav" aria-label="Main navigation">
                <a class="active" href="index.cfm">Home</a>
                <a href="bootstrap.cfm">Bake The Menu</a>
                <a href="search.cfm">Ask The Bot</a>
            </nav>
        </div>
    </header>

    <main>
        <section class="home-hero" aria-labelledby="homeTitle">
            <div class="home-sprinkles" aria-hidden="true"></div>
            <div class="donutland-scene" aria-hidden="true">
                <div class="rainbow-arc"></div>
                <div class="cloud cloud-one"></div>
                <div class="cloud cloud-two"></div>
                <div class="candy-hill candy-hill-one"></div>
                <div class="candy-hill candy-hill-two"></div>
                <div class="donut-castle">
                    <div class="castle-tower tower-left"></div>
                    <div class="castle-tower tower-right"></div>
                    <div class="castle-base">
                        <span></span>
                        <span></span>
                        <span></span>
                    </div>
                </div>
                <div class="jumbo-donut">
                    <span class="scene-sprinkle sprinkle-one"></span>
                    <span class="scene-sprinkle sprinkle-two"></span>
                    <span class="scene-sprinkle sprinkle-three"></span>
                    <span class="scene-sprinkle sprinkle-four"></span>
                    <span class="scene-sprinkle sprinkle-five"></span>
                </div>
                <div class="unicorn" aria-hidden="true">
                    <img class="unicorn-art" src="img/unicorn_vector_trace.svg" alt="">
                </div>
            </div>

            <div class="home-hero-inner">
                <div class="home-copy">
                    <p class="eyebrow home-eyebrow">Family donut magic, powered by ColdFusion AI</p>
                    <h1 id="homeTitle" class="sr-only">Glaze Against The Machine</h1>
                    <div class="home-logo-stage">
                        <img class="home-logo-image" src="img/gatm_square_logo.png" alt="Glaze Against The Machine">
                    </div>
                    <p class="home-lede">
                        A rainbow-bright donut shop helper for families choosing the perfect box:
                        classic favorites for grown-ups, sprinkle storms for kids, and allergy-aware
                        answers before anyone presses their nose to the glass.
                    </p>
                    <cfif !apiKeyReady>
                        <p class="home-note">
                            Add your API key to the keystore as <code>openaiapi_donuts</code>, then
                            <a href="index.cfm?reloadApp=1">reload application state</a>.
                        </p>
                    </cfif>
                    <div class="actions home-actions">
                        <a class="button" href="search.cfm">Build A Family Box</a>
                        <a class="button secondary" href="bootstrap.cfm">Stock The Sprinkle Case</a>
                    </div>
                </div>

                <aside class="home-flavor-ticket" aria-label="Today's donut mood">
                    <span class="ticket-kicker">Today's wish</span>
                    <strong>One dozen tiny uprisings</strong>
                    <span>with unicorn glaze, rainbow crumbs, and smart menu answers.</span>
                </aside>
            </div>
        </section>

        <section class="shell home-shop-strip" aria-label="Shop highlights">
            <article class="treat-card">
                <span class="treat-dot treat-dot-pink"></span>
                <h2>Sprinkle rebels</h2>
                <p>Bright flavors, silly names, and surprise-safe recommendations for little sweet tooths.</p>
            </article>
            <article class="treat-card">
                <span class="treat-dot treat-dot-mint"></span>
                <h2>Family boxes</h2>
                <p>Ask for a mix that keeps chocolate fans, fruit fans, and coffee fans smiling.</p>
            </article>
            <article class="treat-card">
                <span class="treat-dot treat-dot-yellow"></span>
                <h2>Menu-aware answers</h2>
                <p>The bot answers from whichever donut catalog is currently stocked in the vector case.</p>
            </article>
        </section>

        <section class="shell home-dashboard" aria-labelledby="dashboardTitle">
            <div class="home-section-heading">
                <p class="eyebrow">Shop counter</p>
                <h2 id="dashboardTitle">The magic oven status</h2>
                <p>
                    A quick peek behind the counter shows which menu is stocked and whether the helper is ready.
                </p>
            </div>

            <div class="home-dashboard-grid">
                <section class="status-panel" aria-label="Readiness">
                    <div class="status-panel-top">
                        <div class="mini-donut status-donut" aria-hidden="true"></div>
                        <div>
                            <p class="eyebrow">Readiness</p>
                            <h3>Ready for the morning rush?</h3>
                        </div>
                    </div>
                    <div class="status-grid">
                        <div class="status-row">
                            <span class="status-label">OpenAI API key</span>
                            <cfoutput><span class="chip #apiKeyReady ? 'ok' : 'bad'#">#apiKeyReady ? 'configured' : 'missing'#</span></cfoutput>
                        </div>
                        <div class="status-row">
                            <span class="status-label">Vector store</span>
                            <cfoutput><span class="chip #vectorReady ? 'ok' : 'warn'#">#vectorReady ? 'initialized' : 'not ready'#</span></cfoutput>
                        </div>
                        <div class="status-row">
                            <span class="status-label">Current menu</span>
                            <cfoutput><span class="chip #ingestReady ? 'ok' : 'warn'#">#ingestReady ? application.ingestStatus.addedCount & ' chunks' : 'not ingested'#</span></cfoutput>
                        </div>
                        <div class="status-row">
                            <span class="status-label">Source</span>
                            <cfoutput><span class="muted">#encodeForHTML(application.ingestStatus.sourceName)#</span></cfoutput>
                        </div>
                    </div>
                </section>

                <section class="visit-panel" aria-label="Next steps">
                    <p class="eyebrow">Next sweet stop</p>
                    <h3>Choose what the bot knows, then let families ask away.</h3>
                    <p>
                        Stock the vector case with a menu, preview the treats, and send shoppers to the
                        donut finder for grounded recommendations.
                    </p>
                    <div class="actions">
                        <a class="button secondary" href="bootstrap.cfm">Change The Menu</a>
                        <a class="button" href="search.cfm">Ask For Donuts</a>
                    </div>
                    <div class="flavor-stack" aria-hidden="true">
                        <span>Rainbow Rings</span>
                        <span>Cloud Puff Crullers</span>
                        <span>Unicorn Confetti</span>
                    </div>
                </section>
            </div>
        </section>
    </main>
</body>
</html>
