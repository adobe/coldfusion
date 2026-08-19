<cfparam name="request.viewing" default="home">
<cfoutput>
<header class="site-header">
    <div class="site-header__inner">
        <a class="brand-mark site-header__logo" href="index.cfm">
            <img class="logo-icon" src="assets/img/logo.png" alt="StyleMart logo" width="28" height="28">
            <span class="logo-text">StyleMart</span>
        </a>
        <nav class="site-header__nav" aria-label="Primary">
            <div class="nav-link nav-link--mega">
                <a href="products.cfm" class="nav-link__label">Shop</a>
                <div class="mega-menu" aria-label="Shop categories">
                    <div class="mega-menu__col">
                        <h4>Tops</h4>
                        <a href="category.cfm?slug=tshirts">T-Shirts</a>
                        <a href="category.cfm?slug=shirts">Shirts</a>
                        <a href="category.cfm?slug=sweaters">Sweaters</a>
                    </div>
                    <div class="mega-menu__col">
                        <h4>Bottoms</h4>
                        <a href="category.cfm?slug=jeans">Jeans</a>
                        <a href="category.cfm?slug=pants">Pants</a>
                    </div>
                    <div class="mega-menu__col">
                        <h4>Outerwear</h4>
                        <a href="category.cfm?slug=jackets">Jackets</a>
                        <a href="category.cfm?slug=raincoats">Raincoats</a>
                        <a href="category.cfm?slug=dresses">Dresses</a>
                    </div>
                    <div class="mega-menu__col">
                        <h4>Shoes & Accessories</h4>
                        <a href="category.cfm?slug=sneakers">Sneakers</a>
                        <a href="category.cfm?slug=formal-shoes">Formal Shoes</a>
                        <a href="category.cfm?slug=backpacks">Backpacks</a>
                        <a href="category.cfm?slug=sunglasses">Sunglasses</a>
                    </div>
                    <div class="mega-menu__col mega-menu__col--promo">
                        <h4>Curated</h4>
                        <a href="capsule.cfm?capsule=jordan-london">Capsule Wardrobes</a>
                        <a href="products.cfm">View All</a>
                    </div>
                </div>
            </div>
            <a href="capsule.cfm" class="nav-link" data-tooltip="Curated outfit sets — personalized when you sign in">Tailored Looks</a>
            <a href="orders.cfm" class="nav-link">Orders</a>
        </nav>
        <div class="site-header__actions">
            <div class="search-bar" data-search-bar>
                <form class="search-bar__form" action="search.cfm" method="get" role="search" aria-label="Site search">
                    <span class="search-bar__icon" aria-hidden="true">
                        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                    </span>
                    <input
                        type="search"
                        name="q"
                        class="search-bar__input"
                        placeholder="Search products, categories…"
                        autocomplete="off"
                        spellcheck="false"
                        role="combobox"
                        aria-expanded="false"
                        aria-controls="search-suggestions"
                        aria-autocomplete="list"
                        aria-haspopup="listbox"
                        data-search-input>
                    <button type="button" class="search-bar__clear" aria-label="Clear search" data-search-clear hidden>
                        <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                    </button>
                </form>
                <div class="search-bar__panel" id="search-suggestions" role="listbox" aria-label="Search suggestions" data-search-panel hidden></div>
            </div>
            <button class="icon-btn search-bar__mobile-toggle" aria-label="Open search" data-search-mobile-toggle>
                <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
            </button>
            <a class="icon-btn header-compare" href="compare.cfm" aria-label="Compare" data-compare-header style="display:none">⚖ <span data-compare-count>0</span></a>
            <a class="icon-btn" href="cart.cfm" aria-label="Cart">🛒 <span data-cart-count>0</span></a>
            <a class="header-user auth-only" href="account.cfm" style="display:none">
                <span class="header-user__avatar">👤</span>
                <span class="header-user__name" data-user-name></span>
            </a>
            <button class="btn-logout auth-only" data-logout style="display:none">Logout</button>
            <a class="icon-btn anon-only" href="login.cfm" aria-label="Sign in">Sign in</a>
        </div>
    </div>
</header>
</cfoutput>
