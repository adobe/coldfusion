<cfparam name="request.title" default="StyleMart">
<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>#request.title#</title>
    <link rel="icon" type="image/svg+xml" href="assets/img/brand/favicon.svg">
    <link rel="stylesheet" href="assets/css/tokens.css">
    <link rel="stylesheet" href="assets/css/themes.css">
    <link rel="stylesheet" href="assets/css/base.css">
    <link rel="stylesheet" href="assets/css/shell.css">
    <link rel="stylesheet" href="assets/css/components.css">
    <link rel="stylesheet" href="assets/css/chat.css">
    <link rel="stylesheet" href="assets/css/trace.css">
    <link rel="stylesheet" href="assets/css/theme-switcher.css">
</head>
<body data-page="#request.viewing#">
    <cfinclude template="header.cfm">
    <main class="app-shell">
        <section class="app-shell__storefront">
            <cfinclude template="#request.storefrontTemplate#">
        </section>
        <div class="resizer auth-only" data-resize="chat" role="separator" aria-orientation="vertical" aria-label="Resize chat column" tabindex="0" style="display:none"></div>
        <section class="app-shell__chat auth-only" style="display:none">
            <cfinclude template="chat-panel.cfm">
        </section>
        <div class="resizer auth-only" data-resize="trace" role="separator" aria-orientation="vertical" aria-label="Resize trace column" tabindex="0" style="display:none"></div>
        <section class="app-shell__trace auth-only" style="display:none">
            <cfinclude template="trace-panel.cfm">
        </section>
    </main>
    <cfinclude template="footer.cfm">

    <!--- Auth modal (inline popup, not a separate page) --->
    <div class="auth-modal" id="auth-modal" aria-hidden="true">
        <div class="auth-modal__backdrop" data-auth-close></div>
        <div class="auth-modal__dialog" role="dialog" aria-labelledby="auth-modal-title">
            <button class="auth-modal__close" data-auth-close aria-label="Close">&times;</button>
            <div class="auth-card__brand">
                <img src="assets/img/logo.png" alt="StyleMart" width="36" height="36">
                <h2 id="auth-modal-title" class="auth-card__title">StyleMart</h2>
            </div>

            <form class="auth-form" id="login-form" autocomplete="on">
                <h3 class="auth-form__heading">Sign in</h3>
                <div class="auth-field">
                    <label for="login-username">Username</label>
                    <input type="text" id="login-username" name="username" required autocomplete="username" placeholder="e.g. jordan">
                </div>
                <div class="auth-field">
                    <label for="login-password">Password</label>
                    <input type="password" id="login-password" name="password" required autocomplete="current-password" placeholder="Enter password">
                </div>
                <div class="auth-error" id="login-error" role="alert" aria-live="polite"></div>
                <button type="submit" class="btn--primary">Sign in</button>
                <p class="auth-switch">Don't have an account? <a href="##" data-show="register">Create one</a></p>
            </form>

            <form class="auth-form auth-form--hidden" id="register-form" autocomplete="on">
                <h3 class="auth-form__heading">Create account</h3>
                <div class="auth-field">
                    <label for="reg-username">Username</label>
                    <input type="text" id="reg-username" name="username" required autocomplete="username" minlength="3" maxlength="32" pattern="[a-zA-Z0-9_.\-]+" placeholder="3-32 chars, letters/numbers/._-">
                </div>
                <div class="auth-field">
                    <label for="reg-display">Display name</label>
                    <input type="text" id="reg-display" name="displayName" required maxlength="80" placeholder="Your name">
                </div>
                <div class="auth-field">
                    <label for="reg-email">Email <span class="auth-optional">(optional)</span></label>
                    <input type="email" id="reg-email" name="email" autocomplete="email" placeholder="you@example.com">
                </div>
                <div class="auth-field">
                    <label for="reg-password">Password</label>
                    <input type="password" id="reg-password" name="password" required autocomplete="new-password" minlength="8" maxlength="128" placeholder="Min 8 chars, 1 letter + 1 digit">
                </div>
                <div class="auth-error" id="register-error" role="alert" aria-live="polite"></div>
                <button type="submit" class="btn--primary">Create account</button>
                <p class="auth-switch">Already have an account? <a href="##" data-show="login">Sign in</a></p>
            </form>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <script type="module" src="assets/js/main.js"></script>
</body>
</html>
</cfoutput>
