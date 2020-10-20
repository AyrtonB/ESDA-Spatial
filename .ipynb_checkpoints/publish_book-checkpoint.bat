:: This script will deploy the course site for the ESDA-Spatial module

call %1\Scripts\activate.bat %1

call conda activate Spatial-Py

call ghp-import _build/html -f -p -n

pause