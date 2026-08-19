<cfoutput>
<div class="auth-page">
    <div class="auth-card">
        <div class="auth-card__brand">
            <img src="assets/img/logo.png" alt="StyleMart" width="40" height="40">
            <h1 class="auth-card__title">StyleMart</h1>
            <p class="auth-card__subtitle">Your AI-powered wardrobe, considered.</p>
        </div>

        <!--- Login Form --->
        <form class="auth-form" id="login-form" autocomplete="on">
            <h2 class="auth-form__heading">Sign in</h2>
            <div class="auth-field">
                <label for="login-username">Username</label>
                <input type="text" id="login-username" name="username" required
                       autocomplete="username" placeholder="e.g. jordan">
            </div>
            <div class="auth-field">
                <label for="login-password">Password</label>
                <input type="password" id="login-password" name="password" required
                       autocomplete="current-password" placeholder="Enter password">
            </div>
            <div class="auth-error" id="login-error" role="alert" aria-live="polite"></div>
            <button type="submit" class="btn btn--primary btn--full">Sign in</button>
            <p class="auth-switch">
                Don't have an account? <a href="##" data-show="register">Create one</a>
            </p>
        </form>

        <!--- Register Form (hidden by default) --->
        <form class="auth-form auth-form--hidden" id="register-form" autocomplete="on">
            <h2 class="auth-form__heading">Create account</h2>
            <div class="auth-field">
                <label for="reg-username">Username</label>
                <input type="text" id="reg-username" name="username" required
                       autocomplete="username" minlength="3" maxlength="32"
                       pattern="[a-zA-Z0-9_.\-]+"
                       placeholder="3-32 chars, letters/numbers/._-">
            </div>
            <div class="auth-field">
                <label for="reg-display">Display name</label>
                <input type="text" id="reg-display" name="displayName" required
                       maxlength="80" placeholder="Your name">
            </div>
            <div class="auth-field">
                <label for="reg-email">Email <span class="auth-optional">(optional)</span></label>
                <input type="email" id="reg-email" name="email"
                       autocomplete="email" placeholder="you@example.com">
            </div>
            <div class="auth-field">
                <label for="reg-password">Password</label>
                <input type="password" id="reg-password" name="password" required
                       autocomplete="new-password" minlength="8" maxlength="128"
                       placeholder="Min 8 chars, 1 letter + 1 digit">
            </div>
            <div class="auth-error" id="register-error" role="alert" aria-live="polite"></div>
            <button type="submit" class="btn btn--primary btn--full">Create account</button>
            <p class="auth-switch">
                Already have an account? <a href="##" data-show="login">Sign in</a>
            </p>
        </form>
    </div>
</div>
</cfoutput>
