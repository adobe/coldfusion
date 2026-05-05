/**
 * FinancialTool - Financial calculations and conversions for AI function-calling demo.
 * Provides mortgage calculator, currency conversion, ROI, tax estimation and stock lookup.
 */
component {

    /**
     * Calculate monthly mortgage payment
     * @mcpTool true
     * @mcpDescription Calculate monthly mortgage payment and total interest for a loan. Returns monthly payment, total paid, and total interest over the loan term.
     * @principal Loan amount in USD (e.g. 400000)
     * @annualRate Annual interest rate as a percentage (e.g. 6.5 for 6.5%)
     * @termYears Loan term in years (e.g. 30)
     * @return Struct with monthlyPayment, totalPaid, totalInterest, and amortisation summary
     */
    remote struct function calculateMortgage(required numeric principal, required numeric annualRate, required numeric termYears) {
        var r = arguments.annualRate / 100 / 12;
        var n = arguments.termYears * 12;
        var monthly = 0;

        if (r == 0) {
            monthly = arguments.principal / n;
        } else {
            monthly = arguments.principal * (r * (1+r)^n) / ((1+r)^n - 1);
        }
        monthly = int(monthly * 100) / 100;
        var total = monthly * n;
        return {
            principal:      arguments.principal,
            annualRate:     arguments.annualRate,
            termYears:      arguments.termYears,
            monthlyPayment: monthly,
            totalPaid:      int(total * 100) / 100,
            totalInterest:  int((total - arguments.principal) * 100) / 100,
            payoffYear:     year(now()) + arguments.termYears
        };
    }

    /**
     * Convert an amount between currencies using indicative exchange rates
     * @mcpTool true
     * @mcpDescription Convert an amount between currencies using indicative exchange rates. Supports USD, EUR, GBP, JPY, INR, AUD, CAD, CHF, SGD.
     * @amount The amount to convert
     * @fromCurrency Source currency code (USD, EUR, GBP, JPY, INR, AUD, CAD)
     * @toCurrency   Target currency code
     * @return Struct with converted amount and exchange rate used
     */
    remote struct function convertCurrency(required numeric amount, required string fromCurrency, required string toCurrency) {
        // Rates relative to USD (indicative)
        var toUSD = { USD:1.0, EUR:1.08, GBP:1.27, JPY:0.0067, INR:0.012, AUD:0.64, CAD:0.74, CHF:1.12, SGD:0.75 };
        var from = uCase(trim(arguments.fromCurrency));
        var to   = uCase(trim(arguments.toCurrency));

        if (!structKeyExists(toUSD, from)) return { error:"Unknown source currency: #from#. Supported: #structKeyList(toUSD)#" };
        if (!structKeyExists(toUSD, to))   return { error:"Unknown target currency: #to#. Supported: #structKeyList(toUSD)#" };

        var usdAmount    = arguments.amount * toUSD[from];
        var converted    = usdAmount / toUSD[to];
        var rate         = toUSD[from] / toUSD[to];
        return {
            from:            from,
            to:              to,
            originalAmount:  arguments.amount,
            convertedAmount: int(converted * 100) / 100,
            exchangeRate:    int(rate * 10000) / 10000,
            note:            "Indicative rates only — not for financial transactions"
        };
    }

    /**
     * Calculate return on investment (ROI) and compound annual growth rate (CAGR)
     * @mcpTool true
     * @mcpDescription Calculate return on investment (ROI) and compound annual growth rate (CAGR) for an investment. Returns profit/loss, ROI percentage, and CAGR.
     * @initialInvestment Amount invested initially in USD
     * @finalValue Current or projected value in USD
     * @years Number of years the investment was held
     * @return Struct with ROI percentage, profit/loss, and CAGR
     */
    remote struct function calculateROI(required numeric initialInvestment, required numeric finalValue, required numeric years) {
        if (arguments.initialInvestment <= 0) return { error:"Initial investment must be greater than zero" };
        var profit = arguments.finalValue - arguments.initialInvestment;
        var roi    = (profit / arguments.initialInvestment) * 100;
        var cagr   = (arguments.years > 0) ? ((arguments.finalValue / arguments.initialInvestment)^(1 / arguments.years) - 1) * 100 : 0;
        return {
            initialInvestment: arguments.initialInvestment,
            finalValue:        arguments.finalValue,
            years:             arguments.years,
            profit:            int(profit * 100) / 100,
            roiPercent:        int(roi * 100) / 100,
            cagrPercent:       int(cagr * 100) / 100,
            performance:       (roi >= 0) ? "Gain" : "Loss"
        };
    }

    /**
     * Estimate US federal income tax based on 2025 tax brackets
     * @mcpTool true
     * @mcpDescription Estimate US federal income tax based on 2025 tax brackets. Returns estimated tax, effective rate, and bracket breakdown.
     * @annualIncome Gross annual income in USD
     * @filingStatus Filing status: single, married_joint, married_separate, head_of_household
     * @return Struct with estimated federal tax, effective rate, and bracket breakdown
     */
    remote struct function estimateTax(required numeric annualIncome, string filingStatus = "single") {
        // 2025 approximate brackets for single filer
        var brackets = [
            { min:0,       max:11925,  rate:10 },
            { min:11925,   max:48475,  rate:12 },
            { min:48475,   max:103350, rate:22 },
            { min:103350,  max:197300, rate:24 },
            { min:197300,  max:250525, rate:32 },
            { min:250525,  max:626350, rate:35 },
            { min:626350,  max:999999999, rate:37 }
        ];
        var standardDeduction = 14600; // 2025 single
        var taxableIncome = max(0, arguments.annualIncome - standardDeduction);
        var totalTax = 0;
        var breakdown = [];

        for (var bracket in brackets) {
            if (taxableIncome <= bracket.min) break;
            var taxable = min(taxableIncome, bracket.max) - bracket.min;
            var tax = taxable * (bracket.rate / 100);
            totalTax += tax;
            arrayAppend(breakdown, { rate:"#bracket.rate#%", taxable:int(taxable), tax:int(tax) });
        }

        return {
            grossIncome:       arguments.annualIncome,
            standardDeduction: standardDeduction,
            taxableIncome:     int(taxableIncome),
            estimatedTax:      int(totalTax),
            effectiveRate:     (arguments.annualIncome > 0) ? int(totalTax / arguments.annualIncome * 10000) / 100 : 0,
            takeHomePay:       int((arguments.annualIncome - totalTax) * 100) / 100,
            brackets:          breakdown,
            note:              "Estimate only — consult a tax professional for accurate calculation"
        };
    }

    /**
     * Look up a simulated stock quote for well-known ticker symbols
     * @mcpTool true
     * @mcpDescription Look up a simulated stock quote for well-known ticker symbols. Returns price, daily change, market cap, P/E ratio, and sector.
     * @symbol Stock ticker symbol (e.g. ADBE, AAPL, MSFT, GOOGL, AMZN, TSLA)
     * @return Struct with price, change, market cap and company info
     */
    remote struct function getStockQuote(required string symbol) {
        var stocks = {
            "ADBE": { name:"Adobe Inc.",             price:412.50, change:+3.20, changePct:+0.78, marketCap:"$182B", pe:28.4, sector:"Technology" },
            "AAPL": { name:"Apple Inc.",             price:189.30, change:-1.10, changePct:-0.58, marketCap:"$2.94T", pe:29.1, sector:"Technology" },
            "MSFT": { name:"Microsoft Corporation",  price:415.80, change:+5.60, changePct:+1.37, marketCap:"$3.09T", pe:35.2, sector:"Technology" },
            "GOOGL":{ name:"Alphabet Inc.",          price:171.90, change:+2.40, changePct:+1.42, marketCap:"$2.13T", pe:22.7, sector:"Technology" },
            "AMZN": { name:"Amazon.com Inc.",        price:195.60, change:-0.80, changePct:-0.41, marketCap:"$2.09T", pe:44.1, sector:"Consumer Cyclical" },
            "TSLA": { name:"Tesla Inc.",             price:172.30, change:-4.50, changePct:-2.55, marketCap:"$549B",  pe:52.3, sector:"Consumer Cyclical" },
            "NVDA": { name:"NVIDIA Corporation",     price:875.40, change:+12.30,changePct:+1.43, marketCap:"$2.15T", pe:68.9, sector:"Technology" },
            "CRM":  { name:"Salesforce Inc.",        price:298.70, change:+1.90, changePct:+0.64, marketCap:"$288B",  pe:43.2, sector:"Technology" }
        };

        var sym = uCase(trim(arguments.symbol));
        if (!structKeyExists(stocks, sym)) {
            return { error:"Symbol '#sym#' not found. Available: #structKeyList(stocks)#" };
        }
        var s = stocks[sym];
        s["symbol"] = sym;
        s["asOf"] = dateTimeFormat(now(), "yyyy-mm-dd HH:nn");
        s["note"] = "Simulated data for demo purposes only";
        return s;
    }
}
