<cfoutput>
<div class="checkout" data-checkout-root>
    <div class="checkout__stepper" data-stepper>
        <div class="stepper__step stepper__step--active" data-step-ind="1"><span class="stepper__num">1</span> Shipping</div>
        <div class="stepper__sep"></div>
        <div class="stepper__step" data-step-ind="2"><span class="stepper__num">2</span> Payment</div>
        <div class="stepper__sep"></div>
        <div class="stepper__step" data-step-ind="3"><span class="stepper__num">3</span> Review</div>
    </div>

    <div class="checkout__content">
        <div class="checkout__steps">
            <!--- Step 1: Shipping --->
            <div class="checkout__step checkout__step--active" data-step="1">
                <h2>Shipping Address</h2>
                <form data-shipping-form>
                    <div class="form-row">
                        <label>Full Name</label>
                        <input type="text" name="name" placeholder="Jordan Lee" required>
                    </div>
                    <div class="form-row">
                        <label>Email</label>
                        <input type="email" name="email" placeholder="you@example.com" required>
                    </div>
                    <div class="form-row">
                        <label>Phone</label>
                        <input type="tel" name="phone" placeholder="+1 (555) 000-0000" required>
                    </div>
                    <div class="form-row">
                        <label>Street Address</label>
                        <input type="text" name="line1" placeholder="123 Main St" required>
                    </div>
                    <div class="form-row form-row--split">
                        <div>
                            <label>City</label>
                            <input type="text" name="city" placeholder="San Francisco" required>
                        </div>
                        <div>
                            <label>State / Province</label>
                            <input type="text" name="state" placeholder="CA" required>
                        </div>
                    </div>
                    <div class="form-row form-row--split">
                        <div>
                            <label>ZIP / Postal Code</label>
                            <input type="text" name="zip" placeholder="94102" required>
                        </div>
                        <div>
                            <label>Country</label>
                            <select name="country" required>
                                <option value="US" selected>United States</option>
                                <option value="CA">Canada</option>
                                <option value="GB">United Kingdom</option>
                                <option value="AU">Australia</option>
                                <option value="DE">Germany</option>
                                <option value="FR">France</option>
                                <option value="IN">India</option>
                                <option value="JP">Japan</option>
                            </select>
                        </div>
                    </div>
                    <button type="submit" class="btn-primary checkout__next-btn">Continue to Payment</button>
                </form>
            </div>

            <!--- Step 2: Payment --->
            <div class="checkout__step" data-step="2" style="display:none">
                <h2>Payment Method</h2>
                <form data-payment-form>
                    <div class="form-row">
                        <label>Card Number</label>
                        <input type="text" name="cardNumber" placeholder="4242 4242 4242 4242" maxlength="19" required>
                    </div>
                    <div class="form-row form-row--split">
                        <div>
                            <label>Expiry</label>
                            <input type="text" name="expiry" placeholder="MM/YY" maxlength="5" required>
                        </div>
                        <div>
                            <label>CVV</label>
                            <input type="text" name="cvv" placeholder="123" maxlength="4" required>
                        </div>
                    </div>
                    <div class="form-row">
                        <label>Name on Card</label>
                        <input type="text" name="cardName" placeholder="Jordan Lee" required>
                    </div>
                    <p class="checkout__secure-note">This is a workshop demo. No real charges will be made.</p>
                    <div class="checkout__btn-row">
                        <button type="button" class="btn-secondary checkout__back-btn" data-back="1">Back</button>
                        <button type="submit" class="btn-primary checkout__next-btn">Review Order</button>
                    </div>
                </form>
            </div>

            <!--- Step 3: Review --->
            <div class="checkout__step" data-step="3" style="display:none">
                <h2>Review & Place Order</h2>
                <div class="checkout__review" data-review-content></div>
                <div class="checkout__btn-row">
                    <button type="button" class="btn-secondary checkout__back-btn" data-back="2">Back</button>
                    <button type="button" class="btn-primary checkout__place-btn" data-place-order>Place Order</button>
                </div>
            </div>
        </div>

        <aside class="checkout__summary" data-checkout-summary>
            <p>Loading order summary...</p>
        </aside>
    </div>
</div>
</cfoutput>
