setwd(normalizePath(dirname(R.utils::commandArgs(asValues=TRUE)$"f")))
source('../../findNSourceUtils.R')
library(gbm)

test.GBM.smallcat <- function(conn) {
  # Training set has 26 categories from A to Z
  # Categories A, C, E, G, ... are perfect predictors of y = 1
  # Categories B, D, F, H, ... are perfect predictors of y = 0
  
  Log.info("Importing alphabet_cattest.csv data...\n")
  alphabet.hex <- h2o.uploadFile(conn, locate("smalldata/histogram_test/alphabet_cattest.csv"), key = "alphabet.hex")
  alphabet.hex$y <- as.factor(alphabet.hex$y)
  Log.info("Summary of alphabet_cattest.csv from H2O:\n")
  print(summary(alphabet.hex))
  
  # Import CSV data for R to use in comparison
  alphabet.data <- read.csv(locate("smalldata/histogram_test/alphabet_cattest.csv"), header = TRUE)
  alphabet.data$y <- as.factor(alphabet.data$y)
  Log.info("Summary of alphabet_cattest.csv from R:\n")
  print(summary(alphabet.data))
  
  # Train H2O GBM Model:
  Log.info("H2O GBM (Naive Split) with parameters:\nclassification = TRUE, n.trees = 1, interaction.depth = 1, n.bins = 100\n")
  drfmodel.nogrp <- h2o.gbm(x = "X", y = "y", data = alphabet.hex, n.trees = 1, interaction.depth = 1, n.bins = 100, group_split = FALSE)
  print(drfmodel.nogrp)
  
  Log.info("H2O GBM (Group Split) with parameters:\nclassification = TRUE, n.trees = 1, interaction.depth = 1, n.bins = 100\n")
  drfmodel.grpsplit <- h2o.gbm(x = "X", y = "y", data = alphabet.hex, n.trees = 1, interaction.depth = 1, n.bins = 100, group_split = TRUE)
  print(drfmodel.grpsplit)
  
  # Check AUC and overall prediction error at least as good with group split than without
  #Log.info("Expect GBM with Group Split to give Perfect Prediction in Single Iteration")
  #expect_true(drfmodel.grpsplit@model$auc == 1)
  #expect_true(drfmodel.grpsplit@model$confusion[3,3] == 0)
  expect_true(drfmodel.grpsplit@model$auc >= drfmodel.nogrp@model$auc)
  expect_true(drfmodel.grpsplit@model$confusion[3,3] <= drfmodel.nogrp@model$confusion[3,3])
  
  # Train R GBM Model:
  # Log.info("R GBM with same parameters:")
  # drfmodel.r <- gbm(y ~ ., data = alphabet.data, n.trees = 1, nodesize = 1)
  # drfmodel.r.pred <- predict(drfmodel.r, alphabet.data, type = "response")
  
  # Compute confusion matrices
  # Log.info("R Confusion Matrix:"); print(drfmodel.r$confusion)
  # Log.info("H2O (Group Split) Confusion Matrix:"); print(drfmodel.grpsplit@model$confusion)
  
  # Compute the AUC - need to convert factors back to numeric
  # actual <- ifelse(alphabet.data$y == "0", 0, 1)
  # pred <- ifelse(drfmodel.r.pred == "0", 0, 1)
  # R.auc = gbm.roc.area(actual, pred)
  # Log.info(paste("R AUC:", R.auc, "\tH2O (Group Split) AUC:", drfmodel.grpsplit@model$auc))
  testEnd()
}

doTest("GBM Test: Classification with 26 categorical level predictor", test.GBM.smallcat)
