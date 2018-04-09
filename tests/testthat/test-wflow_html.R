context("wflow_html")

# Test wflow_html --------------------------------------------------------------

test_that("wflow_html sets custom knitr chunk options", {
  # The R Markdown file opts_chunk.Rmd reads the options and exports to an RDS
  # file
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  tmp_dir <- workflowr:::absolute(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  rmd <- file.path(tmp_dir, "file.Rmd")
  file.copy("files/test-wflow_html/opts_chunk.Rmd", rmd)
  html <- render(rmd, quiet = TRUE)
  expect_true(file.exists(html))
  observed <- readRDS(file.path(tmp_dir, "opts_chunk.rds"))
  expect_identical(observed$comment, NA)
  expect_identical(observed$fig.align, "center")
  expect_identical(observed$tidy, FALSE)
})

test_that("wflow_html can set knit_root_dir in YAML header", {
  # The R Markdown file knit_root_dir.Rmd creates a file knit_root_dir.txt in
  # its working directory, which is one upstream from its file location.
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  tmp_dir <- workflowr:::absolute(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  sub_dir <- file.path(tmp_dir, "sub_dir")
  dir.create(sub_dir)
  rmd <- file.path(sub_dir, "file.Rmd")
  file.copy("files/test-wflow_html/knit_root_dir.Rmd", rmd)
  html <- render(rmd, quiet = TRUE)
  expect_true(file.exists(html))
  expect_false(file.exists(file.path(sub_dir, "knit_root_dir.txt")))
  expect_true(file.exists(file.path(tmp_dir, "knit_root_dir.txt")))
})

test_that("knit_root_dir can be overridden by command-line render argument", {
  # The R Markdown file knit_root_dir.Rmd creates a file knit_root_dir.txt in
  # its working directory, which is one upstream from its file location.
  # However, this is overriden by passing the directory that contains the file
  # directly to render.
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  tmp_dir <- workflowr:::absolute(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  sub_dir <- file.path(tmp_dir, "sub_dir")
  dir.create(sub_dir)
  rmd <- file.path(sub_dir, "file.Rmd")
  file.copy("files/test-wflow_html/knit_root_dir.Rmd", rmd)
  html <- render(rmd, quiet = TRUE, knit_root_dir = dirname(rmd))
  expect_true(file.exists(html))
  expect_true(file.exists(file.path(sub_dir, "knit_root_dir.txt")))
  expect_false(file.exists(file.path(tmp_dir, "knit_root_dir.txt")))
})

test_that("wflow_html can change the sesssioninfo from the YAML header", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  tmp_dir <- workflowr:::absolute(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  rmd <- file.path(tmp_dir, "file.Rmd")
  lines <- c("---",
             "output: workflowr::wflow_html",
             "workflowr:",
             "  sessioninfo: \"devtools::session_info()\"",
             "---",
             "",
             "`r 1 + 1`")
  writeLines(lines, rmd)
  html <- render(rmd, quiet = TRUE)
  expect_true(file.exists(html))
  html_lines <- readLines(html)
  expect_true(sum(stringr::str_detect(html_lines, "devtools::session_info")) == 1)
})


test_that("wflow_html can change the seed from the YAML header", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  tmp_dir <- workflowr:::absolute(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  rmd <- file.path(tmp_dir, "file.Rmd")
  lines <- c("---",
             "output: workflowr::wflow_html",
             "workflowr:",
             "  seed: 1",
             "---",
             "",
             "`r round(rnorm(1), 5)`")
  writeLines(lines, rmd)
  html <- render(rmd, quiet = TRUE)
  expect_true(file.exists(html))
  html_lines <- readLines(html)
  set.seed(1)
  expect_true(sum(stringr::str_detect(html_lines,
                                      as.character(round(rnorm(1), 5)))) == 1)
})

test_that("wflow_html does not require a YAML header", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  tmp_dir <- workflowr:::absolute(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  rmd <- file.path(tmp_dir, "file.Rmd")
  lines <- c("some text")
  writeLines(lines, rmd)
  html <- render(rmd, quiet = TRUE)
  expect_true(file.exists(html))
  html_lines <- readLines(html)
  expect_true(sum(stringr::str_detect(html_lines, "some text")) == 1)
})

test_that("wflow_html reads _workflowr.yml in the same directory, but can be overidden", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  tmp_dir <- workflowr:::absolute(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))

  # Set seed of 5 in _workflowr.yml
  writeLines("seed: 5", con = file.path(tmp_dir, "_workflowr.yml"))

  rmd <- file.path(tmp_dir, "file.Rmd")
  lines <- c("---",
             "output: workflowr::wflow_html",
             "---",
             "",
             "`r round(rnorm(1), 5)`")
  writeLines(lines, rmd)
  html <- render(rmd, quiet = TRUE)
  expect_true(file.exists(html))
  html_lines <- readLines(html)
  set.seed(5)
  expect_true(sum(stringr::str_detect(html_lines,
                                      as.character(round(rnorm(1), 5)))) == 1)

  # Override _workflowr.yml by specifying in YAML header
  lines <- c("---",
             "output: workflowr::wflow_html",
             "workflowr:",
             "  seed: 1",
             "---",
             "",
             "`r round(rnorm(1), 5)`")
  writeLines(lines, rmd)
  html <- render(rmd, quiet = TRUE)
  html_lines <- readLines(html)
  set.seed(1)
  expect_true(sum(stringr::str_detect(html_lines,
                                      as.character(round(rnorm(1), 5)))) == 1)
})

test_that("The default knit_root_dir for a workflowr project is the root directory", {
  tmp_dir <- tempfile()
  tmp_start <- wflow_start(tmp_dir, change_wd = FALSE)
  tmp_dir <- workflowr:::absolute(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  rmd <- file.path(tmp_dir, "analysis",  "file.Rmd")
  lines <- c("`r getwd()`")
  writeLines(lines, rmd)
  html <- render_site(rmd, quiet = TRUE)
  expect_true(file.exists(html))
  html_lines <- readLines(html)
  expect_true(sum(stringr::str_detect(html_lines, tmp_dir)) == 1)
})


test_that("The default knit_root_dir for a workflowr project can be analysis/", {
  tmp_dir <- tempfile()
  tmp_start <- wflow_start(tmp_dir, change_wd = FALSE)
  tmp_dir <- workflowr:::absolute(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  wflow_yml <- file.path(tmp_dir, "_workflowr.yml")
  wflow_yml_lines <- readLines(wflow_yml)
  wflow_yml_lines <- stringr::str_replace(wflow_yml_lines,
                                          "knit_root_dir: \".\"",
                                          "knit_root_dir: \"analysis\"")
  writeLines(wflow_yml_lines, wflow_yml)
  rmd <- file.path(tmp_dir, "analysis",  "file.Rmd")
  lines <- c("`r getwd()`")
  writeLines(lines, rmd)
  html <- render_site(rmd, quiet = TRUE)
  expect_true(file.exists(html))
  html_lines <- readLines(html)
  expect_true(sum(stringr::str_detect(html_lines, basename(rmd))) == 1)
})