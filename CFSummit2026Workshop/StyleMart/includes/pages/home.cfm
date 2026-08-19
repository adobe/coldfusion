<cfoutput>
<section class="hero">
    <img class="hero__bg" src="assets/img/home-hero.png" alt=""
         loading="eager" decoding="async"
         onerror="this.parentElement.classList.add('hero--no-img');">
    <div class="hero__overlay"></div>
    <div class="hero__copy">
        <p class="hero__eyebrow">AI Commerce Studio</p>
        <h1>Wardrobe,<br>considered.</h1>
        <p>A capsule wardrobe for travel, work, and everything in between. Curated by AI, styled for you.</p>
        <div class="hero__cta">
            <a class="btn-primary" href="products.cfm">Shop the catalog</a>
            <a class="btn-secondary hero__btn-alt" href="capsule.cfm">View capsules</a>
        </div>
    </div>
</section>


<section class="cat-strip" aria-label="Browse categories">
    <h2>Browse categories</h2>
    <div class="cat-strip__grid" data-categories></div>
</section>

<section class="capsule-promo">
    <h2>Curated Capsule Wardrobes</h2>
    <p>AI-styled sets for travel, work, and weekend — personalized when you sign in.</p>
    <a class="btn-secondary" href="capsule.cfm">Explore capsules</a>
</section>

<section class="featured" aria-label="Featured">
    <h2>Featured</h2>
    <div class="product-grid" data-featured-grid></div>
</section>
</cfoutput>
