---
layout: post
title: "From Forecasts to Allocation: Demand Estimation, Elasticity, and Simulation-Based Decision Optimization"
subtitle: "Latent Linkage, Demand Estimation, and Simulation-Based Allocation Under Uncertainty" 
optimized_image: /files/generic.png
category: Writings
tags:
  - Education
  - Empirical Methodology
math: true
toc: true
---

# Introduction

Allocation decisions are often made under partial information. At the decision point, the analyst observes a finite set of ex-ante covariates: prevailing market prices, estimated velocity, unit costs, discount structure, timing, category characteristics, and subjective forecasts. Ex-post, the decision-maker observes realized prices, realized demand, sell-through, liquidation timing, and return on capital. The methodological problem is to connect these two information sets in a way that supports both retrospective evaluation and prospective optimization.

This post develops a probabilistic framework for that problem. The core object is a predictive distribution over economic outcomes, rather than a point forecast. Price is modeled as a positive, right-skewed stochastic variable; demand is modeled as a count process with overdispersion; and quantity selection is treated as an allocation problem under budget constraints. The framework therefore combines elements of demand estimation, elasticity modeling, latent-variable inference, and simulation-based optimization.

A central complication is that the mapping between initial decision records and realized acquisition outcomes may be only partially observed. I treat this as a latent-linkage problem and use an EM-style approach to infer soft responsibilities between candidate decision records and downstream outcomes. This avoids imposing brittle deterministic matches while preserving uncertainty in the estimation stage.

The resulting model has two purposes. First, it provides a disciplined way to evaluate forecast quality and decision quality using only information available at the time of decision. Second, it produces a simulation engine for counterfactual allocation: given estimated price and demand distributions, what quantity should be chosen to maximize expected, or risk-adjusted, profit subject to capital constraints?

In this framing, the question is not simply whether a forecast was accurate. The econometric question is whether the observed decision was optimal relative to the decision-maker's information set, estimated demand curve, and uncertainty over future market outcomes.



# Data

In marketplace settings, the decision-maker often observes a contemporaneous reference price before committing capital. On Amazon, this is typically the Buy Box price: the displayed offer price that Amazon surfaces as the default purchase option for a listing. Because the Buy Box reflects the currently competitive offer, it is a useful proxy for the prevailing market price at the time of decision.

More generally, this variable should be interpreted as the observable market reference price: the price signal available to the decision-maker when the allocation decision is made. In other domains, this might be the best ask, the median competing listing price, the platform-clearing price, or another contemporaneous benchmark.

## Inputs Available at Decision Time

- **Acquisition economics:** unit cost after all purchase-side adjustments, including discounts, rebates, coupons, shipping, handling, and transaction costs.
- **Market reference price:** the observable competitive price signal at the time of decision. In Amazon marketplace settings, this is often the Buy Box price: the default offer price shown to customers and a useful proxy for the currently competitive market price.
- **Demand signal:** observed velocity or another contemporaneous proxy for expected demand.
- **Decision-maker forecasts:** expected sale price, planned quantity, expected return, or other subjective projections made before outcomes are observed.
- **Market structure:** category, platform, source channel, seller competition, listing constraints, seasonality, and other contextual variables.

## Outputs Observed Ex Post

* Realized sale price, fees, and transaction costs
* Units sold, unsold inventory, sell-through rate.
* Time to liquidation or time over a fixed evaluation horizon.
* Realized ROI.

## Decision Variables

- Quantity to allocate or purchase.
- Target sale price or implied pricing expectation.
- Optional policy choices such as holding horizon, liquidation rule, or risk tolerance.

## Modeling Stack

1. **Price forecasting.**
   Predict the likely future sale price distribution for a SKU given decision-time features (prevailing market price, velocity, category, seasonality).

2. **Demand / sell-through forecasting.**
   Predict the probability distribution of units sold within a horizon (e.g., 30/60 days), conditional on price and decision-time signals.

3. **Optimization layer.**
   Combine price and demand forecasts into an ROI distribution. Simulate marginal profit per unit, and allocate purchase quantities under budget constraints to maximize expected (or risk-adjusted) portfolio return.

# Methodological Considerations

The framework has three methodological problems: linking ex-ante decision records to ex-post outcome records, estimating predictive outcome distributions, and translating those distributions into an allocation rule.

## The latent link between decision records and realized outcomes

The data contain two related but imperfectly linked event tables. The first records candidate decisions made under uncertainty: an agent observes an item, market conditions, acquisition economics, and forms expectations about price, demand, and quantity. The second records realized acquisition or allocation events, which later connect to observed outcomes such as realized price, sell-through, liquidation time, and return.

The true parent mapping from decision record to realized acquisition event is not directly observed. In other words, we may observe that a decision was considered and that a transaction later occurred, but not which specific decision record caused or justified that transaction.

### Approaches

- **Rule-based linkage:** construct a heuristic match score using price proximity, time lag, item/source similarity, and other observable constraints. Each acquisition event is assigned to the highest-scoring candidate decision record. Pros: simple, transparent, easy to implement. Cons: imposes hard matches and is fragile when records are noisy or many candidates are plausible.

- **Localized aggregation:** avoid one-to-one matching and instead pool decision and outcome records within narrow windows defined by item, source, time, and acquisition economics. Pros: robust to noisy identifiers and missing links. Cons: loses record-level attribution and can blur heterogeneous decisions within the same window.

- **Latent-variable linkage via EM:** treat the parent decision record for each realized acquisition as unobserved. Estimate soft responsibilities over candidate parent records, then fit the outcome model using those weights. Pros: principled, preserves linkage uncertainty, and integrates naturally with probabilistic outcome models. Cons: more machinery, sensitive to candidate-set construction and prior linkage assumptions.

- **Reduced-form outcome modeling:** model realized outcomes directly as a function of decision-time features without explicitly resolving the acquisition link. Pros: avoids brittle matching and can still recover useful predictive structure. Cons: weaker interpretation, possible attenuation from noisy exposure assignment, and less useful for record-level decision evaluation.

Start with latent-variable linkage via EM. If the candidate links are too noisy or sparse for stable estimation, fall back to localized aggregation over narrow item/source/time windows.

## Outcome modelling

In order to have a portfolio optimization stage, outcome model has to be a predictive distribution, $$f_{p,s}$$. Otherwise, we're just evaluating how good a prediction is, instead of answering "what should should the analyst have chosen".

### Approaches

- **Quantile or conformal models:** estimate a grid of conditional quantiles and recover an empirical predictive distribution from those quantiles. Pros: weak distributional assumptions, flexible tails, and natural calibration checks. Cons: quantile crossing, less smooth simulation behavior, and weaker extrapolation in sparse regions.

- **Parametric distributional regression:** specify explicit outcome distributions and model their parameters as functions of decision-time features. For example, price can be modeled with a LogNormal distribution and demand with a Negative Binomial distribution. Pros: simple, fast, simulation-ready, and compatible with EM weighting. Cons: sensitive to distributional misspecification.

- **Machine-learning distributional models:** use flexible learners such as gradient boosting to estimate either quantiles or distributional parameters. Pros: captures nonlinearities and interactions with limited feature engineering. Cons: more complex to calibrate, less transparent, and easier to overfit when linkage uncertainty is already present.

- **Survival or hazard models:** model demand as a time-to-sale or liquidation process rather than a static count over a fixed horizon. Pros: handles censoring directly and uses timing information efficiently. Cons: requires cleaner event-time data and complicates the downstream allocation simulation.

- **Fully Bayesian hierarchical models:** jointly model linkage uncertainty, outcome distributions, group-level effects, and parameter uncertainty. Pros: coherent uncertainty propagation and natural partial pooling. Cons: computationally expensive and unnecessary for a first implementation.

We will use a parametric distributional regression: LogNormal price and Negative Binomial demand, with parameters estimated from decision-time features and EM linkage weights. This gives a calibrated predictive distribution while keeping the estimation and optimization stages tractable.

## Optimal Strategy

Given predictive distributions for price and demand, the allocation problem can be written as a stochastic program. The decision variable is quantity; the objective is expected profit, expected return, or a risk-adjusted transformation of the simulated profit distribution; and the constraints encode available capital, operational limits, and admissible exposure by item or market segment.

### Approaches

The simplest estimator is risk-neutral: integrate over the predictive outcome distribution and choose the allocation that maximizes expected profit. More conservative policies replace the expectation with a risk-adjusted functional, such as a downside penalty, Value-at-Risk constraint, Conditional Value-at-Risk objective, or lower-quantile profit criterion.

- **Risk-neutral:** maximize expected profit.
- **Risk-adjusted:** penalize variance, loss probability, unsold inventory, or lower-tail outcomes.
- **Tail-risk constrained:** impose VaR or CVaR constraints on portfolio outcomes.
- **Quantile-based:** optimize a conservative profit quantile instead of the mean.

# EM Soft Linkage Between Decision and Outcome Records

## The Problem

The empirical setting contains two event tables with an unobserved parent-child relationship. The first table records ex-ante decision events: an item is evaluated under observed market conditions, acquisition economics, demand signals, and subjective forecasts. The second table records realized acquisition events: quantities are committed, costs are incurred, and subsequent outcomes are observed through downstream sales or inventory records.

The acquisition-to-outcome mapping is observed, so realized price, sell-through, inventory overhang, liquidation timing, and return can be measured conditional on an acquisition event. The decision-to-acquisition mapping, however, is latent. We observe candidate decisions and realized acquisitions, but not the assignment from each acquisition back to the decision record that generated it.

## Expectation-Maximization Explained

The **Expectation-Maximization** algorithm handles latent (unobserved) variables. Here:

- The latent variable is the parent decision record $$L_p$$ for each acquisition event $$p$$.
- We don't observe $$L_p$$, but we can assign *soft responsibilities* $$w_{p,s} \in [0,1]$$: "how much do we believe decision record $$s$$ is the parent of acquisition event $$p$$?"

The process:

1. Guess the parent links (E-step): For each acquisition event, compute weights across candidate decision records, based on plausibility.
2. Fit the outcome model (M-step): Treat the acquisition event's outcome $$Y_p$$ as coming from all candidate decision-time features $$X_s$$, weighted by those responsibilities.
3. Update the weights with the improved outcome model.
4. Repeat until the parameters stabilize.

### Forecast Leakage and Endogenous Linkage

Subjective forecasts are excluded from the linkage kernel to avoid endogenous assignment. If expected return, forecasted price, or expected demand are used to infer the latent decision-to-acquisition mapping, then forecast accuracy becomes part of the assignment mechanism itself.

This creates a mechanical selection problem. Candidate decision records whose forecasts are close to realized outcomes receive higher posterior linkage weights, while records with inaccurate forecasts are downweighted. The model would therefore partially validate forecasts by construction, rather than evaluating them out of sample against realized outcomes.

The linkage kernel is therefore restricted to correspondence variables: timing, item identity, source/channel, and acquisition economics. Forecast variables remain excluded from linkage and are used only after the mapping stage, where they can be evaluated as decision-time beliefs.

### Determinants of Decision-Acquisition Linkage

The linkage kernel is based on correspondence variables, not realized outcomes or subjective forecasts:

- The acquisition occurs after the decision, within a plausible execution window.
- Item identifiers or product attributes are consistent across records.
- Source/channel is consistent across records.
- Realized acquisition cost is consistent with decision-time acquisition economics, including purchase-side adjustments.
- Quantity and availability are operationally plausible.

### Practical Implication

The estimation sequence is:

1. Use correspondence variables such as timing, item identity, source/channel, and acquisition economics to define the linkage kernel.
2. Estimate price and demand distributions using the resulting soft links as observation weights.
3. Evaluate decision-time forecasts and quantities against the fitted outcome distributions and realized outcomes.

This separation is important. Forecasts are not used to construct the mapping between decision records and acquisition records. They are held out of the linkage stage so they can be evaluated as decision-time beliefs: whether predicted prices were calibrated, whether expected demand was realistic, and whether chosen quantities were optimal given the information available at the time.


## EM Method for Decision-to-Acquisition Linkage

We want to link decision records $$s$$ to acquisition records $$p$$, even though the true linkage $$L_p$$ is unobserved.

* If we knew $$L_p$$, we could directly model outcome $$Y_p$$ as a function of the decision-time features $$X_s$$.
* Since we do not know $$L_p$$, we treat it as a latent variable.

The question is: "Given an acquisition event $$p$$ with outcome $$Y_p$$, what is the probability that decision record $$s$$ is its parent?"

The posterior probability can be written as:

$$
P(L_p = s \mid Y_p, X_s ; \theta) = 
\frac{P(Y_p \mid L_p = s, X_s ; \theta) \times P(L_p = s \mid X_s ; \theta)}{P(Y_p \mid X; \theta)}
$$

where:

- The prior, $$P(L_p = s \mid X_s ; \theta)$$, is how likely the decision record is to be the parent before looking at the outcome. For example, if an acquisition occurred soon after the decision record and the acquisition economics line up, then the link is more plausible.
- The likelihood, $$P(Y_p \mid L_p = s, X_s ; \theta)$$, measures how well the observed outcome fits if we assume that $$s$$ is the parent, given the outcome model.
- The denominator normalizes across all candidate decision records so that the posterior probabilities sum to one:

$$
P(Y_p \mid X; \theta) =
\sum_{s'} P(Y_p \mid L_p = s', X_{s'} ; \theta)
\times P(L_p = s' \mid X_{s'} ; \theta)
$$


## E-Step

Given an outcome $$Y_p$$ and the candidate decision records $$X_s$$, estimate how much posterior weight to assign to each possible parent record:

$$
w_{p,s} = P(L_p = s \mid Y_p, X; \theta) =
\frac{
P(Y_p \mid L_p = s, X_s ; \theta)
\times P(L_p = s \mid X_s ; \theta)
}{
\sum_{s'} P(Y_p \mid L_p = s', X_{s'} ; \theta)
\times P(L_p = s' \mid X_{s'} ; \theta)
}
$$

Interpretation:

- Candidate decision records that are more plausible matches receive higher weight.
- Candidate records whose features imply unlikely outcomes receive lower weight.


## M-step (maximization)

If we knew the decision-to-acquisition link, then for every acquisition event $$p$$, we would have outcome $$Y_p$$ and the decision-time features $$X_{L_p}$$, and the likelihood of the data is

$$
\ell(\theta) = \sum_p \log P(Y_p \mid X_{L_p} ; \theta)
$$

However, since we do not observe the parent decision record, we average it over all the weights in the E-step (note the $$X_s$$ instead of $$X_{L_p}$$)

$$
E_{L \mid Y,X} \ell(\theta) =
\sum_p \bigg[ 
\sum_s w_{p,s}   \times \log P(Y_p \mid X_s ; \theta)
\bigg]
$$

Then we iterate $$\theta$$ to maximize 

$$
\max_{\theta} E_{L \mid Y,X} \ell(\theta)
$$

where $$\theta$$ denotes the model parameters and encodes

1. The prior linkage kernel (time/cost proximity to prior match probability)
2. The outcome model, how the ex-ante features predict realized outcomes

Intuition:

- Imagine you copied acquisition event $$p$$ into the dataset once for each candidate decision record $$s$$ 
- Each copy gets the same outcome $$Y_p$$, but different decision-time features 
- You give each copy a weight $$w_{p,s}$$
- You fit your outcome model to this weighted dataset.

Then recompute weights with the updated model. Iterate until convergence.

## Outcome Modelling 

The outcome models connect decision-time information to the downstream optimization problem. Their role is not only to predict realized outcomes, but to represent uncertainty in a form that can be used for simulation, evaluation, and allocation.

They need to satisfy four design goals:

- **Probabilistic:** outputs must be predictive distributions rather than point estimates, so they can support EM estimation and downstream optimization under uncertainty.
- **Scalable:** the approach must handle many items, sources, decision-makers, and market contexts without requiring bespoke models for each unit.
- **Calibratable:** predictive intervals should have interpretable coverage, so a nominal 90% interval should contain realized outcomes approximately 90% of the time.
- **Interpretable:** the models should expose key drivers, systematic biases, and heterogeneity across items or decision-makers, rather than functioning only as black-box predictors.

### Pooling and Sparsity

A key challenge is data sparsity. Many individual items have few observed acquisition or outcome events, and the item × source × decision-maker space is extremely sparse. A model that is too granular will overfit noise, while a model that is too aggregated will erase meaningful heterogeneity.

- **No pooling:** train independent models for each item, source, or decision-maker. This preserves heterogeneity but is noisy and unstable in sparse cells.
- **Complete pooling:** collapse all observations into a single global model. This improves stability but assumes away meaningful differences across items, sources, and decision-makers.
- **Partial pooling:** estimate a global model with regularized group-level effects for items, sources, decision-makers, or categories. This captures heterogeneity while shrinking noisy estimates toward the population mean.

Under partial pooling, rare items or infrequent decision-makers borrow strength from the broader population, while high-volume groups can learn their own adjustments.


### Independence

Price and demand are correlated, but for tractability we start by treating them as independent:

$$
f_{p,s} = P(Y^{price} \mid X_s;\theta)\;\times\;P(Y^{demand} \mid X_s;\theta).
$$

* **Price**: LogNormal distribution, parameters predicted from features.
* **Demand**: Negative Binomial distribution, parameters predicted from features.
* Closed-form likelihoods -> usable in EM, and easy to sample for optimization.

Dependence can be added later (price-conditional demand or copulas).

### Censoring

We face both **right** and **left** censoring:

- Right censoring: at evaluation, we only observe units sold up to time $$T$$. True demand may be higher. If ignored, this biases demand downward and depresses marginal value.
* Left censoring: sometimes initial conditions aren't fully observed (unknown starting inventory, receiving delays, suppressed/gated listings). This can artificially distort modeled demand.

At decision-time we observe:

* Listing velocity, $$V_0$$ (monthly demand at observed market price)
* Market price $$p_0$$

We can use these features to _anchor_ the demand function.

### Elasticity

By definition, price elasticity of demand, $$\epsilon$$

$$
\varepsilon = -\frac{dQ/Q}{dp/p},\quad \Rightarrow\quad \ln Q = -\varepsilon \ln p + C.
$$

Integrating both sides of the equation and transforming,

$$
\begin{align*}
\ln(Q) &= - \epsilon \ln p + c \\
Q &= p^{-\epsilon} e^c \\
&= K p^{-\epsilon} 
\end{align*}
$$

Demand at $$(V_0, p_0)$$ is

$$
V_0 = K p_0^{-\epsilon} \Rightarrow k = V_0 P_0^{\epsilon}
$$

Then for any other price $$p$$

$$
\begin{align*}
Q(p) &= K p^{-\epsilon} \\
&=  V_0 p_0^{\epsilon} p^{-\epsilon} \\
&= V_0 \times \frac{p}{p_0}^{-\epsilon}
\end{align*}
$$

So the demand curve has the form $$Q(p) = V_0 \times \frac{p}{p_0}^{-\epsilon}$$. 

Interpretation:

- At $$ p=p_0 $$, mean demand approximately $$ V_0 $$
- If $$ p < p_0$$, demand scales up

We can also add scaling terms

- $$T/30$$ to scale for a given horizon, $$T$$ 
- marketshare $$M$$ to adjust for the impact of our control of the portion of units sold at price $$p$$, which can simply be $$M = \min\(1, \frac{q_s}{V_0}\)$$, planned buy quantity as a proxy for marketshare. If we planned to buy more than velocity, then we we take the generous assumption that we own the listing.



#### Estimating Elasticity As A Function Of Velocity

Assumption: high velocity SKUs attract more sellers, so demand is more price-sensitive. Slow SKUs are less so.

Counter point: Monopolistic listings.

Specifying elasticity as 

$$
\epsilon_i = \alpha + \beta \log V_{0,i}
$$

where parameters

- $$\alpha$$ is baseline elasticity
- $$\beta$$ marginal effect of velocity on elasticity, or how elasticity steepens with velocity

and have to be estimated.

We may set heuristic parameters when velocity is (low, medium, high) and assign elasticity values as a first pass.

Or, given the definition of elasticity is from log-quantity over log-price, we can specify a linear model whereby the parameter is exactly that, and driven by baseline velocity.

We can estimate this is a few ways. Heuristically, we can assign low/medium/high velocity bands to elasticities (e.g. 0.5, 1.0, 2.0), or pool data and estimate a log-log demand function which marginal effects that give our desired elasticity parameters.

$$
\ln Q = \beta_0 + \alpha \ln p + \beta \log p \times \ln V_0 + \gamma \ln V_0 + u
$$

Then, marginal effect of log price on log demand gives

$$
\frac{\delta \ln Q}{\delta \ln p} = \alpha+ \beta \ln V_0 \Rightarrow \epsilon(V_0) = -(\alpha + \beta \ln V_0)
$$

This directly encodes elasticity as a function of baseline velocity.

This is also the structural mean demand we use for the parametric estimation later.

##### Comment 

Anchoring demand at $$(V_0, p_0)$$ and scaling with elasticity is derived from the classic constant elasticity demand curve model. We observe the anchor point directly at decisiont-ime, and then use realized sales outcomes. This affords a flexible, lightweight model that uses minimal data. In demand estimation, operations research, and inventory modeling, setting an anchor and scaling from it with elasticity is a standard shortcut when longitudinal data is sparse.

While we could extract higher-resolution historical signals (e.g., Keepa price/velocity traces), we deliberately do not. Historical series are often noisy, incomplete, or inconsistent across SKUs, and introduce substantial preprocessing overhead. Anchoring at decision-time captures the information analysts actually had when making the decision, keeps the model tractable, and avoids the false precision of trying to backfit from messy panel data.

## Parametric Setup


### Price

We model price as LogNormal.  LogNormal is natural because prices are strictly positive and often right-skewed.

$$
\log p \sim \mathcal N\big(\mu(X_s), \sigma^2(X_s)\big)
$$

Observed sale prices are **conditional on selling**. We do **not** observe:

- The price if no units sold (unsold inventory).
- Price paths that never cleared (overpriced stock).
- Counterfactual prices under different decisions.

So, we anchor the distribution at the prevailing market price $$p_0$$

$$
\log P \;\sim\; \mathcal N\big(\log p_0 + \delta(X),\ \sigma^2(X)\big),
$$

where

- $$\delta(X)$$: compression/markup adjustment from **ex-ante** decision-time features ($$\log V_0$$, category, retailer, horizon, forecast).
- $$\sigma^2(X)$$: dispersion that can vary with features (velocity bands, category, retailer).

The log-likelihood, under a log normal distribution is 

$$
\ell_i = \log f_{\text{LogNormal}}\!\big(p^{\text{SELL}}_i \;\big|\; \mu=\log p_{0,i} + \delta(X_i),\, \sigma=\sigma(X_i)\big)
$$

Where $$f$$ is the log normal PDF.

Dense versus sparse SKUs: With many sales, the SKU contributes many likelihood terms, so $$\delta(X)$$ and $$\sigma(X)$$ are strongly shaped near that SKU's feature values. With few/zero sales the SKU contributes little/none; predictions fall back to the feature-driven, pooled structure learned from similar SKUs, in terms of ex-ante characteristics.

Over the dataset of sales,


$$
\mathcal L(\delta,\sigma) \;=\; \sum_{i=1}^{N} w_i\,\ell_i(\delta,\sigma),
$$

where $w_i$ are EM responsibilities for the decision-acquisition link.

##### How SKU heterogeneity enters

Parameters are functions of features $$X$$, not SKUs. SKUs with many sales simply contribute more observations with the same $$X$$ so those feature regions dominate the fit. Sparse SKUs inherit predictions from the shared $$\delta(X),\sigma(X)$$ learned on neighbors with similar features.


### Demand
Demand is negative binomial

$$
D \sim \text{NegBin}\big(\mu(X_s), \kappa(X_s)\big),\quad
E[D] = \mu, \text{Var}(D) = \mu + \frac{\mu^2}{\kappa}
$$

Because SKU x Retailer x Analyst is sparse, we pool: learn shared functions of features (e.g., velocity band, category, retailer), optionally with partial-pooling (regularized group effects) to avoid noisy SKU-level estimates.

#### Structural mean for demand

We fix the mean via the decision-time anchor $$(V_0, p_0)$$ and elasticity

$$
\mu_i = \mu(p_i) = V_{0,i} \times \left( \frac{p_i}{p_{0,i}}\right)^{-\epsilon(V_{0,i})} \times \frac{T_i}{30} \times M_i
$$


#### Estimating dispersion $$\kappa$$ with a fixed mean

Now we need to estimate the dispersion parameter which controls how variable demand is around the mean. For an observed demand $$D_i$$, given $$\mu_i, \kappa_i$$,


$$
P(D_i \mid \mu_i,\kappa_i) =
\frac{\Gamma(D_i+\kappa_i)}{\Gamma(\kappa_i)\,\Gamma(D_i+1)}
\Bigg(\frac{\mu_i}{\mu_i+\kappa_i}\Bigg)^{D_i}
\Bigg(\frac{\kappa_i}{\mu_i+\kappa_i}\Bigg)^{\kappa_i}.
$$

where the gamma function, $$\Gamma(n)=(n-1)!$$ generalizes factorials.

The variance under this distribution is:

$$
\text{Var}(D_i) = \mu_i + \frac{\mu_i^2}{\kappa_i}
$$

So small $$\kappa$$ means fat tails (high volatility). This parameter is what inflates variance beyond Poisson, it is the knob that determines how uncertain our demand is at a given mean.



#### Feature-based model for dispersion


We let $$\kappa$$ vary with decision features:

$$
\log \kappa_i = h_\kappa(X_i),
$$

where $$X_i$$ could include log velocity, category, retailer, seasonality, etc.

This allows high-velocity SKUs to have systematically higher volatility (smaller $$\kappa$$) while niche SKUs are modeled as more stable.


#### Fitting $$h_\kappa$$

For each record $$i$$, we compute the log-likelihood:

$$
\ell_i(\mu_i,\kappa_i) =
\log \Gamma(D_i+\kappa_i) - \log \Gamma(\kappa_i) - \log \Gamma(D_i+1)
+ D_i \log \frac{\mu_i}{\mu_i+\kappa_i}
+ \kappa_i \log \frac{\kappa_i}{\mu_i+\kappa_i}.
$$

And, across all observations, weighted by the EM weights $$w_i$$:


$$
\mathcal L(h_\kappa)=\sum_i w_i\,\ell_i\!\Big(\mu_i,\ \kappa_i=\exp\{h_\kappa(X_i)\}\Big).
$$

Maximize $$\mathcal L(h_\kappa)$$: find the function $$h_\kappa(\cdot)$$ that makes the observed counts $D_i$ most probable given the **fixed** means $$\mu_i$$.

This yields the full demand distribution (mean **and** spread), which is essential for calibrated EM likelihoods and downstream profit optimization.

SKUs with lots of acquisition observations directly shape the local $$\kappa$$, sparse SKUs inherit dispersion from pooled feature-based estimates.

### Total loss (M-step)

When refitting price and demand with EM weights:

$$
\min_{\theta}\ \sum_{p,s}\Big[
-\,w_{p,s}\log P\big(Y_p^{\text{price}}\mid X_s;\theta\big)
-\,w_{p,s}\log P\big(Y_p^{\text{demand}}\mid X_s;\theta\big)
\Big]
+\lambda\|\text{regularization}\|.
$$

This joint loss combines the price and demand likelihoods (weighted by EM responsibilities), plus regularization. In practice, this is the function optimized in each M-step to update $$\theta$$.

### Calibration

To do.


# Optimization

To do.

$$
\Pi(q) = \min(q, D) \times (p-c) - h [q - \min(q,D)]
$$

where

- $$q$$ is quantity bought
- $$\min(q,D)$$ is the quantity sold, which is at most market demand
- $$h$$ is a cost (penalty factor) for every unit bought which exceeds demand

and marginal profit of the $$q$$-th unit sold 

$$
\Delta \Pi(q) = \Pi(q) - \Pi(q-1) 
$$

which equals $$p-c$$ when $$D \ge q$$ and $$-h$$ otherwise (over buy).

So the expected marginal profit is

$$
\mathbb E[\Delta\Pi(q)] 
= \mathbb E\!\left[(p-c)\,\mathbf 1\{D\ge q\}\right] - h \,\Pr(D < q)
$$

## Independence

- If we assume independence between price and demand (major simplification)

$$
\mathbb E[\Delta\Pi(q)] = (\mathbb E[p]-c) \cdot \Pr(D\ge q) -h \,[1-\Pr(D\ge q)]
$$

- If demand is conditional on price

$$
\mathbb E[\Delta\Pi(q)] = \mathbb E\!\Big[(p-c)\,\Pr(D\!\ge q\mid p)\Big] -h \,\Big(1-\mathbb E_{p}[\Pr(D\!\ge q\mid p)]\Big)
$$

For risk adjustment we can apply transformation $$g(\cdot)$$ to the scenario marginal profit function to nudge the decision rule to reflect risk appetite. For example, if we want to account for tail risks, we can apply a Conditional Value at Risk (CVaR) approach. But for now, we are risk neutral.

## Budget Constraint

Let $$c_i$$ be unit cost for SKU $$i$$. Define the bang-for-buck ladder (per unit step):

$$
\gamma_i(q)=\frac{\mathbb E\{g[\Delta\Pi_i(q)]\}}{c_i}.
$$

We take a greedy "fractional knapsack on unit steps" approach.

1. For each SKU $$i$$ and unit $$q=1,\dots,Q_i^{\max}$$, compute $$\gamma_i(q)$$. Intuitively: for a given SKU, buying an additional unit costs $$c_i$$ and which provides value $$g[\Delta \Pi_i(q)]$$. It is therefore profitable to buy up to $$q$$ if (a) benefit exceeds cost and (b) there is no other combination of item and quantity that is also affordable and has a higher marginal profit to cost ratio.
2. Sort all unit steps across SKUs by $$\gamma$$ descending.
3. Take steps until the spend $$\sum_i c_i\,q_i \le B$$ (and drop any steps with $$\gamma_i(q)\le 0$$).

Budget $$B$$ is computed from procurement-side data and measures how much we can spend by retailer. Optimal allocation is choosing $$q^*$$ for each SKU to maximize total expected profit subject to $$B$$.

**Why this greedy**

- Marginal profit $$\Delta\Pi_i(q)$$ is **non-increasing in $$q$$** (because $$\Pr[D_i\ge q]$$ falls with $$q$$).
- Unit cost $$c_i$$ is constant per SKU.
- Under these conditions, the set function is monotone submodular, and sorting by $$\gamma$$ gives the natural near-optimal allocation

So we build a ladder of unit steps  across all SKUs using $$\gamma_i(q)=\mathbb E\{g[\Delta\Pi_i(q)]\}/c_i$$, sort it high-to-low, and buy down the ladder until the budget $$B$$ is exhausted-respecting per-retailer budgets and operational caps where needed.



