# Drift Experiment Decision Memo

**Created:** Before first exposure  
**Hypothesis:** Consequence-framed financial drift insights generate more attention than trend-framed drift insights.  
**NOT testing:** Whether insights help users change behavior.

---

## Experiment Design

- **Signal:** Spending drift (category with 3+ month sustained directional change >20%)
- **Variant A (trend):** "Food Delivery ↑ 41% over 4 months"
- **Variant B (consequence):** "Cutting Food Delivery to its old level saves ₹7,200/year"
- **Assignment:** Stable hash(userId + categoryId) — deterministic, no flip-flopping
- **Cooldown:** 7 days per category
- **Ranking:** By yearly financial impact (not percentage)

## Minimum Evaluation Dataset

- **300 displayed exposures** (`displayedAt != null`)
- **Across 100 unique users** (distinct `userId`)

## Kill Criteria (Pre-committed — DO NOT CHANGE after seeing data)

| Overall CTR | Decision |
|---|---|
| < 5% | **Kill.** Remove feature. Test different signal type (anomaly, budget-vs-actual). |
| 5–8% after 300/100 | **Extend** to 600 exposures / 200 users. If still 5–8%, kill. |
| 8–12% | **Segment.** If high-impact (>₹15k/year) is >15% CTR, keep with minimum threshold. If flat across segments, kill. |
| > 12% | **Expand.** Build next skill using winning framing. |

## A/B Winner Criteria

- Consequence must outperform trend by **≥30% relative CTR** to become default.
- Example: 13% vs 10% = 30% relative lift → consequence wins.
- If < 30% relative difference → variants are equivalent. Default to consequence (more actionable).

## High-Impact Only Scenario

If CTR segments as:
- \>15% for ₹15k+ annual impact
- < 5% for < ₹5k impact

**Decision:** Keep drift, add minimum impact threshold to detector. Not "drift failed."

## Coverage Diagnostic (Check at 50 exposures)

- If < 20% of users with 3+ months of snapshots generate a drift → detector has coverage problem
- Fix detector before evaluating framing
- Category fragmentation (Swiggy/Zomato/Restaurant = 3 categories) is the likely cause

## Metrics Dashboard

All answerable from `InsightExposure` collection:

| Metric | Query |
|---|---|
| Exposures | count where displayedAt != null |
| Unique users | distinct userId where displayedAt != null |
| Users generating drift | distinct userId in all exposures |
| Trend CTR (exposure) | clicked / displayed where variant == 'trend' |
| Consequence CTR (exposure) | clicked / displayed where variant == 'consequence' |
| Trend CTR (per-user) | users_clicked / users_seen where variant == 'trend' |
| Consequence CTR (per-user) | users_clicked / users_seen where variant == 'consequence' |
| High-impact CTR | clicked / displayed where impactAmount > 15000 |
| Low-impact CTR | clicked / displayed where impactAmount < 5000 |
| Dismiss rate | dismissed / displayed |
| Median impact | median(impactAmount) where displayed |
| Detail view rate | viewedDetails / clicked |

## What success DOES NOT prove

- That insights help users change behavior
- That users want AI financial features
- That natural language querying is needed
- That financial memory graphs are valuable

## What failure DOES NOT prove

- That financial insights don't work
- That personal finance AI is wrong
- That the app can't grow

## The contract

If 2.7% CTR across 700 exposures and 300 users → **delete the feature**.  
Don't "improve the detector." Don't "try better copy."  
Accept that spending drift doesn't create enough tension. Move to next hypothesis.
