<cfoutput>
<div class="cart" data-cart-root>
    <div class="cart__header">
        <h1>Your cart</h1>
        <a href="products.cfm" class="cart__continue">&larr; Continue shopping</a>
    </div>
    <div data-pending-slot></div>
    <div class="cart__layout">
        <div data-cart-items class="cart__items"></div>
        <aside class="cart__summary">
            <div class="cart-summary__row"><span>Subtotal</span><span data-subtotal>$0.00</span></div>
            <div class="cart-summary__row cart-summary__discount" style="display:none"><span>Discount</span><span data-discount-total>$0.00</span></div>
            <div data-coupon-slot class="cart-summary__coupon"></div>
            <div class="cart-summary__row cart-summary__total"><span>Total</span><span data-cart-total>$0.00</span></div>
            <a class="btn-primary cart__checkout-btn" href="checkout.cfm">Checkout</a>
            <a class="btn-secondary cart__upsell-btn" href="capsule.cfm?capsule=jordan-london">Complete your capsule &rarr;</a>
            <a class="btn-ghost cart__abandon-btn" href="email-preview.cfm?from=abandon" data-abandon-btn>I&rsquo;ll finish this later</a>
        </aside>
    </div>
</div>
</cfoutput>
