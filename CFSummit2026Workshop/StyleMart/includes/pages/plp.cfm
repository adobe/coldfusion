<cfoutput>
<nav class="breadcrumb" aria-label="Breadcrumb" data-breadcrumb>
    <a href="index.cfm">Home</a> <span class="breadcrumb__sep">›</span>
    <span>Shop</span>
</nav>
<div class="plp">
    <aside class="plp__facets" data-facets aria-label="Product filters"></aside>
    <div class="plp__main">
        <div class="plp__bar">
            <span data-result-count>Loading…</span>
            <div class="applied-filters" data-applied-filters></div>
            <select class="plp__sort" data-sort aria-label="Sort products">
                <option value="">Sort by</option>
                <option value="price-asc">Price: Low to High</option>
                <option value="price-desc">Price: High to Low</option>
                <option value="newest">Newest</option>
                <option value="rating">Top Rated</option>
                <option value="popularity">Most Popular</option>
            </select>
        </div>
        <div class="product-grid" data-plp-grid></div>
        <div class="plp__status" data-plp-status hidden></div>
        <div class="plp__sentinel" data-plp-sentinel aria-hidden="true"></div>
    </div>
</div>
</cfoutput>
