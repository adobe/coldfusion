<cfoutput>
<div class="category-page" data-category-root data-category-slug="#encodeForHTML(url.slug)#">
    <div class="category-page__hero" data-category-hero>
        <img data-hero-img src="" alt="">
        <div class="category-page__hero-overlay">
            <h1 data-category-name>Loading…</h1>
            <p data-category-description></p>
        </div>
    </div>
    <section class="category-page__featured">
        <div class="category-page__bar">
            <h2 data-category-heading>Products</h2>
            <span class="category-page__count" data-category-count></span>
        </div>
        <div class="product-grid" data-category-grid></div>
        <div class="plp__status" data-category-status hidden></div>
        <div class="plp__sentinel" data-category-sentinel aria-hidden="true"></div>
    </section>
</div>
</cfoutput>
