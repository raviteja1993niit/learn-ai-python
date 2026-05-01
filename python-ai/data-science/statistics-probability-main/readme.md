# 📐 Statistics & Probability for Data Science & ML

## Why Statistics Matters
Every ML algorithm has statistics at its core:
- Linear regression = least squares estimation
- Naive Bayes = conditional probability
- PCA = eigenvalue decomposition
- Hypothesis testing = A/B testing for ML models

## Key Topics

### Descriptive Statistics
| Concept | Python |
|---------|--------|
| Mean, Median, Mode | `np.mean()`, `np.median()`, `stats.mode()` |
| Variance & Std Dev | `np.var()`, `np.std()` |
| Skewness & Kurtosis | `stats.skew()`, `stats.kurtosis()` |
| Percentiles & IQR | `np.percentile()` |
| Correlation | `df.corr()`, `stats.pearsonr()` |

### Probability Distributions
- Normal, Binomial, Poisson, Uniform, Exponential
- PDF, CDF, inverse CDF
- Central Limit Theorem
- `scipy.stats` — all distributions

### Inferential Statistics
| Test | Use Case |
|------|----------|
| t-test | Compare means of 2 groups |
| Chi-square | Categorical variable independence |
| ANOVA | Compare means of 3+ groups |
| Z-test | Large sample proportion test |
| Mann-Whitney U | Non-parametric 2-group comparison |

### A/B Testing
- Null hypothesis / alternative hypothesis
- p-value, confidence intervals, statistical power
- Type I (false positive) & Type II (false negative) errors
- Sample size calculation

## Learning Path
1. `pip install scipy statsmodels`
2. Descriptive stats on any dataset
3. Probability distributions with scipy.stats
4. Hypothesis testing (t-test, chi-square)
5. A/B test simulation end-to-end

## What to Build
- [ ] A/B test simulator for ML model comparison
- [ ] Distribution fitter — find best distribution for your data
- [ ] Statistical EDA report with all tests
- [ ] Hypothesis testing on playstore-Dataset

## Related Folders
- `data-science/Pandas-Profiling-EDA-master/` — auto stats
- `machine-learning/Types-Of-Cross-Validation-main/` — statistical validation