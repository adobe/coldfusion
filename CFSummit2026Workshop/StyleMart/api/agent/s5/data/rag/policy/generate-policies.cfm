<cfscript>
policyDir = getDirectoryFromPath(getCurrentTemplatePath());

policies = [
    {
        file: "returns-policy.pdf",
        title: "StyleMart Returns & Exchange Policy",
        content: "
RETURNS & EXCHANGE POLICY

Effective Date: January 1, 2026

1. RETURN WINDOW
All items may be returned within 30 days of delivery for a full refund to the original payment method. Items must be unworn, unwashed, and in original condition with tags attached.

2. EXCHANGE POLICY
Exchanges are available for size or color swaps within 30 days. If the desired variant is out of stock, a full refund is issued automatically.

3. SALE ITEMS
Items purchased at a discount of 40% or more are final sale and cannot be returned or exchanged. Items at less than 40% discount follow standard return policy.

4. SHIPPING COSTS
Return shipping is free for all US orders. International returns require the customer to cover return shipping costs. Exchange shipments are always free.

5. REFUND PROCESSING
Refunds are processed within 5-7 business days after we receive the returned item. Credit card refunds may take an additional 3-5 business days to appear on your statement.

6. DAMAGED OR DEFECTIVE ITEMS
If you receive a damaged or defective item, contact us within 48 hours of delivery for an immediate replacement or refund. No return shipping required for defective items.

7. GIFT RETURNS
Items purchased as gifts can be returned for store credit only. Gift receipts are required for gift returns."
    },
    {
        file: "wool-care.pdf",
        title: "StyleMart Wool & Delicate Fabric Care Guide",
        content: "
WOOL & DELICATE FABRIC CARE GUIDE

WOOL-BLEND JACKETS AND BLAZERS
Wool-blend jackets (containing 50% or more wool) can be machine-washed on a cold/delicate cycle (30C or below). Use a mesh laundry bag to prevent snagging. Tumble dry on low heat for no more than 10 minutes, then reshape while damp and lay flat to finish drying. Do not wring or twist. Steam or low-iron on the wool setting if needed.

PURE WOOL ITEMS
Items labeled 100% wool should be dry-cleaned or hand-washed only. If hand-washing: use cold water with a wool-specific detergent, soak for 5 minutes maximum, gently press water out (never wring), roll in a towel to absorb moisture, then lay flat to dry away from direct heat or sunlight.

CASHMERE
Cashmere items must be hand-washed in cold water with a cashmere-specific cleanser. Lay flat to dry on a clean towel. Do not hang cashmere items as they will stretch. Fold for storage; never use hangers. Pilling is normal for the first few wears — use a cashmere comb to remove.

SILK
Silk items should be hand-washed in cold water or dry-cleaned. Do not use bleach or fabric softener. Iron on low heat while slightly damp, using a pressing cloth between iron and fabric.

LINEN
Linen can be machine-washed on a gentle cycle with cold or lukewarm water. Linen wrinkles naturally — embrace it or iron while damp on medium-high heat. Do not tumble dry; hang or lay flat to air dry."
    },
    {
        file: "general-care.pdf",
        title: "StyleMart General Garment Care Instructions",
        content: "
GENERAL GARMENT CARE INSTRUCTIONS

COTTON T-SHIRTS AND CASUAL TOPS
Machine wash cold with like colors. Tumble dry low or hang to dry. Iron on medium heat if needed. Avoid bleach on colored items.

DENIM AND JEANS
Turn inside out before washing. Machine wash cold. Hang to dry to preserve fit and color. Wash infrequently (every 4-5 wears) to maintain shape and reduce fading.

SYNTHETIC FABRICS (POLYESTER, NYLON, SPANDEX)
Machine wash cold on gentle cycle. Tumble dry low or hang to dry. Do not iron at high temperatures — synthetics melt. Avoid fabric softener with moisture-wicking garments.

OUTERWEAR AND COATS
Check care label — some outerwear requires professional cleaning. Water-resistant coats should not be dry-cleaned as it removes the DWR coating. Re-apply DWR spray after every 5 washes.

LEATHER AND FAUX LEATHER
Wipe clean with a damp cloth. Apply leather conditioner every 3-6 months. Store on padded hangers in a cool, dry place. Never machine wash or dry clean real leather.

COLOR PRESERVATION
Wash dark colors in cold water inside-out. Use color-safe detergent. Avoid overloading the washing machine. Remove items promptly after wash cycle ends to prevent dye transfer.

STAIN TREATMENT
Treat stains immediately — blot, don't rub. Use cold water for protein-based stains (blood, sweat). Use warm water for oil-based stains. Test stain remover on an inconspicuous area first."
    },
    {
        file: "size-guide-tops.pdf",
        title: "StyleMart Size Guide — Tops & Outerwear",
        content: "
SIZE GUIDE: TOPS, SHIRTS, AND OUTERWEAR

MEASUREMENT INSTRUCTIONS
Chest: Measure around the fullest part of your chest, keeping the tape horizontal.
Waist: Measure around your natural waistline, above the hip bone.
Sleeve: Measure from center back of neck, across shoulder, down to wrist.

WOMEN'S SIZING
| Size | Chest (in) | Waist (in) | Sleeve (in) |
| XS   | 32-33      | 25-26      | 30          |
| S    | 34-35      | 27-28      | 30.5        |
| M    | 36-37      | 29-30      | 31          |
| L    | 38-40      | 31-33      | 31.5        |
| XL   | 41-43      | 34-36      | 32          |
| 2XL  | 44-46      | 37-39      | 32.5        |

MEN'S SIZING
| Size | Chest (in) | Waist (in) | Sleeve (in) |
| XS   | 34-35      | 28-29      | 32          |
| S    | 36-37      | 30-31      | 33          |
| M    | 38-40      | 32-34      | 34          |
| L    | 41-43      | 35-37      | 35          |
| XL   | 44-46      | 38-40      | 35.5        |
| 2XL  | 47-49      | 41-43      | 36          |
| 3XL  | 50-52      | 44-46      | 36.5        |

FIT GUIDE
Slim Fit: Contoured close to the body. If between sizes, size up.
Regular Fit: Standard cut with moderate ease. True to size.
Relaxed Fit: Generous room through chest and waist. If between sizes, size down.
Oversized: Intentionally loose. Order your normal size for the oversized look."
    },
    {
        file: "size-guide-bottoms.pdf",
        title: "StyleMart Size Guide — Bottoms & Footwear",
        content: "
SIZE GUIDE: JEANS, PANTS, AND FOOTWEAR

JEANS AND PANTS — MEASUREMENT INSTRUCTIONS
Waist: Measure where you typically wear your pants.
Hip: Measure around the fullest part of your hips.
Inseam: Measure from crotch seam to hem of a well-fitting pair of pants.

WOMEN'S JEANS SIZING
| Size | Waist (in) | Hip (in) | Inseam (in) |
| 24   | 24-25      | 34-35    | 28/30/32    |
| 25   | 25-26      | 35-36    | 28/30/32    |
| 26   | 26-27      | 36-37    | 28/30/32    |
| 27   | 27-28      | 37-38    | 28/30/32    |
| 28   | 28-29      | 38-39    | 28/30/32    |
| 29   | 29-30      | 39-40    | 28/30/32    |
| 30   | 30-31      | 40-41    | 28/30/32    |
| 31   | 31-32      | 41-42    | 28/30/32    |
| 32   | 32-33      | 42-43    | 28/30/32    |

MEN'S JEANS SIZING
| Size | Waist (in) | Hip (in) | Inseam (in) |
| 28   | 28-29      | 36-37    | 30/32/34    |
| 30   | 30-31      | 38-39    | 30/32/34    |
| 32   | 32-33      | 40-41    | 30/32/34    |
| 34   | 34-35      | 42-43    | 30/32/34    |
| 36   | 36-37      | 44-45    | 30/32/34    |
| 38   | 38-39      | 46-47    | 30/32/34    |

FOOTWEAR
| US Size | EU Size | UK Size | Foot Length (cm) |
| 6       | 39      | 5.5     | 24.5             |
| 7       | 40      | 6.5     | 25.0             |
| 8       | 41      | 7.5     | 25.5             |
| 9       | 42      | 8.5     | 26.5             |
| 10      | 43      | 9.5     | 27.0             |
| 11      | 44      | 10.5    | 27.5             |
| 12      | 45      | 11.5    | 28.5             |

DENIM FIT TYPES
Skinny: Fitted through hip and thigh, narrow leg. Low stretch — size up if unsure.
Slim: Close fit, slight taper. Medium stretch.
Straight: Even width from hip to hem. Classic cut.
Relaxed: Generous through seat and thigh. Comfortable daily wear.
Wide Leg: Fitted waist, wide from hip to hem. Fashion-forward."
    }
];

for (p in policies) {
    filePath = policyDir & p.file;

    htmlContent = "<html><body>";
    htmlContent &= "<h1>#encodeForHTML(p.title)#</h1>";
    htmlContent &= "<pre style='font-family: Arial, sans-serif; font-size: 11pt; white-space: pre-wrap;'>#encodeForHTML(p.content)#</pre>";
    htmlContent &= "</body></html>";

    cfDocument(format="pdf", filename="#filePath#", overwrite="true") {
        writeOutput(htmlContent);
    }

    writeOutput("Generated: #p.file#<br>");
}
writeOutput("<br>Done. All policy PDFs generated.");
</cfscript>
