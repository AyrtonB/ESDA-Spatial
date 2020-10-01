library(rmarkdown)

tutorial_dir <- '../tutorials'
tutorial_files <- list.files(tutorial_dir)

tutorial_files

for (tutorial_file in tutorial_files)
{
    input_fp <- paste(tutorial_dir, tutorial_file, sep='/')
    output_fp <- paste(strsplit(tutorial_file, '.ipynb'), 'rmd', sep='.')
    
    rmarkdown:::convert_ipynb(input_fp, output_fp)
}
