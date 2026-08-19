// assets/js/components/facets.js

export function Facets(facets, activeFilters = {}) {
  if (!facets) return '';
  const hasActive = activeFilters.category || activeFilters.colors || activeFilters.size || activeFilters.priceMin || activeFilters.fit;
  return `
    <div class="facets">
      <div class="facets__header">
        <h3 class="facets__title">Filters</h3>
        <button class="facets__clear ${hasActive ? '' : 'facets__clear--hidden'}" data-clear-filters>Clear All</button>
      </div>
      ${CategoryFacet(facets.category, activeFilters.category)}
      ${SizeFacet(facets.size, activeFilters.size)}
      ${ColorFacet(facets.color, activeFilters.colors)}
      ${PriceFacet(facets.priceBuckets, activeFilters.priceMin, activeFilters.priceMax)}
      ${FitFacet(facets.fit, activeFilters.fit)}
    </div>
  `;
}

function CategoryFacet(categories, active) {
  if (!categories || !categories.length) return '';
  const activeList = active ? active.split(',') : [];
  return `
    <div class="facet">
      <h4 class="facet__title">Category</h4>
      <div class="facet__options">
        ${categories.map(cat => `
          <label class="facet__option">
            <input type="checkbox" name="category" value="${cat.value}" ${activeList.includes(cat.value) ? 'checked' : ''}>
            <span>${cat.label}</span>
            <span class="facet__count">(${cat.count})</span>
          </label>
        `).join('')}
      </div>
    </div>
  `;
}

function SizeFacet(sizeGroups, active) {
  if (!sizeGroups || !sizeGroups.length) return '';
  return `
    <div class="facet">
      <h4 class="facet__title">Size</h4>
      ${sizeGroups.map(group => `
        <div class="facet__size-group">
          <span class="facet__size-group-label">${group.label}</span>
          <div class="facet__options facet__options--chips">
            ${group.sizes.map(size => `
              <button type="button" class="facet__chip ${active === size.value ? 'facet__chip--active' : ''}" name="size" data-value="${size.value}">
                ${size.value}
              </button>
            `).join('')}
          </div>
        </div>
      `).join('')}
    </div>
  `;
}

function ColorFacet(colors, activeColors) {
  if (!colors || !colors.length) return '';
  const active = activeColors ? activeColors.split(',') : [];
  return `
    <div class="facet">
      <h4 class="facet__title">Color</h4>
      <div class="facet__options facet__options--colors">
        ${colors.map(color => `
          <label class="facet__swatch" title="${color.value}">
            <input type="checkbox" name="colors" value="${color.value}" ${active.includes(color.value) ? 'checked' : ''}>
            <span class="color-swatch color-swatch--lg" style="background:${color.swatch}"></span>
          </label>
        `).join('')}
      </div>
    </div>
  `;
}

function PriceFacet(buckets, priceMin, priceMax) {
  if (!buckets || !buckets.length) return '';
  const allBuckets = [...buckets];
  if (!allBuckets.find(b => b.min >= 500)) {
    allBuckets.push({ min: 500, max: 99999, count: 0 });
  }
  return `
    <div class="facet">
      <h4 class="facet__title">Price</h4>
      <div class="facet__options">
        ${allBuckets.map(b => {
          const isActive = +priceMin === b.min && +priceMax === b.max;
          const label = b.min >= 500 ? `$${b.min}+` : `$${b.min} - $${b.max}`;
          return `
            <label class="facet__option">
              <input type="radio" name="price" value="${b.min},${b.max}" ${isActive ? 'checked' : ''}>
              <span>${label}</span>
            </label>
          `;
        }).join('')}
      </div>
    </div>
  `;
}

function FitFacet(fits, active) {
  if (!fits || !fits.length) return '';
  const activeList = active ? active.split(',') : [];
  return `
    <div class="facet">
      <h4 class="facet__title">Fit</h4>
      <div class="facet__options">
        ${fits.map(fit => `
          <label class="facet__option">
            <input type="checkbox" name="fit" value="${fit.value}" ${activeList.includes(fit.value) ? 'checked' : ''}>
            <span>${fit.label}</span>
            <span class="facet__count">(${fit.count})</span>
          </label>
        `).join('')}
      </div>
    </div>
  `;
}
