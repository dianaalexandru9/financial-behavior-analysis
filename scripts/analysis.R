# ------------------------------------------------------------
# Financial Behavior Analysis in the Romanian Real Estate Market
# Multivariate Statistical Analysis using R
# ------------------------------------------------------------

# STEP 0: Load required libraries
library(ggplot2)
library(factoextra)
library(FactoMineR)
library(corrplot)
library(psych)
library(plotly)
library(reshape2)
library(NbClust)
library(cluster)
library(GPArotation)

# STEP 1: Load dataset
data <- read.csv("data/DateACP.csv", row.names = 1)

# STEP 2: Descriptive statistics
summary(data)

# ------------------------------------------------------------
# Principal Component Analysis (PCA)
# ------------------------------------------------------------

# STEP 3: Correlation matrix before removing highly correlated variables
corr_matrix <- cor(data)

corrplot(
  corr_matrix,
  method = "number",
  type = "full",
  title = "Correlation Matrix of the Analyzed Variables",
  mar = c(0, 0, 2, 0),
  tl.cex = 0.9,
  number.cex = 0.7
)

# X3 and X7 were removed due to strong correlations with other variables
data_reduced <- subset(data, select = -c(X3, X7))

# STEP 4: Data standardization
standardize <- function(x) {
  (x - mean(x)) / sd(x)
}

data_standardized <- apply(data_reduced, 2, standardize)

# STEP 5: Correlation matrix after variable reduction and standardization
corr_matrix_reduced <- cor(data_standardized)

corrplot(
  corr_matrix_reduced,
  method = "number",
  type = "full",
  title = "Correlation Matrix After Variable Reduction",
  mar = c(0, 0, 2, 0),
  tl.cex = 0.9,
  number.cex = 0.7
)

# STEP 6: Principal Component Analysis
pca_result <- PCA(
  data_standardized,
  scale.unit = TRUE,
  ncp = 5,
  graph = TRUE,
  axes = c(1, 2)
)

# STEP 7: Scree plot
fviz_eig(
  pca_result,
  addlabels = TRUE,
  ylim = c(0, 50),
  main = "Percentage of Variance Explained by Principal Components"
)

# STEP 8: Factor loading matrix
factor_matrix <- round(pca_result$var$cor, 2)
print(factor_matrix)

# STEP 9: Country projection in the principal component space
fviz_pca_ind(
  pca_result,
  repel = TRUE,
  col.ind = "cos2",
  gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
  title = "Country Projection in the PCA Principal Plane"
)

# ------------------------------------------------------------
# Cluster Analysis
# ------------------------------------------------------------

# STEP 10: Prepare data for clustering
cluster_data <- read.csv("data/DateACP.csv", row.names = 1)

# Remove redundant variables based on PCA/correlation analysis
cluster_data <- subset(cluster_data, select = -c(X3, X7))

# Standardize data
cluster_data_standardized <- scale(cluster_data)

# STEP 11: Euclidean distance matrix
distance_matrix <- round(
  dist(cluster_data_standardized, method = "euclidean"),
  3
)

# STEP 12: Distance matrix visualization
distance_data <- melt(as.matrix(distance_matrix))

ggplot(data = distance_data, aes(x = Var1, y = Var2, fill = value)) +
  geom_tile() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_gradient(low = "lightblue", high = "purple") +
  ggtitle("Euclidean Distances Between Countries (2024)") +
  theme(plot.title = element_text(hjust = 0.5))

# STEP 13: Hierarchical clustering
cluster_result <- hclust(distance_matrix, method = "ward.D2")

plot(
  cluster_result,
  labels = rownames(cluster_data),
  main = "Country Dendrogram (2024)",
  cex = 0.8
)

# STEP 14: Elbow method for determining the optimal number of clusters
fviz_nbclust(cluster_data_standardized, hcut, method = "wss") +
  geom_vline(xintercept = 3, linetype = 2) +
  labs(subtitle = "Elbow Method for Determining the Number of Clusters")

# STEP 15: Cluster validation using NbClust
nbclust_result <- NbClust(
  cluster_data_standardized,
  distance = "euclidean",
  min.nc = 2,
  max.nc = 7,
  method = "ward.D2",
  index = "all"
)

# STEP 16: Silhouette analysis for 3 clusters
silhouette_result <- silhouette(
  cutree(cluster_result, k = 3),
  distance_matrix
)

plot(
  silhouette_result,
  cex.names = 0.5,
  main = "Silhouette Plot for 3 Clusters"
)

# STEP 17: Cluster centroids
clusters <- cutree(cluster_result, k = 3)

centroids <- aggregate(
  cluster_data_standardized,
  by = list(Cluster = clusters),
  FUN = mean
)

round(centroids, 2)

# ------------------------------------------------------------
# Exploratory Factor Analysis (EFA)
# ------------------------------------------------------------

# STEP 18: Load and prepare data for factor analysis
efa_data <- read.csv("data/DateACP.csv", row.names = 1)

# Remove redundant variables
efa_data <- subset(efa_data, select = -c(X3, X7))
efa_data_standardized <- scale(efa_data)

# STEP 19: KMO and Bartlett tests
KMO(efa_data_standardized)
cortest.bartlett(efa_data_standardized)

# Further variable reduction based on adequacy tests
efa_data_reduced <- subset(efa_data, select = -X6)
efa_data_standardized_reduced <- scale(efa_data_reduced)

KMO(efa_data_standardized_reduced)
cortest.bartlett(efa_data_standardized_reduced)

efa_data_clean <- subset(efa_data_reduced, select = -X1)
efa_data_standardized_clean <- scale(efa_data_clean)

KMO(efa_data_standardized_clean)
cortest.bartlett(efa_data_standardized_clean)

# STEP 20: Parallel analysis for determining the number of factors
fa.parallel(
  efa_data_standardized_clean,
  fa = "fa",
  n.iter = 100,
  main = "Parallel Analysis for Determining the Number of Factors"
)

# STEP 21: Factor extraction
efa_result <- fa(
  efa_data_standardized_clean,
  nfactors = 1,
  rotate = "none",
  fm = "ml"
)

print(efa_result, cut = 0.3)

# STEP 22: Factor structure visualization
fa.diagram(
  efa_result,
  main = "One-Factor Model"
)

# STEP 23: Factor loadings interpretation
efa_result$loadings