# Summary Statistics (Pre-period, `post_t==0`)

## `wins_percentage_delay`

### Treated (`treat_new==1`)

```r
summary(reg_df_subset_positive[post_t==0&treat_new==1]$wins_percentage_delay)
```

| Min.  | 1st Qu. | Median | Mean    | 3rd Qu. | Max.    |
|-------|---------|--------|---------|---------|---------|
| 4.268 | 24.583  | 64.516 | 154.888 | 147.703 | 878.324 |

### Control (`treat_new==0`)

```r
summary(reg_df_subset_positive[post_t==0&treat_new==0]$wins_percentage_delay)
```

| Min.  | 1st Qu. | Median | Mean    | 3rd Qu. | Max.    |
|-------|---------|--------|---------|---------|---------|
| 4.268 | 25.275  | 68.817 | 160.757 | 157.746 | 878.324 |

---

## `winsorized_delay`

### Treated (`treat_new==1`)

```r
summary(reg_df_subset_positive[post_t==0&treat_new==1]$winsorized_delay)
```

| Min. | 1st Qu. | Median | Mean  | 3rd Qu. | Max.   |
|------|---------|--------|-------|---------|--------|
| 1.00 | 32.00   | 71.00  | 66.36 | 103.00  | 103.00 |

### Control (`treat_new==0`)

```r
summary(reg_df_subset_positive[post_t==0&treat_new==0]$winsorized_delay)
```

| Min. | 1st Qu. | Median | Mean  | 3rd Qu. | Max.   |
|------|---------|--------|-------|---------|--------|
| 1.00 | 40.00   | 91.00  | 72.95 | 103.00  | 103.00 |
