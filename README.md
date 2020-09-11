# UCL Energy Systems & Data Analytics - Spatial Module
 
test for multiple server nbs

### Set-Up Instructions

First we must install Anaconda, a platform for managing data science environments and tools, it can be downloaded using the links at the bottom of [this page](https://www.anaconda.com/download/) (use the 64-bit versions).

We now need to create the environment in which we can do our spatial analysis. In programming an environment refers to the suite of software and tooling used, in this case the specific R packages required for us to carry out spatial analyses. Anaconda makes this easy for us to set-up as all of the information on how to create an environment is stored in the *environment.yml* file, which is located in the top directory of this repository. 

cd path/to/this/directory
conda env create -f environment.yml
conda activate ESDA-Spatial
ipython kernel install --user --name=ESDA-Spatial
