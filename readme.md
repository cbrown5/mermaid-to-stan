# Mermaid → Stan (Prototype)

A browser-based tool that converts a Mermaid flowchart into Stan code for Bayesian modelling in rstan. The user edits the diagram and the Stan code updates in real time.

**⚠️ Warning:** Prototype only. Minimal testing conducted. Fully vibe coded. 

---

## Scope (prototype)

- Single `index.html` file, no build step, no framework
- Mermaid.js and vanilla JS only
- Supports linear regression and multiple regression as primary test cases
- Generates a minimal but valid Stan program (data block, parameters block, model block)

---

## Mermaid DSL Convention

Standard Mermaid `graph LR` flowcharts are used. Every node label encodes its role in the model using a `type: spec` format inside the node label string. The node **ID** (before the brackets) becomes the **variable name** in Stan.

### Node types

| Type | Label format | Stan role |
|------|-------------|-----------|
| `int` | `N["int"]` | integer in `data {}` (e.g. sample size) |
| `data` | `x["data: vector[N]"]` or `x["data: real"]` | declared in `data {}` |
| `param` | `beta["param: Normal(0,10)"]` | declared in `parameters {}`, prior in `model {}` |
| `param+` | `sigma["param+: HalfNormal(0,1)"]` | as above but with `<lower=0>` constraint |
| `det` | `mu["det: alpha + beta*x"]` | deterministic quantity, computed inside `model {}` |
| `obs` | `y["obs: Normal(mu,sigma)"]` | observed outcome, likelihood in `model {}` |

Edges (`A --> B`) appear in the diagram for visual clarity but node labels carry all information needed for code generation.

### Supported distributions (prototype)

`Normal`, `HalfNormal`, `Cauchy`, `HalfCauchy`, `Uniform`, `Beta`, `Exponential`, `StudentT`.
A lookup table maps these to Stan function names (e.g. `HalfNormal` → `normal` with `<lower=0>`).

---

## Example: Simple linear regression

Mermaid input:

```
graph LR
    N["int"]
    x["data: vector[N]"]
    y["obs: Normal(mu,sigma)"]
    alpha["param: Normal(0,10)"]
    beta["param: Normal(0,10)"]
    sigma["param+: HalfNormal(0,1)"]
    mu["det: alpha + beta*x"]

    alpha --> mu
    beta --> mu
    x --> mu
    mu --> y
    sigma --> y
```

Generated Stan:

```stan
data {
  int N;
  vector[N] x;
  vector[N] y;
}
parameters {
  real alpha;
  real beta;
  real<lower=0> sigma;
}
model {
  vector[N] mu;
  mu = alpha + beta * x;
  alpha ~ normal(0, 10);
  beta ~ normal(0, 10);
  sigma ~ normal(0, 1);
  y ~ normal(mu, sigma);
}
```

---

## Example: Multiple regression (two predictors)

```
graph LR
    N["int"]
    x1["data: vector[N]"]
    x2["data: vector[N]"]
    y["obs: Normal(mu,sigma)"]
    alpha["param: Normal(0,10)"]
    b1["param: Normal(0,10)"]
    b2["param: Normal(0,10)"]
    sigma["param+: HalfCauchy(0,2.5)"]
    mu["det: alpha + b1*x1 + b2*x2"]

    alpha --> mu
    b1 --> mu
    b2 --> mu
    x1 --> mu
    x2 --> mu
    mu --> y
    sigma --> y
```

---

## UI layout

```
┌─────────────────────────┬─────────────────────────┐
│  Mermaid diagram editor │  Stan code output        │
│  (live textarea)        │  (readonly textarea)     │
│                         │                    [Copy]│
├─────────────────────────┴─────────────────────────┤
│  Rendered Mermaid diagram (live preview)           │
└────────────────────────────────────────────────────┘
```

- **Load example** buttons: "Linear regression", "Multiple regression"
- Diagram editor and Stan output update on every keystroke (debounced ~400 ms)
- **Copy** button copies Stan code to clipboard
- Parse errors displayed inline below the editor

---

## Parser logic (JS, single pass)

1. Match all node definitions with regex: `/(\w+)\["([^"]+)"\]/g`
2. Split each label on the first `:` → `type` and `spec`
3. Categorise nodes into: `intVars`, `dataVars`, `params`, `dets`, `obsVars`
4. Extract edges `/(\w+)\s*-->\s*(\w+)/g` to topologically order `det` nodes
5. Emit Stan blocks in order: `data {}` → `parameters {}` → `model {}`

---

## Files

```
index.html   ← everything (HTML + CSS + JS, self-contained)
readme.md
```

---

## Out of scope for prototype

- Vector/matrix parameters
- Transformed parameters block
- Generated quantities block
- Hierarchical / multilevel models
- Custom Stan functions
- Input validation / well-specification checking