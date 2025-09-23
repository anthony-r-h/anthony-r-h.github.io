---
layout: post
title: "Black-Scholes From The Ground Up"
subtitle: "" 
optimized_image: /files/Finance5Dummies/black-scholes.png
category: Writings
tags:
  - Edcuation
  - Finance
math: true
---

<h2>Table Of Contents</h2>
<p style="margin-bottom:10px;"></p>

* toc
{:toc}

# About

The Black-Scholes model provides a theoretical framework for pricing European-style options.

> European-style options are only exercisable at expiration

The central principle is that an option can be perfectly replicated by dynamically buying and selling the underlying asset and a risk-free bond in just the right proportions. This strategy, called continuously revised delta hedging, eliminates risk. Since arbitrage is not allowed, the option’s fair value must equal the cost of building this replicating portfolio.

## The core idea

- The option price comes from replication: construct the same payoff by trading stock + risk-free bond.
- No arbitrage implies option and replicating portfolio must have the same price.
- This reasoning leads to a partial differential equation (PDE). Solving it yields the Black–Scholes formula.

## Why it matters

- Closed-form option pricing
  - Independent of investor risk preferences and the stock’s expected return.
  - Depends only on volatility, time, and the risk-free rate.
  - Anchors derivative prices directly to the underlying asset.
- Foundation of modern derivatives
    - Inversion of Black–Scholes backs out *implied volatility*, effectively making volatility a tradable asset.
    - Defines the **Greeks** (Delta, Gamma, Vega, Theta, Rho), a systematic framework for risk measurement and hedging.
- Broader influence
    - Catalyzed quantitative finance: stochastic calculus, martingale pricing, incomplete markets.
    - Reinforced the no-arbitrage principle, supporting efficient market ideas in derivative pricing.
    - Laid groundwork for entire industries in structured products, risk management, and volatility trading.


# Goal

We want the **fair price** today of a European option.

At expiry $T$, payoff is known:

- Call: $\max(S_T - K, 0)$
- Put: $\max(K - S_T, 0)$

Question: *What's the correct price at time $t<T$?*

# Setup and definitions

Let 

- $S_t$: stock price at time $t$.
- $K$: strike price.
- $T$: expiration time.
- $t$: current time, with $\tau = T-t$ = time to maturity.
- $r$: risk-free interest rate (continuously compounded).
- $\sigma$: volatility of stock (constant).
- $\mu$: expected return of stock (drops out later).
- $W_t$: standard Brownian motion (random noise).
- $C(S,t)$: call price as function of stock & time.

# Stock price model

## Brownian motion

Brownian Motion describes a stochastic process as a function of time where every step is random. Where a random variable is a single draw from a distribution, Brownian motion describes uncertainty over time.

A standard Brownian motion $W_t$ is

1. $W_0 = 0$
2. Increments are independent: $W_{t+\delta} - W_t \sim \mathcal{N}(0, \Delta t) $
3. Paths are continuous but nowhere differentiable
4. Variance grows linearly with time, $\mathbb{E}[W_t] = 0$, $\text{Var}[W_t] = t$

Why assume Brownian motion for stocks?

- It captures the intuiton that stock returns are random, but scale with time
- Leads to lognormal distribution of prices
- Makes the math easy (Ito's Lemma, PDEs)

The intuition behind Brownian motion in finance is that stock prices result from the cumulative effect of many small, random buying and selling decisions. Each trade is like a small random step. In the limit of many rapid, independent steps, this process converges to Brownian motion, a continuous random process with normally distributed increments.

## GBM setup

Assume geometric Brownian motion (GBM)

$$
dS_t = \mu S_t\, dt + \sigma S_t\, dW_t
$$

Interpretation:

A tiny change in the stock price over a small interval is:

- Deterministic drift, $\mu S_t dt$
    - Predictable component
    - If $\mu = 0.05$, then we're saying the stock grows at 5% per year (scaled by the interval length $dt$)
- Random shock (diffusion term), $\sigma S_t dW_t$
    - Captures unpredictable movements
    - $\sigma$ is the volatility coefficient and scales randomness
    - $dW_t$: increment of Brownian motion, distributed as $dW_t \sim \mathcal{N}(0, dt)$
    - Randomness accumulates over time
        - $\mathbb{E}[dS_t] = \mu S_t dt$
        - Variance of the sock $\text{Var}(dS_t) = \sigma^2 S_t^2 dt$ 
            - Variance grows linearly in elapsted time
            - The scale of uncetainty grows in proportion to the current stock price


## Is GBM a good assumption?

**Evidence for**

- Log returns are roughly normal int he short-term (daily, or weekly scales)
- Volatility shown to be proportional to time over _moderate_ horizons

**Evidence against**

- Fat tails (kurtosis)
    - empirical return distributions have more extreme outcomes than Gaussian predicts
    - $10 \sigma$ events occur, which are near impossible under Gaussian distributions
- Volatility is clustered
    - Brownian motion assumes a constant volatility factor $\sigma$
    - In the data, periods of high volatility tend to follow each other
- Negative returns often increase volatility
- Jumps in stock prices
    - Prices gap due to earnings, news, memes, etc
    - Brownian paths are continuous, implying no jumps

**Extensions**

- Stochastic volatility (e.g., Heston)
- Jump–diffusion (Merton)
- GARCH (discrete-time clustering)
- Rough volatility (long-memory in vol)

# Ito's Lemma (stochastic chain rule)

Ordinary calculus uses the chain rule. Because Brownian motion has variance that scales with $dt$, in stochastic calculus, we need an extra correction term.

If $f(S,t)$ is a smooth function of stock price and time and follows $dS_t = \mu S_t dt + \sigma S_t dW_t$, then Ito’s Lemma says:

$$
df = \frac{\partial f}{\partial t}\,dt 
+ \frac{\partial f}{\partial S}\,dS 
+ \tfrac{1}{2} \frac{\partial^2 f}{\partial S^2} (dS)^2
$$

With $(dW_t)^2 = dt$.

> This "extra" second-derivative term is the core of stochastic calculus.

# Apply Ito's Lemma to option price

Let the option price be $C(S,t)$. Applying Ito's Lemma:

$$
dC = \Big( \frac{\partial C}{\partial t} + \mu S \frac{\partial C}{\partial S} + \tfrac{1}{2}\sigma^2 S^2 \frac{\partial^2 C}{\partial S^2} \Big) dt
+ \sigma S \frac{\partial C}{\partial S} dW_t
$$

Interpretation:

- First big bracket: deterministic drift of the option.
- Second term: random component proportional to $dW_t$.

# Construct a hedged portfolio

We now form a portfolio that combines an option and the stock in such a way that the random part of its value change disappears.

$$
\Pi = C - \Delta S
$$

This corresponds to being long one option and short $\Delta$ shares of stock. The reason for the minus sign is that a call option already behaves like a partial long stock position (its Delta). To cancel that exposure, we must take the opposite side in the stock.

If instead we went long both the option and the stock, their risks would reinforce each other and stock rises increase the value of both, so the randomness would be additive rather than hedged. By choosing $\Delta$, we can cancel the random parts out, leaving the portfolio riskless.

Change in portfolio:

$$
d\Pi = dC - \Delta\, dS
$$

Substitute expressions for $dC$ and $dS$:

$$
d\Pi = \Big( \frac{\partial C}{\partial t} + \mu S \frac{\partial C}{\partial S} + \tfrac{1}{2}\sigma^2 S^2 \frac{\partial^2 C}{\partial S^2} - \Delta \mu S \Big) dt
+ \Big( \sigma S \frac{\partial C}{\partial S} - \Delta \sigma S \Big) dW_t
$$

# Eliminate randomness (Delta Hedging)

If we choose

$$
\Delta = \frac{\partial C}{\partial S}
$$

Then the $dW_t$ term vanishes, so the portfolio becomes **riskless** and has no randomness left in it

This step shows that derivative pricing can be anchored to no-arbitrage and hedging arguments, not investor psychology. That’s why Black–Scholes was revolutionary: it turned option pricing into physics-like mechanics instead of subjective forecasting.

Interpretation:

- The option itself is risky, its value jumps around randomly with the stock
- But if you hold the right number of shares, along with the option, the random part cancels out
- Then, the portfolio is perfectly hedged against small movements in the stock
- This is called delta hedging: neutralizing the option's sensitivity to the stock price

Implication

- Once randomness is gone, its return must equal the risk-free rate, otherwise arbitrage opportunities would exist
- Expected return of the stock $\mu$ disappears after hedging
    - Option prices don't depend on what investors expect the stock price will return
    - Instead, they depend on volatility, time and interest rates
    - This makes option pricing objective, and not tied to investor subjectivity
- In theory, by adjusting your stock position, $\Delta$, your portfolio is riskless

Now:

$$
d\Pi = \Big( \frac{\partial C}{\partial t} + \frac{1}{2}\sigma^2 S^2 \frac{\partial^2 C}{\partial S^2} \Big) dt
$$

where

- Theta, $\frac{\partial C}{\partial t}$ is time-rent and
- Gamma, $\frac{\partial^2 C}{\partial S^2}$ captures convexity with respect to the underlying stock price.

# No-arbitrage condition

A riskless portfolio must grow at the risk-free rate $r$.

Portfolio value:

$$
\Pi = C - S \frac{\partial C}{\partial S}
$$

So:

$$
d\Pi = r\Big(C - S \frac{\partial C}{\partial S}\Big) dt
$$

# Equating both expressions

We now equate the two expressions for $d\Pi$. We are explicity linking the changes in portfolio value with the risk-free return.

$$
\frac{\partial C}{\partial t} + \tfrac{1}{2}\sigma^2 S^2 \frac{\partial^2 C}{\partial S^2} 
= rC - rS \frac{\partial C}{\partial S}
$$

Rearrange into the **Black–Scholes PDE**:

$$
\frac{\partial C}{\partial t} + rS \frac{\partial C}{\partial S} + \tfrac{1}{2}\sigma^2 S^2 \frac{\partial^2 C}{\partial S^2} - rC = 0
$$

This is the central equation of the Black–Scholes model.

# Solve PDE with boundary condition

Boundary condition at maturity:

$$
C(S,T) = \max(S-K,0)
$$

Solving the PDE gives the closed-form solution:

$$
C(S,t) = S_t \Phi(d_1) - K e^{-r(T-t)} \Phi(d_2)
$$

with

$$
d_1 = \frac{\ln(S_t/K) + (r + \tfrac{1}{2}\sigma^2)(T-t)}{\sigma\sqrt{T-t}}, 
\quad d_2 = d_1 - \sigma \sqrt{T-t}
$$

$\Phi(\cdot)$ = standard normal CDF.

## Handwaving

Solving the PDE involves

- **Change variables**: Rewrite time and stock price in terms of log-price.
    - Let $x = \ln(S)$, and flip time to a “time-to-maturity” variable.
- **Transform the PDE**: With these substitutions, the Black–Scholes PDE turns into the *heat equation* (the classic PDE from physics describing diffusion of heat in a rod).
    - This is the big insight: option pricing is mathematically equivalent to heat diffusion.
- **Solve the heat equation**: The solution involves integrating against the normal distribution.

Solving it isn't super important though.


## Interpretation

Option price structure

$$
C(S,t) = \underbrace{S_t \,\Phi(d_1)}_{\text{benefit of stock if exercised}}
        - \underbrace{K e^{-r(T-t)} \,\Phi(d_2)}_{\text{cost of paying strike}}
$$

- First term: expected value (under the risk-neutral measure) of holding the stock, conditional on exercise.
- Second term: present value of the strike, weighted by the risk-neutral exercise probability.
- Difference = fair call price.

What is **$d_1$ and $d_2$**?

- Both are **z-scores** in the lognormal distribution of future stock prices.
- $d_2$: standardized distance of the strike $K$ under the risk-neutral distribution of $\ln S_T$.
- $d_1 = d_2 + \sigma\sqrt{T-t}$: shifted upward by one volatility unit, because the stock expectation is “stock-weighted.”

Probabilistic interpretation

- $\Phi(d_2)$: risk-neutral probability that the option finishes in the money.
- $\Phi(d_1)$: the call option’s **Delta**, i.e. hedge ratio, interpretable as a stock-weighted probability of exercise.

Put value follows from **put–call parity**:

$$
P(S,t) = K e^{-r(T-t)} \Phi(-d_2) - S_t \Phi(-d_1)
$$

# Key insights

The big idea here is: stocks are dynamic, in $dS_t = \mu S_t dt + \sigma S_t d W_t$, the $dWt$ term is irreducible and can't be eliminated. While options are also risky, under certain condititions, if you combine an option with the right fraction of stocks (Delta), then the random terms cancel out. That means that if you continuously rebalance via stock holdings (Delta hedge), you can replicate the option payoff with certainty. As a consequence, the option's fair price is the cost of the replication strategy.

- **Ito's Lemma** explains how option prices evolve when underlying follows Brownian motion.
- **Delta-hedging** removes randomness, creating a risk-free portfolio.
- **No arbitrage** forces option prices to satisfy the PDE.
- **Implied Volatility** given the market option price, solve for $\sigma$ that makes Black-Scholes match it

**So why bother**? Black-Scholes is a pricing model, not an investment strategy, but rather a pricing model for fair option prices. When an option is mispriced relative to the stock, then there is an arbitrage opportunity which forces option prices back into line. Black-Scholes tells us what happens in equilibrium.

Options allow traders to _express their views_ on volatility, jumps, rail risk by trading options relative to that fair value.


## The Greeks

The Greeks quantify how option value responds to risk factors. 

- **Delta**, $\frac{\partial C}{\partial S}$: sensitivity to stock price
    - How many shares you need to hedge one option, ie, hedge delta with stock
    - Practical benchmarks
        - Near zero when option is deep OTM because the option is worthless and a dollar move in the stock price doesn't change the fact that it is still worthless.
        - 0.5 when ATM because the option has a 50/50 chance of expiring in or out.
        - 1, moves dollar-for-dollar with stock because the option is basically the stock itself, minus strike.
- **Gamma**, $\frac{\partial^2 C}{\partial S^2}$: sensitivity of delta to stock price
    - Convexity of option value with respect to stock moves and tells you how unstable delta is.
    - Practical benchmarks
        - High for short-dated options that are ATM. This is the knife edge where small moves flip the option ITM or OTM
        - Very low for deep ITM/OTM because a dollar change in the stock price doesn't change that fact. 'Delta is saturated'. 
- **Theta**, $\frac{\partial C}{\partial t}$: sensitivity to time
    - How much value the option loses per day. If you buy an option, you're paying theta, and if you're selling an option, you collect theta.
    - Practical benchmarks
        - Long-dated, or deep OTM options: small theta, so option value is invariant to time
        - Short-dated ATM options: large theta since expiry is near.
- **Vega**, $\frac{\partial C}{\partial \sigma}$: sensitivity to volatility
    - Change in option price per 1% change in volatility. Tells you how exposed you are to changes in volatility. 
    - Practical benchmarks
        - For long-dated options, vega is highest (benefit from volatility spikes: earnings, crises). There is more time for volatility to play out.
        - For short-dated options, vega is small since even if volatility rises, there is no time for big moves to materialize.
- **Rho**, $\frac{\partial C}{\partial r}$: sensitivity to interest rate
    - Change in option price per 1% change in the risk-free rate. This matters for FX and bonds (not equities).
    - Benchmarks
        - For short-dated options, rho is negligible
        - For long-dated currency or bond options, rho matters a lot because it directly shapes forward prices.


## Indicators and strategy

The Greeks tell us about the option market expectations, positioning, and risk sensitivity.

- Find high-Gamma names (susceptible to squeezes).
    - Stocks with crowded option markets (e.g., TSLA, NVDA, SPY) show big Gamma exposures - dealers hedging creates "Gamma squeezes."
    - Screening stocks with large aggregate Gamma exposure can signal potential for sharp moves if hedging flows unwind.
- Spot high-Vega setups (earnings trades).
    - Screen for stocks with elevated Vega to trade implied volatility moves (e.g., earnings crush).
- Target Theta-rich environments (premium selling).
    - Screen for high-Theta environments (options overpriced relative to realized volatility).
- Compare IV vs realized volatility to see if options are cheap/expensive.

Some strategies may be

- Earnings trade (IV crush)
  - Before earnings: IV high, options expensive.
  - Speculator thinks actual move will be smaller than implied, so sells straddle/strangle.
  - After earnings: IV collapses, they pocket the difference.
- Crisis hedge
  - Market calm: IV low, options cheap.
  - Speculator expects volatility spike (Fed, geopolitical event, crash).
  - Buys puts or straddles → small daily losses from Theta, but massive payoff if vol spikes.
- Directional leverage
  - Buy OTM calls (Delta \~0.2) if bullish: small upfront cost, huge payoff if stock rallies.
  - Equivalent for bearish view with OTM puts.


# Practical Examples

## NVDA Sept. 26 call option

The contract

- Strike $182.50 (ATM option)
- Expiry: Sept. 26 (very short maturity)
- Market price: $3.95 (midpoint between bid/ask)
- Breakeven: $186.45 (strike plus premium)

The Greeks

- Delta = 0.5651
    - The option behaves like 0.57 shares of stock
    - If NVDA rises a dollar then option prices rise by $0.57
- Gamma = 0.0465
    - Delta will increase by 0.0465 per $1 stock move
    - Gamma is high because it is ATM and short dated, so it is at a knife edge, small moves will flip ITM/OTM 
- Theta = -0.4267
    - Option loses about $0.43 of value per day
    - Time decay is steep because the option has very short maturity
    - Buying option means you pay Theta in rent
- Vega = 0.0757
    - If IV rises by 1%, then the option gains $0.076
    - IV is 44.01%, market expects an annualized volatility of 44%
    - Vega is small due to the fact that the option is nearly expired and there is little time for shocks to the price
- Rho is irrelevant here

Implications

- This is a near-term ATM call
    - High Gamma (sensitive to every wiggle)
    - Steep Theta (loses nearly 10% of value per day)
    - Low Vega (IV changes don't matter this close to expiry)
- As a speculator:
    - Buying this call means betting NVDA jumps quickly above breakeven
    - Selling this call means betting tht NVDA stays flat, so you collect Theta, but risk unlimited upside losses if NVDA jumps
- As a hedger
    - You short 0.57 shares per option to hedge
    - Because Gamma is high, Delta changes rapidly, so you need to rebalance frequently