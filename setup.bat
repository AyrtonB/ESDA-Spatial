:: This script will set-up the coding environment for the ESDA-Spatial course
:: Run `setup.bat path/to/anaconda3` in the command line as an administrator

call %1\Scripts\activate.bat %1

call conda env create -f environment.yml

call conda activate Spatial-Course

call R --slave -e 'IRkernel::installspec(display-name=Spatial-Course)'

call jupyter lab

pause
