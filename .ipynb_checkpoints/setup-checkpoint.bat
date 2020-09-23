:: This script will set-up the coding environment for the ESDA-Spatial course
:: Run `setup.bat path/to/anaconda3` in the command line as an administrator
:: The Anaconda directory can normally be found at C:\Users\<User>\anaconda3

call %1\Scripts\activate.bat %1

call conda env create -f environment.yml

call conda activate ESDA-Spatial

call R --slave -e 'IRkernel::installspec(display-name=ESDA-Spatial)'

call jupyter lab

pause