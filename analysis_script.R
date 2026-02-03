# Load Libraries
library(tidyverse)
library(psych)      # For KMO and Bartlett
library(FactoMineR) # For PCA
library(factoextra) # For visualization
library(cluster)    # For K-Means

# 1. DATA PREPARATION & STANDARDIZATION
# Z-Score normalization to handle different units (Revenue vs Ratios)
dati_pulito <- read.csv("startup_data.csv") # Placeholder for dataset
datiZ <- scale(dati_pulito)

# 2. ASSUMPTION CHECKS
# Bartlett Test of Sphericity (Check correlation)
bartlett_test <- cortest.bartlett(cor(dati_pulito), n = nrow(dati_pulito))
print(bartlett_test) # p.value < 0.001

# Kaiser-Meyer-Olkin (KMO) Measure
kmo_result <- KMO(cor(dati_pulito))
print(kmo_result) # Overall MSA = 0.71 (Good fit)

# 3. PRINCIPAL COMPONENT ANALYSIS (PCA)
PCA <- princomp(datiZ, cor = TRUE)
summary(PCA)

# Visualizing Variable Contribution
fviz_contrib(PCA, choice = "var", axes = 1, title = "Contribution to Dim-1 (Volume)")
fviz_contrib(PCA, choice = "var", axes = 2, title = "Contribution to Dim-2 (Health)")

# 4. CLUSTERING (K-MEANS)
# Determining optimal k using Elbow Method
df_pca <- PCA$scores[, 1:2] # Working on first 2 components
fviz_nbclust(df_pca, kmeans, method = "wss") +
  geom_vline(xintercept = 4, linetype = 2) +
  labs(title = "Elbow Method")

# Running K-Means with k=4
set.seed(123)
res_pca <- kmeans(df_pca, centers = 4)

# 5. VISUALIZATION & VALIDATION
# Cluster Plot
fviz_cluster(res_pca, data = datiZ,
             geom = "point",
             ellipse.type = "convex",
             main = "Cluster Plot on PCA (k=4)")

# ANOVA Validation (Testing significance of clusters)
# Checking if differences between groups are statistically significant
risultati_anova <- df_pca %>%
  as.data.frame() %>%
  mutate(cluster = as.factor(res_pca$cluster)) %>%
  map_dfr(.f = ~ aov(. ~ cluster, data = .) %>% tidy(), .id = "Variable") %>%
  filter(term == "cluster") %>%
  arrange(p.value)

print(risultati_anova)
