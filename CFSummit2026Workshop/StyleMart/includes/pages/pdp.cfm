<cfoutput>
<cfparam name="url.id" default="">
<nav class="breadcrumb" aria-label="Breadcrumb" data-breadcrumb>
    <a href="index.cfm">Home</a> <span class="breadcrumb__sep">›</span>
    <a href="products.cfm">Shop</a> <span class="breadcrumb__sep">›</span>
    <span data-breadcrumb-category>Loading…</span>
</nav>
<div class="pdp" data-pdp-root data-product-id="#encodeForHTML(url.id)#">
    <div class="pdp__gallery">
        <div class="pdp__main-img"><img data-main-img alt=""></div>
        <div class="pdp__thumbs" data-thumbs></div>
    </div>
    <div class="pdp__info">
        <h1 data-name>Loading…</h1>
        <div class="pdp__row">
            <span class="pdp__price" data-price></span>
            <span class="pdp__rating" data-rating></span>
        </div>
        <div class="pdp__chooser">
            <label class="label">Color: <span class="pdp__selected-label" data-color-label></span></label>
            <div class="pdp__colors" data-colors></div>
        </div>
        <div class="pdp__chooser">
            <label class="label">Size: <span class="pdp__selected-label" data-size-label></span></label>
            <div class="pdp__sizes" data-sizes></div>
            <span class="pdp__stock-hint" data-stock-hint></span>
        </div>
        <div class="pdp__qty">
            <label class="label">Quantity:</label>
            <div class="qty-stepper">
                <button type="button" class="qty-stepper__btn" data-qty-minus aria-label="Decrease quantity">−</button>
                <input type="number" class="qty-stepper__input" data-qty-input value="1" min="1" max="10" aria-label="Quantity">
                <button type="button" class="qty-stepper__btn" data-qty-plus aria-label="Increase quantity">+</button>
            </div>
        </div>
        <div class="pdp__cta">
            <button class="btn-primary" data-add-to-cart disabled>Select a size</button>
        </div>
        <button class="pdp__compare-link" data-compare-add>+ Add to compare</button>
        <div class="pdp__tabs">
            <div class="pdp__tab-nav" role="tablist">
                <button class="pdp__tab pdp__tab--active" role="tab" data-tab="description" aria-selected="true">Description</button>
                <button class="pdp__tab" role="tab" data-tab="care">Care</button>
                <button class="pdp__tab" role="tab" data-tab="attributes">Attributes</button>
            </div>
            <div class="pdp__tab-panel pdp__tab-panel--active" data-panel="description">
                <p data-description></p>
            </div>
            <div class="pdp__tab-panel" data-panel="care">
                <p data-care></p>
            </div>
            <div class="pdp__tab-panel" data-panel="attributes">
                <dl data-attrs></dl>
            </div>
        </div>
    </div>
    <section class="pdp__reviews" data-reviews>
        <h2>Customer Reviews</h2>
        <div class="pdp__reviews-summary" data-reviews-summary></div>
        <div class="pdp__review-form-slot" data-review-form-slot></div>
        <div class="pdp__reviews-list" data-reviews-list></div>
    </section>
</div>
</cfoutput>
